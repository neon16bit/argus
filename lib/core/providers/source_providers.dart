import 'package:argus/core/constants.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/data/scrapers/directory_scraper.dart';
import 'package:argus/data/scrapers/scrape_result.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final sourcesProvider = StreamProvider<List<Source>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSources();
});

final mediaItemCountProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getMediaItemCount();
});

final mediaItemsBySourceProvider = FutureProvider.family<List<MediaItem>, int>((
  ref,
  sourceId,
) {
  final db = ref.watch(databaseProvider);
  return db.getMediaItemsBySource(sourceId);
});

final sourceActionsProvider = Provider<SourceActions>((ref) {
  return SourceActions(ref.watch(databaseProvider));
});

// converts a ScrapeResult to a MediaItemsCompanion for database insertion
MediaItemsCompanion _toCompanion(ScrapeResult r, int sourceId) {
  return MediaItemsCompanion(
    sourceId: Value(sourceId),
    rawName: Value(r.rawName),
    cleanTitle: Value(r.cleanTitle),
    groupTitle: Value(r.groupTitle),
    directUrl: Value(r.directUrl),
    type: Value(r.type),
    season: Value(r.season),
    episode: Value(r.episode),
    fileExtension: Value(r.fileExtension),
    fileSize: Value(r.fileSize),
  );
}

// source actions
class SourceActions {
  final AppDatabase db;
  SourceActions(this.db);

  Future<String?> addSource(String name, String url) async {
    if (!url.endsWith('/')) url = '$url/';
    if (!url.startsWith('http')) url = 'http://$url';

    final existing = await db.getSourceByUrl(url);
    if (existing != null) return 'Source already exists';

    bool online = false;
    try {
      final response = await http.get(Uri.parse(url)).timeout(kPingTimeout);
      online = response.statusCode == 200;
    } catch (_) {}

    await db.insertSource(
      SourcesCompanion(
        name: Value(name),
        baseUrl: Value(url),
        isOnline: Value(online),
      ),
    );

    return online ? null : 'Source saved but appears offline';
  }

  Future<bool> pingSource(Source source) async {
    try {
      final response = await http
          .get(Uri.parse(source.baseUrl))
          .timeout(kPingTimeout);
      final online = response.statusCode == 200;
      await db.setSourceOnline(source.id, online);
      return online;
    } catch (_) {
      await db.setSourceOnline(source.id, false);
      return false;
    }
  }

  Future<int> scrapeSource(Source source) async {
    List<ScrapeResult> results = [];
    await for (final progress in DirectoryScraper.scrapeWithProgress(
      source.baseUrl,
    )) {
      if (progress.isDone) {
        results = progress.results;
        break;
      }
    }

    if (results.isEmpty) return 0;

    await db.deleteMediaItemsBySource(source.id);

    final companions = results.map((r) => _toCompanion(r, source.id)).toList();

    for (var i = 0; i < companions.length; i += kInsertBatchSize) {
      final end = (i + kInsertBatchSize).clamp(0, companions.length);
      await db.insertMediaItemsBatch(companions.sublist(i, end));
    }

    // save extracted year stubs in media_shows
    for (final r in results) {
      if (r.year != null) {
        await db.insertShowStub(r.groupTitle, r.year!);
      }
    }

    await db.setSourceLastScraped(source.id, DateTime.now());
    await db.setSourceOnline(source.id, true);

    return companions.length;
  }

  Stream<ScrapeProgress> scrapeSourceWithProgress(
    Source source, {
    bool fullScrape = false,
  }) async* {
    // shallow mode: index top level folders only
    if (!fullScrape) {
      yield const ScrapeProgress(message: 'Indexing folders...', urlsQueued: 1);
      final folders = await DirectoryScraper.shallowIndex(source.baseUrl);

      // null = show level sourcee
      if (folders != null) {
        await db.deleteIndexedFoldersBySource(source.id);
        if (folders.isNotEmpty) {
          await db.insertIndexedFoldersBatch(
            folders
                .map(
                  (f) => IndexedFoldersCompanion(
                    sourceId: Value(source.id),
                    folderName: Value(f.rawName),
                    cleanTitle: Value(f.cleanTitle),
                    folderUrl: Value(f.folderUrl),
                    year: Value(f.year),
                  ),
                )
                .toList(),
          );
        }
        await db.setSourceLastScraped(source.id, DateTime.now());
        await db.setSourceOnline(source.id, true);
        yield ScrapeProgress(
          message: 'Indexed ${folders.length} folders.',
          filesFound: folders.length,
          isDone: true,
        );
        return;
      }
      // fall through to deep scrape for show level sources
      yield const ScrapeProgress(
        message: 'Show level source detected, full scraping...',
      );
    }

    List<ScrapeResult> collectedResults = [];

    await for (final progress in DirectoryScraper.scrapeWithProgress(
      source.baseUrl,
    )) {
      if (progress.isDone) {
        collectedResults = progress.results;
        break;
      }
      yield progress;
    }

    if (collectedResults.isEmpty) {
      yield const ScrapeProgress(
        message: 'No media files found.',
        isDone: true,
        filesFound: 0,
      );
      return;
    }

    yield ScrapeProgress(
      message: 'Saving ${collectedResults.length} items to database...',
      filesFound: collectedResults.length,
    );

    await db.deleteMediaItemsBySource(source.id);

    final companions = collectedResults
        .map((r) => _toCompanion(r, source.id))
        .toList();

    for (var i = 0; i < companions.length; i += kInsertBatchSize) {
      final end = (i + kInsertBatchSize).clamp(0, companions.length);
      await db.insertMediaItemsBatch(companions.sublist(i, end));
    }

    // save extracted year stubs in media_shows
    for (final r in collectedResults) {
      if (r.year != null) {
        await db.insertShowStub(r.groupTitle, r.year!);
      }
    }

    await db.setSourceLastScraped(source.id, DateTime.now());
    await db.setSourceOnline(source.id, true);

    yield ScrapeProgress(
      message: 'Done! Saved ${companions.length} items.',
      filesFound: companions.length,
      isDone: true,
    );
  }

  // full scrapes a single indexed folder and inserts its media items
  Future<void> deepScrapeFolder(
    IndexedFolder folder, {
    Duration requestDelay = Duration.zero,
  }) async {
    final results = <ScrapeResult>[];
    await for (final p in DirectoryScraper.scrapeWithProgress(
      folder.folderUrl,
      requestDelay: requestDelay,
    )) {
      if (p.isDone) {
        results.addAll(p.results);
        break;
      }
    }
    if (results.isEmpty) {
      await db.markFolderScraped(folder.id);
      return;
    }
    final companions = results
        .map((r) => _toCompanion(r, folder.sourceId))
        .toList();
    for (var i = 0; i < companions.length; i += kInsertBatchSize) {
      final end = (i + kInsertBatchSize).clamp(0, companions.length);
      await db.insertMediaItemsBatch(companions.sublist(i, end));
    }
    for (final r in results) {
      if (r.year != null) await db.insertShowStub(r.groupTitle, r.year!);
    }
    await db.markFolderScraped(folder.id);
  }

  Future<void> deleteSource(int id) async {
    await db.deleteMediaItemsBySource(id);
    await db.deleteIndexedFoldersBySource(id);
    await db.deleteSource(id);
  }
}
