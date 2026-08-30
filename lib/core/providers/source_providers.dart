import 'dart:async';
import 'dart:convert';
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

class ScrapedSourcesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final keys = prefs.getKeys();
    final scrapedIds = <int>{};
    for (final key in keys) {
      if (key.startsWith('scraped_')) {
        final idStr = key.substring(8);
        final id = int.tryParse(idStr);
        if (id != null && prefs.getBool(key) == true) {
          scrapedIds.add(id);
        }
      }
    }
    return scrapedIds;
  }

  Future<void> markScraped(int sourceId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('scraped_$sourceId', true);
    state = {...state, sourceId};
  }

  Future<void> clearScraped(int sourceId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('scraped_$sourceId');
    state = {...state}..remove(sourceId);
  }
}

final scrapedSourcesProvider =
    NotifierProvider<ScrapedSourcesNotifier, Set<int>>(
      ScrapedSourcesNotifier.new,
    );

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

final mediaItemsCountBySourceProvider = FutureProvider.family<int, int>((
  ref,
  sourceId,
) {
  final db = ref.watch(databaseProvider);
  return db.getMediaItemCountBySource(sourceId);
});

final sourceActionsProvider = Provider<SourceActions>((ref) {
  return SourceActions(ref.watch(databaseProvider), ref);
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
  final Ref ref;
  SourceActions(this.db, this.ref);

  Future<String?> addSource(
    String name,
    String url,
    int maxDepth,
    bool autoScrape,
    int? requestDelayMs,
  ) async {
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
        autoScrape: Value(autoScrape),
        requestDelayMs: Value(requestDelayMs),
      ),
    );

    return online ? null : 'Source saved but appears offline';
  }

  Future<String?> updateSource(
    int id,
    String name,
    String url,
    int maxDepth,
    bool autoScrape,
    int? requestDelayMs,
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
      ref.read(scrapedSourcesProvider.notifier).clearScraped(id);
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
        autoScrape: autoScrape,
        requestDelayMs: requestDelayMs,
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
    await ref.read(scrapedSourcesProvider.notifier).markScraped(source.id);

    return results.length;
  }

  Stream<ScrapeProgress> scrapeSourceWithProgress(
    Source source, {
    bool fullScrape = false,
    int maxDepth = 1,
  }) async* {
    // shallow mode: index top level folders only
    if (!fullScrape) {
      final controller = StreamController<ScrapeProgress>();
      bool isCancelled = false;
      controller.onCancel = () {
        isCancelled = true;
      };

      controller.add(
        const ScrapeProgress(
          message: 'Indexing folders...',
          urlsQueued: 1,
          isShallow: true,
        ),
      );

      DirectoryScraper.shallowIndex(
            source.baseUrl,
            maxDepth: maxDepth,
            onProgress: (pages, folders) {
              if (isCancelled) return;
              controller.add(
                ScrapeProgress(
                  message: 'Indexing folders...',
                  urlsVisited: pages,
                  urlsQueued: 1,
                  filesFound: folders,
                  isShallow: true,
                ),
              );
            },
          )
          .then((folders) async {
            if (isCancelled) return;
            if (folders != null) {
              final existingFolders = await db.getIndexedFoldersBySource(
                source.id,
              );
              if (isCancelled) return;
              final existingMap = {
                for (final f in existingFolders) f.folderUrl: f,
              };
              final newUrls = folders.map((f) => f.folderUrl).toSet();

              final foldersToDelete = existingFolders
                  .where((f) => !newUrls.contains(f.folderUrl))
                  .toList();
              final foldersToInsert = folders
                  .where((f) => !existingMap.containsKey(f.folderUrl))
                  .toList();

              if (isCancelled) return;
              if (foldersToDelete.isNotEmpty) {
                final idsToDelete = foldersToDelete.map((f) => f.id).toList();
                await db.deleteIndexedFoldersByIds(idsToDelete);

                // Also delete media items from deleted folders to keep DB clean
                for (final f in foldersToDelete) {
                  if (isCancelled) return;
                  await db.deleteMediaItemsByFolderUrl(source.id, f.folderUrl);
                }
              }

              if (isCancelled) return;
              final isFirstScrape = existingFolders.isEmpty;

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

              if (isCancelled) return;
              await db.setSourceLastScraped(source.id, DateTime.now());
              await db.setSourceOnline(source.id, true);
              await ref
                  .read(scrapedSourcesProvider.notifier)
                  .markScraped(source.id);

              if (isCancelled) return;
              controller.add(
                ScrapeProgress(
                  message: isFirstScrape
                      ? 'Added ${foldersToInsert.length} folders.'
                      : (foldersToInsert.isNotEmpty ||
                                foldersToDelete.isNotEmpty
                            ? 'Added ${foldersToInsert.length} new, deleted ${foldersToDelete.length} obsolete folders.'
                            : 'Already up to date.'),
                  filesFound: folders.length,
                  addedCount: foldersToInsert.length,
                  deletedCount: foldersToDelete.length,
                  isShallow: true,
                  isDone: true,
                ),
              );
            } else {
              if (isCancelled) return;
              controller.add(
                const ScrapeProgress(
                  message: 'Show level source detected, full scraping...',
                  isShallow: true,
                ),
              );
            }
            controller.close();
          })
          .catchError((err) {
            if (isCancelled) return;
            controller.addError(err);
            controller.close();
          });

      await for (final progress in controller.stream) {
        if (progress.message ==
            'Show level source detected, full scraping...') {
          break;
        }
        yield progress;
        if (progress.isDone) {
          return;
        }
      }
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

    final isFirstScrape = existingItems.isEmpty;

    await db.setSourceLastScraped(source.id, DateTime.now());
    await db.setSourceOnline(source.id, true);
    await ref.read(scrapedSourcesProvider.notifier).markScraped(source.id);

    yield ScrapeProgress(
      message: isFirstScrape
          ? 'Done! Saved ${itemsToInsert.length} items.'
          : (itemsToInsert.isNotEmpty || itemsToDelete.isNotEmpty
                ? 'Done! Added ${itemsToInsert.length} new, deleted ${itemsToDelete.length} obsolete files.'
                : 'Already up to date.'),
      filesFound: collectedResults.length,
      addedCount: itemsToInsert.length,
      deletedCount: itemsToDelete.length,
      isDone: true,
    );
  }

  // full scrapes a single indexed folder and inserts its media items
  Future<void> deepScrapeFolder(
    IndexedFolder folder, {
    Duration requestDelay = Duration.zero,
  }) async {
    final results = <ScrapeResult>[];
    Set<String> failedUrls = {};
    await for (final p in DirectoryScraper.scrapeWithProgress(
      folder.folderUrl,
      requestDelay: requestDelay,
      groupTitle: folder.cleanTitle,
    )) {
      if (p.isDone) {
        results.addAll(p.results);
        failedUrls = p.failedUrls;
        break;
      }
    }
    if (results.isEmpty) {
      await db.markFolderScraped(folder.id, failedUrls: failedUrls.toList());
      return;
    }

    // prevents items missing a year tag from being orphaned under a different title
    final canonicalResult = results.firstWhere(
      (r) => r.year != null,
      orElse: () => results.first,
    );
    for (var i = 0; i < results.length; i++) {
      results[i] = results[i].copyWith(
        groupTitle: canonicalResult.groupTitle,
        year: canonicalResult.year,
      );
    }

    final existingItems = await db.getMediaItemsByFolderUrl(
      folder.sourceId,
      folder.folderUrl,
    );
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
    final String? cleanTitle = results.isNotEmpty
        ? results.first.groupTitle
        : null;
    await db.markFolderScraped(
      folder.id,
      cleanTitle: cleanTitle,
      failedUrls: failedUrls.toList(),
    );
  }

  // retries only the URLs that failed during a previous scrape
  Future<void> retryScrapeErrors(
    IndexedFolder folder, {
    Duration requestDelay = Duration.zero,
  }) async {
    if (folder.scrapeErrors == null) return;
    final List<dynamic> errorUrls;
    try {
      errorUrls = jsonDecode(folder.scrapeErrors!) as List<dynamic>;
    } catch (_) {
      return;
    }
    if (errorUrls.isEmpty) return;

    final allResults = <ScrapeResult>[];
    final remainingErrors = <String>{};

    for (final errorUrl in errorUrls) {
      final url = errorUrl as String;
      await for (final p in DirectoryScraper.scrapeWithProgress(
        url,
        requestDelay: requestDelay,
        groupTitle: folder.cleanTitle,
      )) {
        if (p.isDone) {
          allResults.addAll(p.results);
          remainingErrors.addAll(p.failedUrls);
          break;
        }
      }
    }

    if (allResults.isNotEmpty) {
      // normalize group title to match existing items
      final canonicalResult = allResults.firstWhere(
        (r) => r.year != null,
        orElse: () => allResults.first,
      );
      for (var i = 0; i < allResults.length; i++) {
        allResults[i] = allResults[i].copyWith(
          groupTitle: canonicalResult.groupTitle,
          year: canonicalResult.year,
        );
      }

      // insert only merge, dont delete existing items from good seasons
      final existingItems = await db.getMediaItemsByFolderUrl(
        folder.sourceId,
        folder.folderUrl,
      );
      final existingMap = {for (final m in existingItems) m.directUrl: m};
      final itemsToInsert = allResults
          .where((r) => !existingMap.containsKey(r.directUrl))
          .toList();

      final companions = itemsToInsert
          .map((r) => _toCompanion(r, folder.sourceId))
          .toList();

      for (var i = 0; i < companions.length; i += kInsertBatchSize) {
        final end = (i + kInsertBatchSize).clamp(0, companions.length);
        await db.insertMediaItemsBatch(companions.sublist(i, end));
      }
      for (final r in allResults) {
        if (r.year != null) await db.insertShowStub(r.groupTitle, r.year!);
      }
    }

    // update scrape errors, clear if all succeeded, or update with remaining
    await db.markFolderScraped(folder.id, failedUrls: remainingErrors.toList());
  }

  Future<void> deleteSource(int id) async {
    await db.deleteMediaItemsBySource(id);
    await db.deleteIndexedFoldersBySource(id);
    await db.deleteSource(id);
    ref.read(scrapedSourcesProvider.notifier).clearScraped(id);
  }
}
