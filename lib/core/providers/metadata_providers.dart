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

  // call simkl file search with raw filename
  final simkl = ref.watch(simklProvider);
  final fileResult = await simkl.fetchMetadataByFilename(
    representative.rawName,
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
    final fullMeta = await simkl.fetchMetadata(clean.title, year: targetYear ?? clean.year);
    if (fullMeta != null) {
      result = SimklFileResult(
        title: fullMeta.title,
        titleEn: fullMeta.titleEn,
        year: fullMeta.year,
        posterPath: fullMeta.posterPath,
        fanartPath: fullMeta.fanartPath,
        overview: fullMeta.overview,
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
