import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/core/utils/name_cleaner.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/data/remote/metadata/metadata_provider.dart';
import 'package:argus/core/providers/simkl_providers.dart';
import 'package:argus/data/remote/metadata/anilist_provider.dart';
import 'package:argus/data/remote/metadata/simkl_provider.dart';
import 'package:argus/data/remote/metadata/tvdb_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final anilistProvider = Provider<AnilistProvider>((ref) {
  return AnilistProvider();
});

final simklProvider = Provider<SimklProvider>((ref) {
  final packageInfo = ref.watch(packageInfoProvider);
  final authState = ref.watch(simklAuthProvider);
  return SimklProvider(
    appName: packageInfo.appName,
    appVersion: packageInfo.version,
    currentAccessToken: authState.accessToken,
    getAccessToken: () =>
        ref.read(simklAuthProvider.notifier).getValidAccessToken(),
  );
});

final tvdbProvider = Provider<TvdbProvider>((ref) {
  final packageInfo = ref.watch(packageInfoProvider);
  return TvdbProvider(
    appName: packageInfo.appName,
    appVersion: packageInfo.version,
  );
});

String? _resolveImageUrl(String? path, {bool isFanart = false}) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  if (path.startsWith('/banners/')) return TvdbProvider.buildImageUrl(path);
  return isFanart
      ? SimklProvider.fanartUrl(path)
      : SimklProvider.posterUrl(path);
}

(String?, String?) _extractTvdbArtworks(
  TvdbSeriesExtended? extended,
  TvdbSeries? series,
) {
  if (extended == null && series == null) return (null, null);

  final posters = extended?.artworks.where((a) => a.isPoster).toList() ?? [];
  final engPosters = posters.where((a) => a.language == 'eng').toList()
    ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
  final textlessPosters =
      posters
          .where(
            (a) =>
                a.language == null || a.language == 'zxx' || a.language == '',
          )
          .toList()
        ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
  final sortedPosters = posters.toList()
    ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

  final bestPoster =
      engPosters.firstOrNull ??
      textlessPosters.firstOrNull ??
      sortedPosters.firstOrNull;
  final tvdbPoster = bestPoster?.fullImageUrl ?? series?.posterUrl;

  final backgrounds =
      extended?.artworks.where((a) => a.isBackground).toList() ?? [];
  backgrounds.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
  final tvdbBackdrop = backgrounds.firstOrNull?.fullImageUrl;

  return (tvdbPoster, tvdbBackdrop);
}

int _scoreCandidate(TvdbSeries r, Set<String> targetTitles, int? targetYear) {
  final rYear = int.tryParse(r.year ?? '');

  final candidateTitles = <String>{
    r.name.toLowerCase().trim(),
    if (r.slug != null) r.slug!.replaceAll('-', ' ').toLowerCase().trim(),
    ...r.aliases.map((a) => a.toLowerCase().trim()),
  }.where((s) => s.isNotEmpty).toSet();

  int bestTitleScore = 0;

  for (final t in targetTitles) {
    if (t.isEmpty) continue;
    final tRegex = RegExp(
      r'\b' + RegExp.escape(t) + r'\b',
      caseSensitive: false,
    );

    for (final c in candidateTitles) {
      if (c == t) {
        bestTitleScore = 100;
        break;
      } else if (tRegex.hasMatch(c) ||
          RegExp(
            r'\b' + RegExp.escape(c) + r'\b',
            caseSensitive: false,
          ).hasMatch(t)) {
        if (bestTitleScore < 60) bestTitleScore = 60;
      } else if (c.contains(t) || t.contains(c)) {
        if (bestTitleScore < 30) bestTitleScore = 30;
      }
    }
    if (bestTitleScore == 100) break;
  }

  // never accept if only year matches
  if (bestTitleScore == 0) return -1;

  int totalScore = bestTitleScore;
  if (targetYear != null && rYear != null) {
    if (rYear == targetYear) {
      totalScore += 50;
    } else if ((rYear - targetYear).abs() <= 1) {
      totalScore += 20;
    } else {
      totalScore -= 30;
    }
  }

  return totalScore;
}

// Provides metadata for a show by groupTitle
//   - check MediaShows cache, return immediately if resolved
//   - pick representative file (prefer S01E01)
//   - call simkl /search/file with raw filename
//   - cache result
final metadataProvider = FutureProvider.family<ShowMetadata?, String>((
  ref,
  groupTitle,
) async {
  final db = ref.watch(databaseProvider);

  // check cache
  MediaShow? cached = await db.getShowByGroupTitle(groupTitle);
  final clean = NameCleaner.cleanFolderName(groupTitle);

  if (cached != null && cached.resolvedAt != null) {
    // if the cache was resolved for a completely different year than the folder specifies,
    // the cached entry was a false match. Invalidate it so it resolves with the correct year
    final yearMismatch =
        clean.year != null && cached.year != null && clean.year != cached.year;

    if (!yearMismatch) {
      if (cached.simklId == null &&
          cached.tvdbId == null &&
          cached.resolvedTitle == null) {
        return null;
      }
      return ShowMetadata(
        title: cached.resolvedTitle ?? groupTitle,
        titleEn: cached.titleEn,
        overview: cached.overview,
        posterUrl: _resolveImageUrl(cached.posterPath),
        backdropUrl: _resolveImageUrl(cached.fanartPath, isFanart: true),
        posterPath: cached.posterPath,
        fanartPath: cached.fanartPath,
        year: cached.year,
        rating:
            cached.ratingSimkl ??
            cached.ratingImdb ??
            cached.ratingMal ??
            cached.ratingAnilist,
        ratingSimkl: cached.ratingSimkl,
        ratingMal: cached.ratingMal,
        ratingImdb: cached.ratingImdb,
        ratingAnilist: cached.ratingAnilist,
        simklId: cached.simklId,
        mediaType: cached.mediaType,
        slug: cached.simklSlug,
        imdbId: cached.imdbId,
        tmdbId: cached.tmdbId,
        malId: cached.malId,
        anilistId: cached.anilistId,
        tvdbId: cached.tvdbId,
        anidbId: cached.anidbId,
      );
    } else {
      debugPrint(
        '[Metadata] Cache year mismatch for "$groupTitle": cached ${cached.year} != expected ${clean.year}. Re-resolving...',
      );
      await db.deleteShowCache(groupTitle);
      cached = null;
    }
  }

  // pick file search by filename
  final items = await db.getMediaItemsByGroupTitle(groupTitle);
  if (items.isEmpty) return null;

  final representative = items.cast<MediaItem?>().firstWhere(
    (i) => i!.season == 1 && i.episode == 1,
    orElse: () => items.cast<MediaItem?>().firstWhere(
      (i) => i!.season != null && i.episode != null,
      orElse: () => items.first,
    ),
  );
  if (representative == null) return null;

  int? targetYear = clean.year;

  if (targetYear == null) {
    final folders = await db.getFoldersByGroupTitle(groupTitle);
    if (folders.isNotEmpty) {
      targetYear = folders.first.year;
    }
  }

  // check representative file name for a year if folder did  not have one
  if (targetYear == null) {
    final fileClean = NameCleaner.clean(representative.rawName);
    targetYear = fileClean.year;
  }

  // only fallback to cached stub year if neither folder nor filename contained a year
  targetYear ??= cached?.year;

  // if the representative has a detected season/episode, inject it if missing
  final filename =
      (representative.season != null && representative.episode != null)
      ? _injectSeasonTag(
          representative.rawName,
          representative.season!,
          representative.episode!,
        )
      : representative.rawName;

  // call simkl file search with filename only if user is logged in
  SimklFileResult? simklResult;
  final authState = ref.watch(simklAuthProvider);

  if (authState.isAuthenticated) {
    final simkl = ref.watch(simklProvider);
    final fileResult = await simkl.fetchMetadataByFilename(
      filename,
      targetYear: targetYear,
    );

    // if file search didn't return a match, fallback to text search on cleaned groupTitle
    if (fileResult != null) {
      simklResult = fileResult;
    } else {
      debugPrint(
        '[Metadata] Filename search returned null for "$groupTitle", '
        'falling back to text search.',
      );
      final fullMeta = await simkl.fetchMetadata(
        clean.title,
        year: targetYear ?? clean.year,
      );
      if (fullMeta != null) {
        simklResult = SimklFileResult(
          title: fullMeta.title,
          titleEn: fullMeta.titleEn,
          year: fullMeta.year,
          posterPath: fullMeta.posterPath,
          fanartPath: fullMeta.fanartPath,
          overview: fullMeta.overview,
          ratingSimkl: fullMeta.ratingSimkl,
          ratingMal: fullMeta.ratingMal,
          ratingImdb: fullMeta.ratingImdb,
          simklId: fullMeta.simklId,
          mediaType: fullMeta.mediaType,
          slug: fullMeta.slug,
          imdbId: fullMeta.imdbId,
          tmdbId: fullMeta.tmdbId,
          malId: fullMeta.malId,
          anilistId: fullMeta.anilistId,
          tvdbId: fullMeta.tvdbId,
          anidbId: fullMeta.anidbId,
        );
      }
    }
  } else {
    debugPrint(
      '[Metadata] Simkl not logged in, using TheTVDB directly for "$groupTitle"...',
    );
  }

  final tvdb = ref.watch(tvdbProvider);
  final isMovieGroup = !items.any((i) => i.season != null || i.episode != null);
  final isMovie =
      (simklResult?.mediaType == 'movie') ||
      (cached?.mediaType == 'movie') ||
      isMovieGroup;
  final preferredType = isMovie ? 'movie' : 'series';
  final year = targetYear ?? clean.year ?? simklResult?.year ?? cached?.year;

  // --- BRANCH 1: User is logged in to Simkl (simklResult != null) ---
  // When logged in to Simkl:
  // - Metadata comes strictly from Simkl
  // - Only images come from TheTVDB (mvdb), fallback to Simkl if unavailable
  // - Existing cached ratings (like ratingAnilist) are preserved additively
  if (simklResult != null) {
    TvdbSeriesExtended? tvdbExtended;
    TvdbSeries? tvdbSeries;

    final knownTvdbId = simklResult.tvdbId ?? cached?.tvdbId;
    if (knownTvdbId != null) {
      tvdbExtended = isMovie
          ? await tvdb.fetchMovieExtended(knownTvdbId)
          : await tvdb.fetchSeriesExtended(knownTvdbId);
      tvdbSeries = tvdbExtended?.series;
      tvdbSeries ??= await tvdb.fetchSeries(knownTvdbId);
    }

    if (tvdbExtended == null &&
        simklResult.imdbId != null &&
        simklResult.imdbId!.isNotEmpty) {
      final remoteMatch = await tvdb.fetchSeriesByRemoteId(simklResult.imdbId!);
      if (remoteMatch != null) {
        tvdbSeries = remoteMatch;
        tvdbExtended = isMovie
            ? await tvdb.fetchMovieExtended(remoteMatch.id)
            : await tvdb.fetchSeriesExtended(remoteMatch.id);
      }
    }

    if (tvdbExtended == null) {
      final searchTitles = <String>{
        clean.title,
        if (simklResult.titleEn != null) simklResult.titleEn!,
        simklResult.title,
      }.where((s) => s.trim().isNotEmpty).toList();

      final targetTitles = searchTitles
          .map((s) => s.toLowerCase().trim())
          .toSet();

      for (final sTitle in searchTitles) {
        var tvdbResults = await tvdb.searchSeries(
          sTitle,
          type: preferredType,
          year: year,
        );
        if (tvdbResults.isEmpty && year != null) {
          tvdbResults = await tvdb.searchSeries(sTitle, type: preferredType);
        }
        if (tvdbResults.isEmpty) {
          tvdbResults = await tvdb.searchSeries(sTitle, year: year);
          if (tvdbResults.isEmpty && year != null) {
            tvdbResults = await tvdb.searchSeries(sTitle);
          }
        }

        if (tvdbResults.isNotEmpty) {
          TvdbSeries? bestMatch;
          int bestScore = -1;

          for (final r in tvdbResults) {
            final score = _scoreCandidate(r, targetTitles, year);
            if (score > bestScore) {
              bestScore = score;
              bestMatch = r;
            }
          }

          if (bestMatch != null) {
            tvdbSeries = bestMatch;
            final isMovieActual = tvdbSeries.type == 'movie' || isMovie;
            tvdbExtended = isMovieActual
                ? await tvdb.fetchMovieExtended(tvdbSeries.id)
                : await tvdb.fetchSeriesExtended(tvdbSeries.id);
            break;
          }
        }
      }
    }

    final (tvdbPoster, tvdbBackdrop) = _extractTvdbArtworks(
      tvdbExtended,
      tvdbSeries,
    );

    final simklPoster = simklResult.posterPath != null
        ? _resolveImageUrl(simklResult.posterPath)
        : null;
    final simklBackdrop = simklResult.fanartPath != null
        ? _resolveImageUrl(simklResult.fanartPath, isFanart: true)
        : null;

    // Only images from mvdb, fallback to simkl, fallback to cached
    final finalPoster = (tvdbPoster != null && tvdbPoster.isNotEmpty)
        ? tvdbPoster
        : (simklPoster ?? cached?.posterPath);

    final finalBackdrop = (tvdbBackdrop != null && tvdbBackdrop.isNotEmpty)
        ? tvdbBackdrop
        : (simklBackdrop ?? cached?.fanartPath);

    final resolvedTitle = simklResult.title;
    final titleEn = simklResult.titleEn ?? simklResult.title;
    final overview = simklResult.overview ?? cached?.overview;
    final mediaType =
        simklResult.mediaType ??
        cached?.mediaType ??
        (isMovie ? 'movie' : 'tv');
    final animeType = simklResult.animeType ?? cached?.animeType;
    final finalYear = simklResult.year ?? year ?? cached?.year;
    final totalEpisodes = simklResult.totalEpisodes ?? cached?.totalEpisodes;

    final ratingSimkl = simklResult.ratingSimkl ?? cached?.ratingSimkl;
    final ratingMal = simklResult.ratingMal ?? cached?.ratingMal;
    final ratingImdb = simklResult.ratingImdb ?? cached?.ratingImdb;
    final ratingAnilist = cached?.ratingAnilist;
    final overallRating =
        ratingSimkl ?? ratingImdb ?? ratingMal ?? ratingAnilist;

    final simklId = simklResult.simklId ?? cached?.simklId;
    final simklSlug = simklResult.slug ?? cached?.simklSlug;
    final tvdbId = tvdbSeries?.id ?? simklResult.tvdbId ?? cached?.tvdbId;
    final malId = simklResult.malId ?? cached?.malId;
    final anilistId = simklResult.anilistId ?? cached?.anilistId;
    final imdbId = simklResult.imdbId ?? tvdbExtended?.imdbId ?? cached?.imdbId;
    final tmdbId = simklResult.tmdbId ?? tvdbExtended?.tmdbId ?? cached?.tmdbId;
    final anidbId = simklResult.anidbId ?? cached?.anidbId;

    await db.upsertShow(
      MediaShowsCompanion(
        groupTitle: Value(groupTitle),
        resolvedTitle: Value(resolvedTitle),
        titleEn: Value(titleEn),
        mediaType: Value(mediaType),
        animeType: Value(animeType),
        year: Value(finalYear),
        totalEpisodes: Value(totalEpisodes),
        posterPath: Value(finalPoster),
        fanartPath: Value(finalBackdrop),
        overview: Value(overview),
        simklId: Value(simklId),
        simklSlug: Value(simklSlug),
        imdbId: Value(imdbId),
        tmdbId: Value(tmdbId),
        malId: Value(malId),
        anilistId: Value(anilistId),
        tvdbId: Value(tvdbId),
        anidbId: Value(anidbId),
        ratingSimkl: Value(ratingSimkl),
        ratingMal: Value(ratingMal),
        ratingImdb: Value(ratingImdb),
        ratingAnilist: Value(ratingAnilist),
        resolvedAt: Value(DateTime.now()),
      ),
    );

    debugPrint(
      '[Metadata] Cached from Simkl with MVDB images: "$resolvedTitle" '
      '(simkl:$simklId, tvdb:$tvdbId, poster:$finalPoster)',
    );

    return ShowMetadata(
      title: resolvedTitle,
      titleEn: titleEn,
      overview: overview,
      posterUrl: _resolveImageUrl(finalPoster),
      posterPath: finalPoster,
      backdropUrl: _resolveImageUrl(finalBackdrop, isFanart: true),
      fanartPath: finalBackdrop,
      year: finalYear,
      rating: overallRating,
      ratingSimkl: ratingSimkl,
      ratingMal: ratingMal,
      ratingImdb: ratingImdb,
      ratingAnilist: ratingAnilist,
      simklId: simklId,
      mediaType: mediaType,
      slug: simklSlug,
      imdbId: imdbId,
      tmdbId: tmdbId,
      malId: malId,
      anilistId: anilistId,
      tvdbId: tvdbId,
      anidbId: anidbId,
      genres: tvdbSeries?.genres ?? const [],
    );
  }

  // not logged in to Simkl
  final anilist = ref.watch(anilistProvider);

  AnilistMetadata? anilistMeta;
  final knownAnilistId = cached?.anilistId;
  final knownMalId = cached?.malId;

  if (knownAnilistId != null) {
    anilistMeta = await anilist.fetchAnimeById(knownAnilistId);
  }
  if (anilistMeta == null && knownMalId != null) {
    anilistMeta = await anilist.fetchAnimeByMalId(knownMalId);
  }

  anilistMeta ??= await anilist.searchAnime(clean.title, year: year);

  if (anilistMeta != null) {
    debugPrint(
      '[AniList] Matched anime "${anilistMeta.titleEnglish ?? anilistMeta.titleRomaji}": '
      'anilist:${anilistMeta.id}, mal:${anilistMeta.malId}, score:${anilistMeta.score}',
    );
  }

  final tvdbSearchTitles = <String>{
    clean.title,
    if (anilistMeta?.titleEnglish != null) anilistMeta!.titleEnglish!,
    if (anilistMeta?.titleRomaji != null) anilistMeta!.titleRomaji!,
  }.where((s) => s.trim().isNotEmpty).toList();

  final targetTitles = tvdbSearchTitles
      .map((s) => s.toLowerCase().trim())
      .toSet();

  TvdbSeries? tvdbSeries;
  TvdbSeriesExtended? tvdbExtended;

  final knownTvdbId = cached?.tvdbId;
  if (knownTvdbId != null) {
    tvdbExtended = isMovie
        ? await tvdb.fetchMovieExtended(knownTvdbId)
        : await tvdb.fetchSeriesExtended(knownTvdbId);
    tvdbSeries = tvdbExtended?.series;
    tvdbSeries ??= await tvdb.fetchSeries(knownTvdbId);
  }

  if (tvdbExtended == null &&
      cached?.imdbId != null &&
      cached!.imdbId!.isNotEmpty) {
    final remoteMatch = await tvdb.fetchSeriesByRemoteId(cached.imdbId!);
    if (remoteMatch != null) {
      tvdbSeries = remoteMatch;
      tvdbExtended = isMovie
          ? await tvdb.fetchMovieExtended(remoteMatch.id)
          : await tvdb.fetchSeriesExtended(remoteMatch.id);
    }
  }

  if (tvdbExtended == null) {
    for (final sTitle in tvdbSearchTitles) {
      var tvdbResults = await tvdb.searchSeries(
        sTitle,
        type: preferredType,
        year: year,
      );
      if (tvdbResults.isEmpty && year != null) {
        tvdbResults = await tvdb.searchSeries(sTitle, type: preferredType);
      }
      if (tvdbResults.isEmpty) {
        tvdbResults = await tvdb.searchSeries(sTitle, year: year);
        if (tvdbResults.isEmpty && year != null) {
          tvdbResults = await tvdb.searchSeries(sTitle);
        }
      }

      if (tvdbResults.isNotEmpty) {
        TvdbSeries? bestMatch;
        int bestScore = -1;

        for (final r in tvdbResults) {
          final score = _scoreCandidate(r, targetTitles, year);
          if (score > bestScore) {
            bestScore = score;
            bestMatch = r;
          }
        }

        if (bestMatch != null) {
          tvdbSeries = bestMatch;
          final isMovieActual = tvdbSeries.type == 'movie' || isMovie;
          tvdbExtended = isMovieActual
              ? await tvdb.fetchMovieExtended(tvdbSeries.id)
              : await tvdb.fetchSeriesExtended(tvdbSeries.id);
          debugPrint(
            '[TheTVDB] Found match for "$groupTitle": "${tvdbSeries.name}" '
            '(id: ${tvdbSeries.id}, year: ${tvdbSeries.year}, type: ${tvdbSeries.type})',
          );
          break;
        }
      }
    }
  }

  // extract tvdb artworks
  final (tvdbPoster, tvdbBackdrop) = _extractTvdbArtworks(
    tvdbExtended,
    tvdbSeries,
  );

  // tvdb English translation
  String? tvdbTitleEn;
  String? tvdbOverview = tvdbSeries?.overview;
  if (tvdbSeries != null &&
      (tvdbSeries.primaryLanguage != 'eng' ||
          RegExp(r'[^\x00-\x7F]').hasMatch(tvdbSeries.name))) {
    final tvdbTrans = await tvdb.fetchSeriesTranslation(
      tvdbSeries.id,
      isMovie: isMovie,
    );
    if (tvdbTrans != null) {
      if (tvdbTrans.name != null && tvdbTrans.name!.isNotEmpty) {
        tvdbTitleEn = tvdbTrans.name;
      }
      if (tvdbTrans.overview != null && tvdbTrans.overview!.isNotEmpty) {
        tvdbOverview = tvdbTrans.overview;
      }
    }
  }

  final isAnime =
      anilistMeta != null ||
      cached?.mediaType == 'anime' ||
      cached?.animeType != null ||
      (tvdbSeries != null &&
          (tvdbSeries.primaryLanguage == 'jpn' ||
              tvdbSeries.genres.any((g) => g.toLowerCase().contains('anime'))));

  // image selection: tvdb > anilist > cached
  final anilistPoster = anilistMeta?.coverImageUrl;
  final anilistBackdrop = anilistMeta?.bannerImageUrl;

  String? finalPoster;
  if (tvdbPoster != null && tvdbPoster.isNotEmpty) {
    finalPoster = tvdbPoster;
  } else if (isAnime && anilistPoster != null && anilistPoster.isNotEmpty) {
    finalPoster = anilistPoster;
  } else if (cached?.posterPath != null && cached!.posterPath!.isNotEmpty) {
    finalPoster = cached.posterPath;
  }

  String? finalBackdrop;
  if (tvdbBackdrop != null && tvdbBackdrop.isNotEmpty) {
    finalBackdrop = tvdbBackdrop;
  } else if (isAnime && anilistBackdrop != null && anilistBackdrop.isNotEmpty) {
    finalBackdrop = anilistBackdrop;
  } else if (cached?.fanartPath != null && cached!.fanartPath!.isNotEmpty) {
    finalBackdrop = cached.fanartPath;
  }

  // if nothing matched across any source
  if (tvdbSeries == null && anilistMeta == null) {
    if (cached != null && cached.resolvedTitle != null) {
      // re-mark resolvedAt and keep previous cached metadata
      await db.upsertShow(
        MediaShowsCompanion(
          groupTitle: Value(groupTitle),
          resolvedAt: Value(DateTime.now()),
        ),
      );
      return ShowMetadata(
        title: cached.resolvedTitle ?? groupTitle,
        titleEn: cached.titleEn,
        overview: cached.overview,
        posterUrl: _resolveImageUrl(cached.posterPath),
        backdropUrl: _resolveImageUrl(cached.fanartPath, isFanart: true),
        posterPath: cached.posterPath,
        fanartPath: cached.fanartPath,
        year: cached.year,
        rating:
            cached.ratingSimkl ??
            cached.ratingImdb ??
            cached.ratingMal ??
            cached.ratingAnilist,
        ratingSimkl: cached.ratingSimkl,
        ratingMal: cached.ratingMal,
        ratingImdb: cached.ratingImdb,
        ratingAnilist: cached.ratingAnilist,
        simklId: cached.simklId,
        mediaType: cached.mediaType,
        slug: cached.simklSlug,
        imdbId: cached.imdbId,
        tmdbId: cached.tmdbId,
        malId: cached.malId,
        anilistId: cached.anilistId,
        tvdbId: cached.tvdbId,
        anidbId: cached.anidbId,
      );
    }

    debugPrint('[Metadata] No TheTVDB or AniList match for "$groupTitle"');
    await db.upsertShow(
      MediaShowsCompanion(
        groupTitle: Value(groupTitle),
        resolvedAt: Value(DateTime.now()),
      ),
    );
    return null;
  }

  // titles
  final animeTitle = anilistMeta?.titleEnglish ?? anilistMeta?.titleRomaji;
  final resolvedTitle =
      (isAnime ? animeTitle : null) ??
      tvdbTitleEn ??
      tvdbSeries?.name ??
      cached?.resolvedTitle ??
      groupTitle;
  final titleEn =
      (isAnime ? animeTitle : null) ??
      tvdbTitleEn ??
      tvdbSeries?.name ??
      cached?.titleEn;

  // overview
  final overview =
      (isAnime && anilistMeta?.description != null
          ? anilistMeta!.description
          : null) ??
      tvdbOverview ??
      cached?.overview;

  // media type and anime type
  final mediaType =
      (isMovie
          ? 'movie'
          : (isAnime ? 'anime' : (tvdbSeries != null ? 'tv' : null))) ??
      cached?.mediaType ??
      'tv';
  final animeType =
      anilistMeta?.format ??
      cached?.animeType ??
      (isAnime ? (isMovie ? 'movie' : 'tv') : null);

  // external IDs (additive: new ?? cached)
  final simklId = cached?.simklId;
  final simklSlug = cached?.simklSlug;
  final tvdbId = tvdbSeries?.id ?? cached?.tvdbId;
  final malId = anilistMeta?.malId ?? cached?.malId;
  final anilistId = anilistMeta?.id ?? cached?.anilistId;
  final imdbId = tvdbExtended?.imdbId ?? cached?.imdbId;
  final tmdbId = tvdbExtended?.tmdbId ?? cached?.tmdbId;
  final anidbId = cached?.anidbId;

  // ratings (additive: new ?? cached)
  final ratingSimkl = cached?.ratingSimkl;
  final ratingMal = cached?.ratingMal;
  final ratingImdb = cached?.ratingImdb;
  final ratingAnilist = anilistMeta?.score ?? cached?.ratingAnilist;
  final tvdbScore = tvdbExtended?.series.score ?? tvdbSeries?.score;
  final overallRating =
      ratingAnilist ??
      ratingSimkl ??
      ratingImdb ??
      ratingMal ??
      tvdbScore ??
      cached?.ratingSimkl ??
      cached?.ratingImdb ??
      cached?.ratingMal ??
      cached?.ratingAnilist;

  final finalYear =
      (tvdbSeries?.year != null ? int.tryParse(tvdbSeries!.year!) : null) ??
      year ??
      cached?.year;
  final totalEpisodes = cached?.totalEpisodes;

  await db.upsertShow(
    MediaShowsCompanion(
      groupTitle: Value(groupTitle),
      resolvedTitle: Value(resolvedTitle),
      titleEn: Value(titleEn),
      mediaType: Value(mediaType),
      animeType: Value(animeType),
      year: Value(finalYear),
      totalEpisodes: Value(totalEpisodes),
      posterPath: Value(finalPoster),
      fanartPath: Value(finalBackdrop),
      overview: Value(overview),
      simklId: Value(simklId),
      simklSlug: Value(simklSlug),
      imdbId: Value(imdbId),
      tmdbId: Value(tmdbId),
      malId: Value(malId),
      anilistId: Value(anilistId),
      tvdbId: Value(tvdbId),
      anidbId: Value(anidbId),
      ratingSimkl: Value(ratingSimkl),
      ratingMal: Value(ratingMal),
      ratingImdb: Value(ratingImdb),
      ratingAnilist: Value(ratingAnilist),
      resolvedAt: Value(DateTime.now()),
    ),
  );

  debugPrint(
    '[Metadata] Cached & enriched: "$resolvedTitle" '
    '(tvdb:$tvdbId, simkl:$simklId, mal:$malId, anilist:$anilistId, '
    'ratingAnilist:$ratingAnilist, ratingSimkl:$ratingSimkl, ratingMal:$ratingMal, ratingImdb:$ratingImdb)',
  );

  return ShowMetadata(
    title: resolvedTitle,
    titleEn: titleEn,
    overview: overview,
    posterUrl: _resolveImageUrl(finalPoster),
    posterPath: finalPoster,
    backdropUrl: _resolveImageUrl(finalBackdrop, isFanart: true),
    fanartPath: finalBackdrop,
    year: finalYear,
    rating: overallRating,
    ratingSimkl: ratingSimkl,
    ratingMal: ratingMal,
    ratingImdb: ratingImdb,
    ratingAnilist: ratingAnilist,
    simklId: simklId,
    mediaType: mediaType,
    slug: simklSlug,
    imdbId: imdbId,
    tmdbId: tmdbId,
    malId: malId,
    anilistId: anilistId,
    tvdbId: tvdbId,
    anidbId: anidbId,
    genres: tvdbSeries?.genres ?? const [],
  );
});

String _injectSeasonTag(String filename, int season, int episode) {
  final hasSeason =
      RegExp(
        r'\b[Ss]\d{1,2}\s*[Ee]\d{1,3}\b',
        caseSensitive: false,
      ).hasMatch(filename) ||
      RegExp(
        r'\bSeason\s*\d{1,2}\b',
        caseSensitive: false,
      ).hasMatch(filename) ||
      RegExp(r'\b\d{1,2}[xX]\d{2,3}\b').hasMatch(filename);
  if (hasSeason) return filename;

  final seasonStr = season.toString().padLeft(2, '0');
  final episodeStr = episode.toString().padLeft(2, '0');
  final replacement = "S${seasonStr}E$episodeStr";

  // find the episode pattern matching the known episode number
  final epRegex = RegExp(
    r'\b(?:Ep(?:isode)?\.?\s*|[Ee])?0*' +
        RegExp.escape(episode.toString()) +
        r'\b',
    caseSensitive: false,
  );

  if (epRegex.hasMatch(filename)) {
    return filename.replaceFirst(epRegex, replacement);
  }

  return filename;
}

final episodeNamesProvider = FutureProvider.family<Map<(int, int), String>, String>((
  ref,
  groupTitle,
) async {
  final db = ref.watch(databaseProvider);

  // if no items in this group have season or episode numbers, it is a movie or non-episodic media
  final items = await db.getMediaItemsByGroupTitle(groupTitle);
  final hasEpisodes = items.any((i) => i.season != null || i.episode != null);
  if (items.isNotEmpty && !hasEpisodes) {
    return const {};
  }

  final meta = await ref.watch(metadataProvider(groupTitle).future);
  final isMovie =
      meta?.mediaType == 'movie' ||
      meta?.mediaType == 'movies' ||
      (items.isNotEmpty && !hasEpisodes);

  if (isMovie) {
    // if stale cached episodes exist from a prior false match, clear them
    final cached = await db.getCachedEpisodes(groupTitle);
    if (cached != null && cached.isNotEmpty) {
      await db.clearEpisodeCache(groupTitle);
    }
    return const {};
  }

  if (meta == null) return const {};

  // check database cache first
  final cached = await db.getCachedEpisodes(groupTitle);
  if (cached != null && cached.isNotEmpty) {
    debugPrint(
      '[TheTVDB] Using ${cached.length} cached episode names for "$groupTitle"',
    );
    return cached;
  }

  final tvdb = ref.watch(tvdbProvider);

  int? tvdbId = meta.tvdbId;
  // if tvdbId is missing, cross search once using imdbId
  if (tvdbId == null && meta.imdbId != null && meta.imdbId!.isNotEmpty) {
    debugPrint('[TheTVDB] Resolving tvdbId via IMDb: ${meta.imdbId}');
    final series = await tvdb.fetchSeriesByRemoteId(meta.imdbId!);
    if (series != null) {
      tvdbId = series.id;
      await (db.update(db.mediaShows)
            ..where((s) => s.groupTitle.equals(groupTitle)))
          .write(MediaShowsCompanion(tvdbId: Value(series.id)));
    }
  }

  if (tvdbId == null) return const {};

  debugPrint(
    '[TheTVDB] Fetching episode names for "$groupTitle" (tvdbId: $tvdbId)...',
  );
  final episodes = await tvdb.fetchEpisodes(tvdbId);
  if (episodes.isEmpty) return const {};

  final map = <(int, int), String>{};
  for (final ep in episodes) {
    if (ep.seasonNumber != null && ep.number != null && ep.name.isNotEmpty) {
      map[(ep.seasonNumber!, ep.number!)] = ep.name;
    }
  }
  debugPrint('[TheTVDB] Loaded ${map.length} episode names for "$groupTitle"');

  // local database cache
  if (map.isNotEmpty) {
    await db.saveCachedEpisodes(groupTitle, map);
  }

  return map;
});
