import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:argus/data/scrapers/scrape_result.dart';
import 'tables/sources.dart';
import 'tables/media_items.dart';
import 'tables/media_shows.dart';
import 'tables/indexed_folders.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Sources, MediaItems, MediaShows, IndexedFolders])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createFts(m);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // add group_title column, backfill from clean_title
        await m.addColumn(mediaItems, mediaItems.groupTitle);
        await customStatement(
          "UPDATE media_items SET group_title = clean_title WHERE group_title = ''",
        );
        // create media_shows table
        await m.createTable(mediaShows);
        // rebuild FTS to use group_title instead of clean_title + raw_name
        await customStatement('DROP TRIGGER IF EXISTS media_items_ai');
        await customStatement('DROP TRIGGER IF EXISTS media_items_ad');
        await customStatement('DROP TRIGGER IF EXISTS media_items_au');
        await customStatement('DROP TABLE IF EXISTS search_index');
        await _createFts(m);
        // repopulate FTS from existing data
        await customStatement('''
          INSERT INTO search_index(rowid, group_title)
          SELECT id, group_title FROM media_items
        ''');
      }
      if (from < 3) {
        // add titleEn column to mediaShows
        await m.addColumn(mediaShows, mediaShows.titleEn);
      }
      if (from < 4) {
        // add rating columns to mediaShows
        await m.addColumn(mediaShows, mediaShows.ratingSimkl);
        await m.addColumn(mediaShows, mediaShows.ratingMal);
        await m.addColumn(mediaShows, mediaShows.ratingImdb);
      }
      if (from < 5) {
        await m.createTable(indexedFolders);
      }
      if (from < 6) {
        await m.addColumn(sources, sources.maxDepth);
      }
    },
  );

  Future<void> _createFts(Migrator m) async {
    // only group_title for search
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
        group_title,
        content='media_items',
        content_rowid='id'
      )
    ''');
    // triggers to keep FTS index in sync
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS media_items_ai AFTER INSERT ON media_items BEGIN
        INSERT INTO search_index(rowid, group_title)
        VALUES (new.id, new.group_title);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS media_items_ad AFTER DELETE ON media_items BEGIN
        INSERT INTO search_index(search_index, rowid, group_title)
        VALUES ('delete', old.id, old.group_title);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS media_items_au AFTER UPDATE ON media_items BEGIN
        INSERT INTO search_index(search_index, rowid, group_title)
        VALUES ('delete', old.id, old.group_title);
        INSERT INTO search_index(rowid, group_title)
        VALUES (new.id, new.group_title);
      END
    ''');
  }

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

  Future<int> getIndexedFolderCountBySource(int sourceId) async {
    final count = countAll();
    final query = selectOnly(indexedFolders)
      ..addColumns([count])
      ..where(indexedFolders.sourceId.equals(sourceId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // indexed folder operations
  Future<void> insertIndexedFoldersBatch(
    List<IndexedFoldersCompanion> folders,
  ) => batch(
    (b) =>
        b.insertAll(indexedFolders, folders, mode: InsertMode.insertOrReplace),
  );

  Future<void> markFolderScraped(int id) =>
      (update(indexedFolders)..where((f) => f.id.equals(id))).write(
        IndexedFoldersCompanion(
          isScraped: const Value(true),
          lastScraped: Value(DateTime.now()),
        ),
      );

  Future<IndexedFolder?> getFolderByUrl(String url) => (select(
    indexedFolders,
  )..where((f) => f.folderUrl.equals(url))).getSingleOrNull();

  Future<int> deleteIndexedFoldersBySource(int sourceId) =>
      (delete(indexedFolders)..where((f) => f.sourceId.equals(sourceId))).go();

  Stream<List<IndexedFolder>> watchFoldersBySource(int sourceId) => (select(
    indexedFolders,
  )..where((f) => f.sourceId.equals(sourceId))).watch();

  Future<List<IndexedFolder>> getIndexedFoldersBySource(int sourceId) =>
      (select(indexedFolders)..where((f) => f.sourceId.equals(sourceId))).get();

  Future<void> deleteIndexedFoldersByIds(List<int> ids) =>
      (delete(indexedFolders)..where((f) => f.id.isIn(ids))).go();

  Future<void> deleteMediaItemsByIds(List<int> ids) =>
      (delete(mediaItems)..where((m) => m.id.isIn(ids))).go();

  // media show operations
  Future<MediaShow?> getShowByGroupTitle(String groupTitle) => (select(
    mediaShows,
  )..where((s) => s.groupTitle.equals(groupTitle))).getSingleOrNull();

  Future<void> upsertShow(MediaShowsCompanion show) => into(mediaShows).insert(
    show,
    onConflict: DoUpdate((old) => show, target: [mediaShows.groupTitle]),
  );

  Future<void> clearShowCache(String groupTitle) =>
      (update(mediaShows)..where((s) => s.groupTitle.equals(groupTitle))).write(
        const MediaShowsCompanion(resolvedAt: Value(null)),
      );

  Future<void> insertShowStub(String groupTitle, int year) =>
      into(mediaShows).insert(
        MediaShowsCompanion(groupTitle: Value(groupTitle), year: Value(year)),
        mode: InsertMode.insertOrIgnore,
      );

  static const _kGroupTitlesSubquery = '''
    SELECT s2.group_title FROM media_shows s2
    WHERE s2.simkl_id = (
      SELECT simkl_id FROM media_shows WHERE group_title = ?1
    )
    AND s2.simkl_id IS NOT NULL
    UNION
    SELECT ?1 -- fallback if simkl_id is null
  ''';

  Future<List<MediaItem>> getMediaItemsByGroupTitle(String groupTitle) async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      WHERE m.group_title IN ($_kGroupTitlesSubquery)
      ORDER BY m.group_title, m.id
      ''',
      variables: [Variable.withString(groupTitle)],
      readsFrom: {mediaItems, mediaShows},
    ).get();

    return rows.map((row) => mediaItems.map(row.data)).toList();
  }

  Stream<List<MediaItem>> watchMediaItemsByGroupTitle(String groupTitle) {
    return customSelect(
      '''
      SELECT m.* FROM media_items m
      WHERE m.group_title IN ($_kGroupTitlesSubquery)
      ORDER BY m.group_title, m.id
      ''',
      variables: [Variable.withString(groupTitle)],
      readsFrom: {mediaItems, mediaShows},
    ).watch().map(
      (rows) => rows.map((row) => mediaItems.map(row.data)).toList(),
    );
  }

  // FTS5 search on titles + indexed folders
  static const _kSearchSql = '''
    SELECT
      COALESCE(s.simkl_id, m.group_title) as result_key,
      m.group_title,
      s.resolved_title, s.title_en, s.poster_path, s.media_type, s.year,
      COUNT(m.id) as item_count,
      NULL as folder_url,
      1 as is_scraped
    FROM media_items m
    LEFT JOIN media_shows s ON m.group_title = s.group_title
    WHERE m.id IN (
      SELECT rowid FROM search_index WHERE search_index MATCH ?1
      UNION
      SELECT m2.id FROM media_items m2
      INNER JOIN media_shows s2 ON m2.group_title = s2.group_title
      WHERE s2.resolved_title LIKE ?2 OR s2.title_en LIKE ?2
    )
    GROUP BY COALESCE(s.simkl_id, m.group_title)

    UNION

    SELECT
      f.folder_url as result_key,
      f.clean_title as group_title,
      s.resolved_title, s.title_en, s.poster_path, s.media_type,
      COALESCE(s.year, f.year) as year,
      0 as item_count,
      f.folder_url as folder_url,
      f.is_scraped as is_scraped
    FROM indexed_folders f
    LEFT JOIN media_shows s ON f.clean_title = s.group_title
    WHERE f.clean_title LIKE ?2
    AND NOT EXISTS (
      SELECT 1 FROM media_items m3 WHERE m3.group_title = f.clean_title
    )

    ORDER BY item_count DESC
    LIMIT 50
  ''';

  Future<List<Map<String, dynamic>>> searchShows(String query) async {
    if (query.trim().isEmpty) return [];
    final escaped = query.replaceAll('"', '""');
    final results = await customSelect(
      _kSearchSql,
      variables: [
        Variable.withString('"$escaped"*'),
        Variable.withString('%$query%'),
      ],
      readsFrom: {mediaItems, mediaShows, indexedFolders},
    ).get();
    return results.map((row) => row.data).toList();
  }

  Stream<List<Map<String, dynamic>>> watchSearchShows(String query) {
    if (query.trim().isEmpty) return Stream.value([]);
    final escaped = query.replaceAll('"', '""');
    return customSelect(
      _kSearchSql,
      variables: [
        Variable.withString('"$escaped"*'),
        Variable.withString('%$query%'),
      ],
      readsFrom: {mediaItems, mediaShows, indexedFolders},
    ).watch().map((rows) => rows.map((row) => row.data).toList());
  }

  Future<List<IndexedFolder>> getFoldersByGroupTitle(String groupTitle) async {
    final rows = await customSelect(
      '''
      SELECT f.*
      FROM indexed_folders f
      WHERE f.clean_title IN ($_kGroupTitlesSubquery)
      ''',
      variables: [Variable.withString(groupTitle)],
      readsFrom: {indexedFolders, mediaShows},
    ).get();
    return rows.map((row) => indexedFolders.map(row.data)).toList();
  }

  Stream<List<IndexedFolder>> watchFoldersByGroupTitle(String groupTitle) {
    return customSelect(
      '''
      SELECT f.*
      FROM indexed_folders f
      WHERE f.clean_title IN ($_kGroupTitlesSubquery)
      ''',
      variables: [Variable.withString(groupTitle)],
      readsFrom: {indexedFolders, mediaShows},
    ).watch().map(
      (rows) => rows.map((row) => indexedFolders.map(row.data)).toList(),
    );
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbDir = await getApplicationSupportDirectory();
      final file = File(p.join(dbDir.path, 'argus_db.sqlite'));
      final cachebase = (await getTemporaryDirectory()).path;
      sqlite3.tempDirectory = cachebase;

      return NativeDatabase.createInBackground(file);
    });
  }
}
