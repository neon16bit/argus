import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:argus/data/database/app_database.dart';
import 'package:argus/data/remote/metadata/simkl_provider.dart';
import 'package:argus/data/remote/simkl/simkl_auth_service.dart';

class SimklSyncService {
  final SimklAuthNotifier authNotifier;
  final AppDatabase db;
  final String appName;
  final String appVersion;
  final SimklProvider? simklProvider;

  SimklSyncService({
    required this.authNotifier,
    required this.db,
    required this.appName,
    required this.appVersion,
    this.simklProvider,
  });

  static bool isNonScrobbleable(String filename) {
    final lower = filename.toLowerCase();
    final nonScrobblePatterns = [
      RegExp(r'\b(nc|nced|ncop|creditless)\b', caseSensitive: false),
      RegExp(r'\b(?:clean\s*(?:op|ed|opening|ending))\b', caseSensitive: false),
      RegExp(
        r'\b(trailer|teaser|preview|pv|cm|sample|menu)\b',
        caseSensitive: false,
      ),
    ];
    return nonScrobblePatterns.any((p) => p.hasMatch(lower));
  }

  Future<bool> syncEpisodeWatched({
    required String groupTitle,
    int? season,
    int? episode,
    String? rawName,
    required bool isWatched,
    bool force = false,
  }) async {
    final state = authNotifier.currentState;
    if (!state.isAuthenticated) {
      return false;
    }
    if (!state.autoSync && !force) {
      return false;
    }

    // skip non scrobbleable extras
    if (rawName != null && isNonScrobbleable(rawName)) {
      debugPrint(
        '[SimklSync] Skipping non-scrobbleable extra: "$rawName" (tracked locally only)',
      );
      return true;
    }

    final token = await authNotifier.getValidAccessToken();
    if (token == null) return false;

    try {
      final show = await (db.select(
        db.mediaShows,
      )..where((s) => s.groupTitle.equals(groupTitle))).getSingleOrNull();

      final nowIso = DateTime.now().toUtc().toIso8601String();

      // extra / movie filename check
      final isExtraOrMovieCandidate =
          rawName != null &&
          simklProvider != null &&
          (season == null ||
              season == 0 ||
              episode == null ||
              rawName.toLowerCase().contains('movie') ||
              rawName.toLowerCase().contains('film'));

      if (isExtraOrMovieCandidate) {
        debugPrint(
          '[SimklSync] Resolving extra/special via Simkl file search: "$rawName"',
        );
        final fileMatch = await simklProvider!.fetchMetadataByFilename(rawName);

        if (fileMatch != null) {
          final isDifferentEntry =
              fileMatch.simklId != null &&
              show?.simklId != null &&
              fileMatch.simklId != show!.simklId;

          final isMovieResult =
              fileMatch.mediaType == 'movie' ||
              fileMatch.animeType == 'movie' ||
              isDifferentEntry ||
              (fileMatch.season == null &&
                  fileMatch.episode == null &&
                  fileMatch.simklId != null);

          if (isMovieResult) {
            debugPrint(
              '[SimklSync] Resolved "$rawName" as standalone media entry: '
              '"${fileMatch.title}" (simkl:${fileMatch.simklId}, type:${fileMatch.mediaType})',
            );
            final matchIds = <String, dynamic>{};
            if (fileMatch.simklId != null) {
              matchIds['simkl'] = fileMatch.simklId;
            }
            if (fileMatch.malId != null) matchIds['mal'] = fileMatch.malId;
            if (fileMatch.tvdbId != null) matchIds['tvdb'] = fileMatch.tvdbId;
            if (fileMatch.imdbId != null && fileMatch.imdbId!.isNotEmpty) {
              matchIds['imdb'] = fileMatch.imdbId;
            }
            if (fileMatch.tmdbId != null && fileMatch.tmdbId!.isNotEmpty) {
              matchIds['tmdb'] = fileMatch.tmdbId;
            }

            final Map<String, dynamic> payload;
            if (fileMatch.mediaType == 'movie') {
              final movieObj = <String, dynamic>{
                'title': fileMatch.title,
                if (fileMatch.year != null) 'year': fileMatch.year,
                if (matchIds.isNotEmpty) 'ids': matchIds,
                if (isWatched) 'watched_at': nowIso,
              };
              payload = {
                'movies': [movieObj],
              };
            } else {
              // anime movie or standalone OVA/special entry
              final epObj = <String, dynamic>{
                'number': fileMatch.episode ?? 1,
                if (isWatched) 'watched_at': nowIso,
              };
              final animeObj = <String, dynamic>{
                'title': fileMatch.title,
                if (fileMatch.year != null) 'year': fileMatch.year,
                if (matchIds.isNotEmpty) 'ids': matchIds,
                'seasons': [
                  {
                    'number': fileMatch.season ?? 1,
                    'episodes': [epObj],
                  },
                ],
              };
              payload = {
                'anime': [animeObj],
              };
            }

            return await _sendSyncRequest(
              token: token,
              payload: payload,
              url: isWatched
                  ? 'https://api.simkl.com/sync/history'
                  : 'https://api.simkl.com/sync/history/remove',
              logDesc: 'Standalone "${fileMatch.title}"',
            );
          } else if (fileMatch.episode != null) {
            debugPrint(
              '[SimklSync] Resolved "$rawName" as special episode of parent show: S${fileMatch.season ?? 0}E${fileMatch.episode}',
            );
            season = fileMatch.season ?? season ?? 0;
            episode = fileMatch.episode;
          }
        } else if (episode == null && (season == null || season == 0)) {
          debugPrint(
            '[SimklSync] Extra "$rawName" has no Simkl match or episode number. Tracked locally only.',
          );
          return true;
        }
      }

      final isAnime = show?.mediaType == 'anime';
      final isAnimeSequel = isAnime && season != null && season > 1;
      final isMovie =
          show?.mediaType == 'movie' ||
          (!isAnime && season == null && episode == null);

      final ids = <String, dynamic>{};
      if (show?.tvdbId != null) ids['tvdb'] = show!.tvdbId;
      if (show?.imdbId != null && show!.imdbId!.isNotEmpty) {
        ids['imdb'] = show.imdbId;
      }
      if (show?.tmdbId != null && show!.tmdbId!.isNotEmpty) {
        ids['tmdb'] = show.tmdbId;
      }

      if (!isAnimeSequel) {
        if (show?.simklId != null) ids['simkl'] = show!.simklId;
        if (show?.malId != null) ids['mal'] = show!.malId;
        if (show?.anilistId != null) ids['anilist'] = show!.anilistId;
      }

      final Map<String, dynamic> payload;

      if (isMovie) {
        final movieObj = <String, dynamic>{
          'title': show?.resolvedTitle ?? groupTitle,
          if (show?.year != null) 'year': show!.year,
          if (ids.isNotEmpty) 'ids': ids,
          if (isWatched) 'watched_at': nowIso,
        };
        payload = {
          'movies': [movieObj],
        };
      } else if (isAnime && !isAnimeSequel) {
        final epObj = <String, dynamic>{
          'number': episode ?? 1,
          if (isWatched) 'watched_at': nowIso,
        };
        final animeObj = <String, dynamic>{
          'title': show?.resolvedTitle ?? groupTitle,
          if (show?.year != null) 'year': show!.year,
          if (ids.isNotEmpty) 'ids': ids,
          'seasons': [
            {
              'number': season ?? 1,
              'episodes': [epObj],
            },
          ],
        };
        payload = {
          'anime': [animeObj],
        };
      } else {
        final epObj = <String, dynamic>{
          'number': episode ?? 1,
          if (isWatched) 'watched_at': nowIso,
        };
        final showObj = <String, dynamic>{
          'title': show?.resolvedTitle ?? groupTitle,
          if (!isAnimeSequel && show?.year != null) 'year': show!.year,
          if (ids.isNotEmpty) 'ids': ids,
          'seasons': [
            {
              'number': season ?? 1,
              'episodes': [epObj],
            },
          ],
        };
        payload = {
          'shows': [showObj],
        };
      }

      final baseUrl = isWatched
          ? 'https://api.simkl.com/sync/history'
          : 'https://api.simkl.com/sync/history/remove';
      final url = isAnime ? '$baseUrl?use_tvdb_anime_seasons=true' : baseUrl;

      return await _sendSyncRequest(
        token: token,
        payload: payload,
        url: url,
        logDesc:
            '${isWatched ? "watched" : "unwatched"}: "$groupTitle" (S:$season E:$episode)',
      );
    } catch (e) {
      debugPrint('[SimklSync] Failed to sync: $e');
      return false;
    }
  }

  Future<bool> _sendSyncRequest({
    required String token,
    required Map<String, dynamic> payload,
    required String url,
    required String logDesc,
  }) async {
    try {
      debugPrint('[SimklSync] Syncing $logDesc -> $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'simkl-api-key': SimklProvider.clientId,
          'User-Agent': '$appName/$appVersion',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[SimklSync] Success ($logDesc): ${response.body}');
        return true;
      } else {
        debugPrint(
          '[SimklSync] Error ($logDesc) [${response.statusCode}]: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[SimklSync] Request failed ($logDesc): $e');
      return false;
    }
  }

  Future<int> syncAllWatchedHistory() async {
    final state = authNotifier.currentState;
    if (!state.isAuthenticated) return 0;

    final token = await authNotifier.getValidAccessToken();
    if (token == null) return 0;

    try {
      final watchedRows = await (db.select(
        db.watchHistory,
      )..where((w) => w.isCompleted.equals(true))).get();

      if (watchedRows.isEmpty) return 0;

      final grouped = <String, List<WatchHistoryData>>{};
      for (final row in watchedRows) {
        grouped.putIfAbsent(row.groupTitle, () => []).add(row);
      }

      final showsPayload = <Map<String, dynamic>>[];
      final moviesPayload = <Map<String, dynamic>>[];
      final animePayload = <Map<String, dynamic>>[];

      for (final entry in grouped.entries) {
        final title = entry.key;
        final rows = entry.value;

        final show = await (db.select(
          db.mediaShows,
        )..where((s) => s.groupTitle.equals(title))).getSingleOrNull();

        final ids = <String, dynamic>{};
        if (show?.simklId != null) ids['simkl'] = show!.simklId;
        if (show?.tvdbId != null) ids['tvdb'] = show!.tvdbId;
        if (show?.imdbId != null && show!.imdbId!.isNotEmpty) {
          ids['imdb'] = show.imdbId;
        }
        if (show?.tmdbId != null && show!.tmdbId!.isNotEmpty) {
          ids['tmdb'] = show.tmdbId;
        }
        if (show?.malId != null) ids['mal'] = show!.malId;
        if (show?.anilistId != null) ids['anilist'] = show!.anilistId;

        final isAnime = show?.mediaType == 'anime';
        final isMovie = show?.mediaType == 'movie';

        if (isMovie) {
          final lastWatched = rows.first.lastWatchedAt
              .toUtc()
              .toIso8601String();
          moviesPayload.add({
            'title': show?.resolvedTitle ?? title,
            if (show?.year != null) 'year': show!.year,
            if (ids.isNotEmpty) 'ids': ids,
            'watched_at': lastWatched,
          });
        } else if (isAnime) {
          // for anime split season 1 vs season 2+
          final seasonMap = <int, List<Map<String, dynamic>>>{};
          for (final r in rows) {
            // Skip unnumbered extras in batch sync
            if (r.episode == null && (r.season == 0 || r.season == null)) {
              continue;
            }
            final sNum = r.season ?? 1;
            final epNum = r.episode ?? 1;
            seasonMap.putIfAbsent(sNum, () => []).add({
              'number': epNum,
              'watched_at': r.lastWatchedAt.toUtc().toIso8601String(),
            });
          }

          for (final sEntry in seasonMap.entries) {
            final sNum = sEntry.key;
            final epList = sEntry.value;

            if (sNum <= 1) {
              // under anime with simkl/mal IDs
              animePayload.add({
                'title': show?.resolvedTitle ?? title,
                if (show?.year != null) 'year': show!.year,
                if (ids.isNotEmpty) 'ids': ids,
                'seasons': [
                  {'number': sNum, 'episodes': epList},
                ],
              });
            } else {
              // season 2+, under shows with tvdb ID (omit season 1 simkl/mal/year)
              final tvdbIds = <String, dynamic>{};
              if (show?.tvdbId != null) tvdbIds['tvdb'] = show!.tvdbId;
              if (show?.imdbId != null && show!.imdbId!.isNotEmpty) {
                tvdbIds['imdb'] = show.imdbId;
              }
              if (show?.tmdbId != null && show!.tmdbId!.isNotEmpty) {
                tvdbIds['tmdb'] = show.tmdbId;
              }

              showsPayload.add({
                'title': show?.resolvedTitle ?? title,
                if (tvdbIds.isNotEmpty) 'ids': tvdbIds,
                'seasons': [
                  {'number': sNum, 'episodes': epList},
                ],
              });
            }
          }
        } else {
          // standard tv: all seasons under shows
          final seasonMap = <int, List<Map<String, dynamic>>>{};
          for (final r in rows) {
            // Skip unnumbered extras in batch sync
            if (r.episode == null && (r.season == 0 || r.season == null)) {
              continue;
            }
            final sNum = r.season ?? 1;
            final epNum = r.episode ?? 1;
            seasonMap.putIfAbsent(sNum, () => []).add({
              'number': epNum,
              'watched_at': r.lastWatchedAt.toUtc().toIso8601String(),
            });
          }

          final seasonsList = seasonMap.entries.map((s) {
            return {'number': s.key, 'episodes': s.value};
          }).toList();

          showsPayload.add({
            'title': show?.resolvedTitle ?? title,
            if (show?.year != null) 'year': show!.year,
            if (ids.isNotEmpty) 'ids': ids,
            'seasons': seasonsList,
          });
        }
      }

      final payload = <String, dynamic>{
        if (showsPayload.isNotEmpty) 'shows': showsPayload,
        if (moviesPayload.isNotEmpty) 'movies': moviesPayload,
        if (animePayload.isNotEmpty) 'anime': animePayload,
      };

      if (payload.isEmpty) return 0;

      debugPrint(
        '[SimklSync] Batch syncing ${showsPayload.length} shows, '
        '${animePayload.length} anime, and ${moviesPayload.length} movies...',
      );

      final response = await http.post(
        Uri.parse(
          'https://api.simkl.com/sync/history?use_tvdb_anime_seasons=true',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'simkl-api-key': SimklProvider.clientId,
          'User-Agent': '$appName/$appVersion',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[SimklSync] Batch sync success: ${response.body}');
        return watchedRows.length;
      } else {
        debugPrint(
          '[SimklSync] Batch sync error (${response.statusCode}): ${response.body}',
        );
        return 0;
      }
    } catch (e) {
      debugPrint('[SimklSync] Error during batch sync: $e');
      return 0;
    }
  }
}
