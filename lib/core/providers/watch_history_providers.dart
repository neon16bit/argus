import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/data/remote/metadata/simkl_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContinueWatchingItem {
  final int watchId;
  final String groupTitle;
  final int? season;
  final int? episode;
  final String? episodeTitle;
  final String streamUrl;
  final int positionMs;
  final int durationMs;
  final bool isCompleted;
  final DateTime lastWatchedAt;
  final String? resolvedTitle;
  final String? titleEn;
  final String? posterPath;
  final String? fanartPath;
  final String? mediaType;
  final int? year;
  final int itemCount;

  const ContinueWatchingItem({
    required this.watchId,
    required this.groupTitle,
    this.season,
    this.episode,
    this.episodeTitle,
    required this.streamUrl,
    required this.positionMs,
    required this.durationMs,
    required this.isCompleted,
    required this.lastWatchedAt,
    this.resolvedTitle,
    this.titleEn,
    this.posterPath,
    this.fanartPath,
    this.mediaType,
    this.year,
    this.itemCount = 0,
  });

  String get displayTitle => titleEn ?? resolvedTitle ?? groupTitle;
  String? get posterUrl => SimklProvider.posterUrl(posterPath);
  String? get fanartUrl => SimklProvider.fanartUrl(fanartPath);

  double get progressFraction =>
      durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

  String get episodeLabel {
    if (season != null && episode != null) {
      return 'S$season E$episode';
    } else if (episode != null) {
      return 'Episode $episode';
    } else if (episodeTitle != null && episodeTitle!.isNotEmpty) {
      return episodeTitle!;
    }
    return '';
  }
}

final continueWatchingProvider = StreamProvider<List<ContinueWatchingItem>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db.watchContinueWatching().map(
    (rows) => rows.map((row) {
      final rawDate = row['last_watched_at'];
      DateTime lastWatched;
      if (rawDate is DateTime) {
        lastWatched = rawDate;
      } else if (rawDate is int) {
        lastWatched = DateTime.fromMillisecondsSinceEpoch(
          rawDate > 10000000000 ? rawDate : rawDate * 1000,
        );
      } else if (rawDate is String) {
        lastWatched = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else {
        lastWatched = DateTime.now();
      }

      return ContinueWatchingItem(
        watchId: row['watch_id'] as int,
        groupTitle: row['group_title'] as String,
        season: row['season'] as int?,
        episode: row['episode'] as int?,
        episodeTitle: row['episode_title'] as String?,
        streamUrl: row['stream_url'] as String,
        positionMs: row['position_ms'] as int? ?? 0,
        durationMs: row['duration_ms'] as int? ?? 0,
        isCompleted: (row['is_completed'] as int? ?? 0) == 1,
        lastWatchedAt: lastWatched,
        resolvedTitle: row['resolved_title'] as String?,
        titleEn: row['title_en'] as String?,
        posterPath: row['poster_path'] as String?,
        fanartPath: row['fanart_path'] as String?,
        mediaType: row['media_type'] as String?,
        year: row['year'] as int?,
        itemCount: row['item_count'] as int? ?? 0,
      );
    }).toList(),
  );
});

final showWatchHistoryProvider =
    StreamProvider.family<List<WatchHistoryData>, String>((ref, groupTitle) {
      final db = ref.watch(databaseProvider);
      return db.watchPlaybackProgressForShow(groupTitle);
    });
