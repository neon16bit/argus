import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:argus/data/scrapers/scrape_result.dart';
import 'tables/sources.dart';
import 'tables/media_items.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Sources, MediaItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // create FTS5 virtual table for full text search
      await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
              clean_title,
              raw_name,
              content='media_items',
              content_rowid='id'
            )
          ''');
      // triggers to keep FTS index in sync
      await customStatement('''
            CREATE TRIGGER IF NOT EXISTS media_items_ai AFTER INSERT ON media_items BEGIN
              INSERT INTO search_index(rowid, clean_title, raw_name)
              VALUES (new.id, new.clean_title, new.raw_name);
            END
          ''');
      await customStatement('''
            CREATE TRIGGER IF NOT EXISTS media_items_ad AFTER DELETE ON media_items BEGIN
              INSERT INTO search_index(search_index, rowid, clean_title, raw_name)
              VALUES ('delete', old.id, old.clean_title, old.raw_name);
            END
          ''');
      await customStatement('''
            CREATE TRIGGER IF NOT EXISTS media_items_au AFTER UPDATE ON media_items BEGIN
              INSERT INTO search_index(search_index, rowid, clean_title, raw_name)
              VALUES ('delete', old.id, old.clean_title, old.raw_name);
              INSERT INTO search_index(rowid, clean_title, raw_name)
              VALUES (new.id, new.clean_title, new.raw_name);
            END
          ''');
    },
  );

  // source operations

  Future<List<Source>> getAllSources() => select(sources).get();

  Stream<List<Source>> watchAllSources() => select(sources).watch();

  Future<Source> getSource(int id) =>
      (select(sources)..where((s) => s.id.equals(id))).getSingle();

  Future<int> insertSource(SourcesCompanion source) =>
      into(sources).insert(source);

  Future<bool> updateSource(Source source) => update(sources).replace(source);

  Future<int> deleteSource(int id) =>
      (delete(sources)..where((s) => s.id.equals(id))).go();

  Future<Source?> getSourceByUrl(String url) =>
      (select(sources)..where((s) => s.baseUrl.equals(url))).getSingleOrNull();

  Future<void> setSourceOnline(int id, bool online) =>
      (update(sources)..where((s) => s.id.equals(id))).write(
        SourcesCompanion(isOnline: Value(online)),
      );

  Future<void> setSourceLastScraped(int id, DateTime time) =>
      (update(sources)..where((s) => s.id.equals(id))).write(
        SourcesCompanion(lastScraped: Value(time)),
      );

  // media item operations

  Future<List<MediaItem>> getMediaItemsBySource(int sourceId) =>
      (select(mediaItems)..where((m) => m.sourceId.equals(sourceId))).get();

  Future<void> insertMediaItemsBatch(List<MediaItemsCompanion> items) async {
    await batch(
      (b) => b.insertAll(mediaItems, items, mode: InsertMode.insertOrIgnore),
    );
  }

  Future<int> deleteMediaItemsBySource(int sourceId) =>
      (delete(mediaItems)..where((m) => m.sourceId.equals(sourceId))).go();

  Future<int> getMediaItemCount() async {
    final count = countAll();
    final query = selectOnly(mediaItems)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getMediaItemCountBySource(int sourceId) async {
    final count = countAll();
    final query = selectOnly(mediaItems)
      ..addColumns([count])
      ..where(mediaItems.sourceId.equals(sourceId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // FTS5 search

  Future<List<MediaItem>> searchMedia(String query) async {
    if (query.trim().isEmpty) return [];
    // escape FTS5 special chars and add prefix matching
    final escaped = query.replaceAll('"', '""');
    final ftsQuery = '"$escaped"*';
    final results = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN search_index si ON si.rowid = m.id
      WHERE search_index MATCH ?
      ORDER BY rank
      LIMIT 200
      ''',
      variables: [Variable.withString(ftsQuery)],
      readsFrom: {mediaItems},
    ).get();
    return results.map((row) => mediaItems.map(row.data)).toList();
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'argus_db');
  }
}
