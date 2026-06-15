import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:argus/data/scrapers/scrape_result.dart';
import 'tables/sources.dart';
import 'tables/media_items.dart';
import 'tables/media_shows.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Sources, MediaItems, MediaShows])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 4;

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

  Future<List<MediaItem>> getMediaItemsByGroupTitle(String groupTitle) async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      WHERE m.group_title IN (
        SELECT s2.group_title FROM media_shows s2
        WHERE s2.simkl_id = (
          SELECT simkl_id FROM media_shows WHERE group_title = ?1
        )
        AND s2.simkl_id IS NOT NULL
        UNION
        SELECT ?1 -- fallback if simkl_id is null
      )
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
      WHERE m.group_title IN (
        SELECT s2.group_title FROM media_shows s2
        WHERE s2.simkl_id = (
          SELECT simkl_id FROM media_shows WHERE group_title = ?1
        )
        AND s2.simkl_id IS NOT NULL
        UNION
        SELECT ?1
      )
      ORDER BY m.group_title, m.id
      ''',
      variables: [Variable.withString(groupTitle)],
      readsFrom: {mediaItems, mediaShows},
    ).watch().map(
      (rows) => rows.map((row) => mediaItems.map(row.data)).toList(),
    );
  }

  // FTS5 search on titles
  Future<List<Map<String, dynamic>>> searchShows(String query) async {
    if (query.trim().isEmpty) return [];
    // escape FTS5 special chars and add prefix matching
    final escaped = query.replaceAll('"', '""');
    final ftsQuery = '"$escaped"*';
    final results = await customSelect(
      '''
      SELECT
        COALESCE(s.simkl_id, m.group_title) as result_key,
        m.group_title,
        s.resolved_title,
        s.title_en,
        s.poster_path,
        s.media_type,
        s.year,
        COUNT(m.id) as item_count
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
      ORDER BY COUNT(m.id) DESC
      LIMIT 50
      ''',
      variables: [
        Variable.withString(ftsQuery),
        Variable.withString('%$query%'),
      ],
      readsFrom: {mediaItems, mediaShows},
    ).get();
    return results.map((row) => row.data).toList();
  }

  Stream<List<Map<String, dynamic>>> watchSearchShows(String query) {
    if (query.trim().isEmpty) return Stream.value([]);
    final escaped = query.replaceAll('"', '""');
    final ftsQuery = '"$escaped"*';
    return customSelect(
      '''
      SELECT
        COALESCE(s.simkl_id, m.group_title) as result_key,
        m.group_title,
        s.resolved_title,
        s.title_en,
        s.poster_path,
        s.media_type,
        s.year,
        COUNT(m.id) as item_count
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
      ORDER BY COUNT(m.id) DESC
      LIMIT 50
      ''',
      variables: [
        Variable.withString(ftsQuery),
        Variable.withString('%$query%'),
      ],
      readsFrom: {mediaItems, mediaShows},
    ).watch().map((rows) => rows.map((row) => row.data).toList());
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'argus_db');
  }
}
