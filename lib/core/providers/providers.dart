import 'package:argus/core/constants.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/data/remote/metadata/metadata_provider.dart';
import 'package:argus/data/remote/metadata/simkl_provider.dart';
import 'package:argus/data/scrapers/directory_scraper.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final packageInfoProvider = Provider<PackageInfo>((ref) {
  throw UnimplementedError('Initialized in main()');
});

final simklProvider = Provider<SimklProvider>((ref) {
  final packageInfo = ref.watch(packageInfoProvider);
  return SimklProvider(
    appName: packageInfo.appName,
    appVersion: packageInfo.version,
  );
});

final metadataProvider = FutureProvider.family<ShowMetadata?, String>((
  ref,
  title,
) async {
  final simkl = ref.watch(simklProvider);

  var result = await simkl.fetchMetadata(title);
  return result;
});

// sources
final sourcesProvider = StreamProvider<List<Source>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSources();
});

// media items
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
    final results = await DirectoryScraper.scrapeDirectory(source.baseUrl);
    if (results.isEmpty) return 0;

    await db.deleteMediaItemsBySource(source.id);

    final companionsList = results
        .map(
          (r) => MediaItemsCompanion(
            sourceId: Value(source.id),
            rawName: Value(r.rawName),
            cleanTitle: Value(r.cleanTitle),
            directUrl: Value(r.directUrl),
            type: Value(r.type),
            season: Value(r.season),
            episode: Value(r.episode),
            fileExtension: Value(r.fileExtension),
            fileSize: Value(r.fileSize),
          ),
        )
        .toList();

    for (var i = 0; i < companionsList.length; i += kInsertBatchSize) {
      final end = (i + kInsertBatchSize).clamp(0, companionsList.length);
      await db.insertMediaItemsBatch(companionsList.sublist(i, end));
    }

    await db.setSourceLastScraped(source.id, DateTime.now());
    await db.setSourceOnline(source.id, true);

    return companionsList.length;
  }

  // scrapes with real time progress
  Stream<ScrapeProgress> scrapeSourceWithProgress(Source source) async* {
    await for (final progress in DirectoryScraper.scrapeWithProgress(
      source.baseUrl,
    )) {
      yield progress;
      if (progress.isDone) break;
    }

    final collectedResults = await DirectoryScraper.scrapeDirectory(
      source.baseUrl,
    );

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

    final companionsList = collectedResults
        .map(
          (r) => MediaItemsCompanion(
            sourceId: Value(source.id),
            rawName: Value(r.rawName),
            cleanTitle: Value(r.cleanTitle),
            directUrl: Value(r.directUrl),
            type: Value(r.type),
            season: Value(r.season),
            episode: Value(r.episode),
            fileExtension: Value(r.fileExtension),
            fileSize: Value(r.fileSize),
          ),
        )
        .toList();

    for (var i = 0; i < companionsList.length; i += kInsertBatchSize) {
      final end = (i + kInsertBatchSize).clamp(0, companionsList.length);
      await db.insertMediaItemsBatch(companionsList.sublist(i, end));
    }

    await db.setSourceLastScraped(source.id, DateTime.now());
    await db.setSourceOnline(source.id, true);

    yield ScrapeProgress(
      message: 'Done! Saved ${companionsList.length} items.',
      filesFound: companionsList.length,
      isDone: true,
    );
  }

  Future<void> deleteSource(int id) async {
    await db.deleteMediaItemsBySource(id);
    await db.deleteSource(id);
  }
}

final sourceActionsProvider = Provider<SourceActions>((ref) {
  return SourceActions(ref.watch(databaseProvider));
});

// search
class SearchResult {
  final String cleanTitle;
  final List<MediaItem> items;

  SearchResult({required this.cleanTitle, List<MediaItem>? items})
    : items = items ?? [];

  int get totalSources => items.length;
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final db = ref.watch(databaseProvider);

  final mediaFuture = db.searchMedia(query);

  final items = await mediaFuture;

  final grouped = <String, SearchResult>{};

  for (final item in items) {
    final key = item.cleanTitle.toLowerCase();
    final existing = grouped[key];
    if (existing != null) {
      existing.items.add(item);
    } else {
      grouped[key] = SearchResult(cleanTitle: item.cleanTitle, items: [item]);
    }
  }
  return grouped.values.toList();
});
