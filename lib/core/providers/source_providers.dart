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

final indexedFoldersCountBySourceProvider = FutureProvider.family<int, int>((
  ref,
  sourceId,
) {
  final db = ref.watch(databaseProvider);
  return db.getIndexedFolderCountBySource(sourceId);
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

  Future<String?> addSource(String name, String url, int maxDepth) async {
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
        maxDepth: Value(maxDepth),
      ),
    );

    return online ? null : 'Source saved but appears offline';
  }

  Future<String?> updateSource(
    int id,
    String name,
    String url,
    int maxDepth,
  ) async {
    if (!url.endsWith('/')) url = '$url/';
    if (!url.startsWith('http')) url = 'http://$url';

    final current = await db.getSource(id);
    final urlChanged = current.baseUrl != url;
    final depthChanged = current.maxDepth != maxDepth;
    final dataCleared = urlChanged || depthChanged;

    if (urlChanged) {
      final existing = await db.getSourceByUrl(url);
      if (existing != null) {
        return 'Another source with this URL already exists';
      }
    }

    bool online = current.isOnline;
    if (urlChanged) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(kPingTimeout);
        online = response.statusCode == 200;
      } catch (_) {
        online = false;
      }
    }

    if (dataCleared) {
      // clear old scraped items because source URL or structure changed
      await db.deleteMediaItemsBySource(id);
      await db.deleteIndexedFoldersBySource(id);
    }

    await db.updateSource(
      Source(
        id: id,
        name: name,
        baseUrl: url,
        isOnline: online,
        lastScraped: dataCleared ? null : current.lastScraped,
        createdAt: current.createdAt,
        maxDepth: maxDepth,
      ),
    );

    return null;
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

    final existingItems = await db.getMediaItemsBySource(source.id);
    final existingMap = {for (final m in existingItems) m.directUrl: m};
    final newUrls = results.map((r) => r.directUrl).toSet();

    final itemsToDelete = existingItems
        .where((m) => !newUrls.contains(m.directUrl))
        .toList();
    final itemsToInsert = results
        .where((r) => !existingMap.containsKey(r.directUrl))
        .toList();

    if (itemsToDelete.isNotEmpty) {
      final idsToDelete = itemsToDelete.map((m) => m.id).toList();
      await db.deleteMediaItemsByIds(idsToDelete);
    }

    final companions = itemsToInsert
        .map((r) => _toCompanion(r, source.id))
        .toList();

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

    return results.length;
  }

  Stream<ScrapeProgress> scrapeSourceWithProgress(
    Source source, {
    bool fullScrape = false,
    int maxDepth = 1,
  }) async* {
    // shallow mode: index top level folders only
    if (!fullScrape) {
      yield const ScrapeProgress(message: 'Indexing folders...', urlsQueued: 1);
      final folders = await DirectoryScraper.shallowIndex(
        source.baseUrl,
        maxDepth: maxDepth,
      );

      // null = show level sourcee
      if (folders != null) {
        final existingFolders = await db.getIndexedFoldersBySource(source.id);
        final existingMap = {for (final f in existingFolders) f.folderUrl: f};
        final newUrls = folders.map((f) => f.folderUrl).toSet();

        final foldersToDelete = existingFolders
            .where((f) => !newUrls.contains(f.folderUrl))
            .toList();
        final foldersToInsert = folders
            .where((f) => !existingMap.containsKey(f.folderUrl))
            .toList();

        if (foldersToDelete.isNotEmpty) {
          final idsToDelete = foldersToDelete.map((f) => f.id).toList();
          await db.deleteIndexedFoldersByIds(idsToDelete);

          // Also delete media items from deleted folders to keep DB clean
          for (final f in foldersToDelete) {
            await (db.delete(db.mediaItems)..where(
                  (m) =>
                      m.sourceId.equals(source.id) &
                      m.directUrl.like('${f.folderUrl}%'),
                ))
                .go();
          }
        }

        if (foldersToInsert.isNotEmpty) {
          await db.insertIndexedFoldersBatch(
            foldersToInsert
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

    final existingItems = await db.getMediaItemsBySource(source.id);
    final existingMap = {for (final m in existingItems) m.directUrl: m};
    final newUrls = collectedResults.map((r) => r.directUrl).toSet();

    final itemsToDelete = existingItems
        .where((m) => !newUrls.contains(m.directUrl))
        .toList();
    final itemsToInsert = collectedResults
        .where((r) => !existingMap.containsKey(r.directUrl))
        .toList();

    if (itemsToDelete.isNotEmpty) {
      final idsToDelete = itemsToDelete.map((m) => m.id).toList();
      await db.deleteMediaItemsByIds(idsToDelete);
    }

    final companions = itemsToInsert
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
      message: 'Done! Saved ${collectedResults.length} items.',
      filesFound: collectedResults.length,
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
      groupTitle: folder.cleanTitle,
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

    final existingItems =
        await (db.select(db.mediaItems)..where(
              (m) =>
                  m.sourceId.equals(folder.sourceId) &
                  m.directUrl.like('${folder.folderUrl}%'),
            ))
            .get();
    final existingMap = {for (final m in existingItems) m.directUrl: m};
    final newUrls = results.map((r) => r.directUrl).toSet();

    final itemsToDelete = existingItems
        .where((m) => !newUrls.contains(m.directUrl))
        .toList();
    final itemsToInsert = results
        .where((r) => !existingMap.containsKey(r.directUrl))
        .toList();

    if (itemsToDelete.isNotEmpty) {
      final idsToDelete = itemsToDelete.map((m) => m.id).toList();
      await db.deleteMediaItemsByIds(idsToDelete);
    }

    final companions = itemsToInsert
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
