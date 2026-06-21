import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/core/utils/name_cleaner.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/data/remote/metadata/metadata_provider.dart';
import 'package:argus/data/remote/metadata/simkl_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final simklProvider = Provider<SimklProvider>((ref) {
  final packageInfo = ref.watch(packageInfoProvider);
  return SimklProvider(
    appName: packageInfo.appName,
    appVersion: packageInfo.version,
  );
});

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
  final cached = await db.getShowByGroupTitle(groupTitle);
  if (cached != null && cached.resolvedAt != null) {
    if (cached.simklId == null) return null;
    return ShowMetadata(
      title: cached.resolvedTitle ?? groupTitle,
      titleEn: cached.titleEn,
      overview: cached.overview,
      posterUrl: SimklProvider.posterUrl(cached.posterPath),
      backdropUrl: SimklProvider.fanartUrl(cached.fanartPath),
      posterPath: cached.posterPath,
      fanartPath: cached.fanartPath,
      year: cached.year,
      rating: cached.ratingSimkl ?? cached.ratingImdb ?? cached.ratingMal,
      ratingSimkl: cached.ratingSimkl,
      ratingMal: cached.ratingMal,
      ratingImdb: cached.ratingImdb,
      simklId: cached.simklId,
      mediaType: cached.mediaType,
      slug: cached.simklSlug,
    );
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

  // get target year from cached stub if available
  final targetYear = cached?.year;

  // if the representative has a detected season/episode, inject it if missing
  final filename =
      (representative.season != null && representative.episode != null)
      ? _injectSeasonTag(
          representative.rawName,
          representative.season!,
          representative.episode!,
        )
      : representative.rawName;

  // call simkl file search with filename
  final simkl = ref.watch(simklProvider);
  final fileResult = await simkl.fetchMetadataByFilename(
    filename,
    targetYear: targetYear,
  );

  // if file search didn't return a match, fallback to text search on cleaned groupTitle
  final SimklFileResult? result;
  if (fileResult != null) {
    result = fileResult;
  } else {
    debugPrint(
      '[Metadata] Filename search returned null for "$groupTitle", '
      'falling back to text search.',
    );
    final clean = NameCleaner.cleanFolderName(groupTitle);
    final fullMeta = await simkl.fetchMetadata(
      clean.title,
      year: targetYear ?? clean.year,
    );
    if (fullMeta != null) {
      result = SimklFileResult(
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
    } else {
      result = null;
    }
  }

  // cache result in MediaShows
  if (result != null) {
    await db.upsertShow(
      MediaShowsCompanion(
        groupTitle: Value(groupTitle),
        resolvedTitle: Value(result.title),
        titleEn: Value(result.titleEn),
        mediaType: Value(result.mediaType),
        animeType: Value(result.animeType),
        year: Value(result.year),
        totalEpisodes: Value(result.totalEpisodes),
        posterPath: Value(result.posterPath),
        fanartPath: Value(result.fanartPath),
        overview: Value(result.overview),
        simklId: Value(result.simklId),
        simklSlug: Value(result.slug),
        imdbId: Value(result.imdbId),
        tmdbId: Value(result.tmdbId),
        malId: Value(result.malId),
        anilistId: Value(result.anilistId),
        tvdbId: Value(result.tvdbId),
        anidbId: Value(result.anidbId),
        ratingSimkl: Value(result.ratingSimkl),
        ratingMal: Value(result.ratingMal),
        ratingImdb: Value(result.ratingImdb),
        resolvedAt: Value(DateTime.now()),
      ),
    );

    debugPrint(
      '[Metadata] Cached "${result.title}" '
      '(simkl:${result.simklId}, mal:${result.malId})',
    );

    return ShowMetadata(
      title: result.title,
      titleEn: result.titleEn,
      overview: result.overview,
      posterUrl: SimklProvider.posterUrl(result.posterPath),
      posterPath: result.posterPath,
      backdropUrl: SimklProvider.fanartUrl(result.fanartPath),
      fanartPath: result.fanartPath,
      year: result.year,
      rating: result.ratingSimkl ?? result.ratingImdb ?? result.ratingMal,
      ratingSimkl: result.ratingSimkl,
      ratingMal: result.ratingMal,
      ratingImdb: result.ratingImdb,
      simklId: result.simklId,
      mediaType: result.mediaType,
      slug: result.slug,
    );
  }

  debugPrint('[Metadata] No Simkl match for "$groupTitle"');
  await db.upsertShow(
    MediaShowsCompanion(
      groupTitle: Value(groupTitle),
      resolvedAt: Value(DateTime.now()),
    ),
  );
  return null;
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
