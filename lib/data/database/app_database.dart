import 'dart:convert';
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
import 'tables/saved_shows.dart';
import 'tables/watch_history.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Sources,
    MediaItems,
    MediaShows,
    IndexedFolders,
    SavedShows,
    WatchHistory,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 11;

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
      if (from < 7) {
        // composite indexes for browse source pagination
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_folders_source_title '
          'ON indexed_folders (source_id, clean_title)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_items_source_group '
          'ON media_items (source_id, group_title)',
        );
      }
      if (from < 8) {
        await m.addColumn(sources, sources.autoScrape);
      }
      if (from < 9) {
        await m.addColumn(sources, sources.requestDelayMs);
        await m.addColumn(indexedFolders, indexedFolders.scrapeErrors);
      }
      if (from < 10) {
        await m.createTable(savedShows);
      }
      if (from < 11) {
        await m.createTable(watchHistory);
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

  Future<void> updateEpisodeNumbers(Map<int, int> itemIdToEpisode) async {
    await batch((b) {
      for (final entry in itemIdToEpisode.entries) {
        b.update(
          mediaItems,
          MediaItemsCompanion(episode: Value(entry.value)),
          where: ($MediaItemsTable m) => m.id.equals(entry.key),
        );
      }
    });
  }

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

  Future<void> markFolderScraped(
    int id, {
    String? cleanTitle,
    List<String>? failedUrls,
  }) => (update(indexedFolders)..where((f) => f.id.equals(id))).write(
    IndexedFoldersCompanion(
      isScraped: const Value(true),
      lastScraped: Value(DateTime.now()),
      cleanTitle: cleanTitle != null ? Value(cleanTitle) : const Value.absent(),
      scrapeErrors: failedUrls != null && failedUrls.isNotEmpty
          ? Value(jsonEncode(failedUrls))
          : const Value(null),
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

  Future<List<MediaItem>> getMediaItemsForEpisode({
    required String groupTitle,
    int? season,
    int? episode,
  }) async {
    final allItems = await getMediaItemsByGroupTitle(groupTitle);
    return allItems.where((m) {
      if (season != null && episode != null) {
        return m.season == season && m.episode == episode;
      } else if (episode != null) {
        return m.episode == episode;
      }
      return true;
    }).toList();
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
      s.resolved_title, s.title_en, s.poster_path,
      CASE
        WHEN s.mal_id IS NOT NULL OR s.anilist_id IS NOT NULL OR s.anidb_id IS NOT NULL THEN 'anime'
        WHEN s.media_type IS NOT NULL THEN s.media_type
        WHEN COUNT(CASE WHEN m.season IS NOT NULL OR m.episode IS NOT NULL THEN 1 END) > 0 THEN 'tv'
        ELSE 'movie'
      END as media_type,
      s.year,
      COUNT(m.id) as item_count,
      NULL as folder_url,
      1 as is_scraped,
      1 as auto_scrape
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
      s.resolved_title, s.title_en, s.poster_path,
      CASE
        WHEN s.mal_id IS NOT NULL OR s.anilist_id IS NOT NULL OR s.anidb_id IS NOT NULL THEN 'anime'
        WHEN s.media_type IS NOT NULL THEN s.media_type
        ELSE 'tv'
      END as media_type,
      COALESCE(s.year, f.year) as year,
      0 as item_count,
      f.folder_url as folder_url,
      f.is_scraped as is_scraped,
      src.auto_scrape as auto_scrape
    FROM indexed_folders f
    LEFT JOIN media_shows s ON f.clean_title = s.group_title
    LEFT JOIN sources src ON f.source_id = src.id
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

  Future<List<String>> getShowTitlesBySource(
    int sourceId, {
    String? searchQuery,
    int limit = 100,
    int offset = 0,
  }) async {
    // try indexed_folders first (grouped sources)
    final foldersQuery = selectOnly(indexedFolders)
      ..addColumns([indexedFolders.cleanTitle])
      ..where(indexedFolders.sourceId.equals(sourceId));
    if (searchQuery != null && searchQuery.isNotEmpty) {
      foldersQuery.where(indexedFolders.cleanTitle.like('%$searchQuery%'));
    }
    foldersQuery
      ..groupBy([indexedFolders.cleanTitle])
      ..orderBy([OrderingTerm(expression: indexedFolders.cleanTitle)])
      ..limit(limit, offset: offset);
    final foldersResult = await foldersQuery.get();

    // if we got results, or weare past the first page, use folders
    if (foldersResult.isNotEmpty || offset > 0) {
      return foldersResult
          .map((r) => r.read(indexedFolders.cleanTitle)!)
          .toList();
    }

    // fallback to media_items distinct group titles (flat sources)
    final itemsQuery = selectOnly(mediaItems)
      ..addColumns([mediaItems.groupTitle])
      ..where(mediaItems.sourceId.equals(sourceId));
    if (searchQuery != null && searchQuery.isNotEmpty) {
      itemsQuery.where(mediaItems.groupTitle.like('%$searchQuery%'));
    }
    itemsQuery
      ..groupBy([mediaItems.groupTitle])
      ..orderBy([OrderingTerm(expression: mediaItems.groupTitle)])
      ..limit(limit, offset: offset);
    final itemsResult = await itemsQuery.get();
    return itemsResult.map((r) => r.read(mediaItems.groupTitle)!).toList();
  }

  // saved shows

  Future<bool> isShowSaved(String groupTitle) async {
    final row = await (select(
      savedShows,
    )..where((b) => b.groupTitle.equals(groupTitle))).getSingleOrNull();
    return row != null;
  }

  Stream<bool> watchIsShowSaved(String groupTitle) {
    return (select(savedShows)..where((b) => b.groupTitle.equals(groupTitle)))
        .watchSingleOrNull()
        .map((row) => row != null);
  }

  Future<void> saveShow(String groupTitle) => into(savedShows).insert(
    SavedShowsCompanion(groupTitle: Value(groupTitle)),
    mode: InsertMode.insertOrIgnore,
  );

  Future<int> removeSavedShow(String groupTitle) =>
      (delete(savedShows)..where((b) => b.groupTitle.equals(groupTitle))).go();

  Future<bool> toggleSaveShow(String groupTitle) async {
    final exists = await isShowSaved(groupTitle);
    if (exists) {
      await removeSavedShow(groupTitle);
      return false;
    } else {
      await saveShow(groupTitle);
      return true;
    }
  }

  Stream<List<Map<String, dynamic>>> watchSavedShows() {
    return customSelect(
      '''
      SELECT
        b.group_title,
        s.resolved_title,
        s.title_en,
        s.poster_path,
        CASE
          WHEN s.mal_id IS NOT NULL OR s.anilist_id IS NOT NULL OR s.anidb_id IS NOT NULL THEN 'anime'
          WHEN s.media_type IS NOT NULL THEN s.media_type
          WHEN (SELECT COUNT(m.id) FROM media_items m WHERE m.group_title = b.group_title AND (m.season IS NOT NULL OR m.episode IS NOT NULL)) > 0 THEN 'tv'
          ELSE 'movie'
        END as media_type,
        s.year,
        (SELECT COUNT(m.id) FROM media_items m WHERE m.group_title = b.group_title) as item_count,
        (SELECT f.folder_url FROM indexed_folders f WHERE f.clean_title = b.group_title LIMIT 1) as folder_url,
        1 as is_scraped,
        1 as auto_scrape
      FROM saved_shows b
      LEFT JOIN media_shows s ON b.group_title = s.group_title
      ORDER BY b.saved_at DESC
      ''',
      readsFrom: {savedShows, mediaShows, mediaItems, indexedFolders},
    ).watch().map((rows) => rows.map((row) => row.data).toList());
  }

  // watch history / playback progress

  Future<void> savePlaybackProgress({
    required String groupTitle,
    int? mediaItemId,
    int? season,
    int? episode,
    String? episodeTitle,
    required String streamUrl,
    required int positionMs,
    required int durationMs,
    bool? isCompleted,
  }) async {
    final completed =
        isCompleted ??
        (durationMs > 0 && positionMs >= (durationMs * 0.9).toInt());

    final query = select(watchHistory)
      ..where((w) {
        if (season != null && episode != null) {
          return w.groupTitle.equals(groupTitle) &
              w.season.equals(season) &
              w.episode.equals(episode);
        } else {
          return w.groupTitle.equals(groupTitle) &
              w.streamUrl.equals(streamUrl);
        }
      });

    final existing = await query.getSingleOrNull();
    if (existing != null) {
      await (update(
        watchHistory,
      )..where((w) => w.id.equals(existing.id))).write(
        WatchHistoryCompanion(
          mediaItemId: Value(mediaItemId ?? existing.mediaItemId),
          episodeTitle: Value(episodeTitle ?? existing.episodeTitle),
          streamUrl: Value(streamUrl),
          positionMs: Value(positionMs),
          durationMs: Value(durationMs),
          isCompleted: Value(completed || existing.isCompleted),
          lastWatchedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(watchHistory).insert(
        WatchHistoryCompanion.insert(
          groupTitle: groupTitle,
          mediaItemId: Value(mediaItemId),
          season: Value(season),
          episode: Value(episode),
          episodeTitle: Value(episodeTitle),
          streamUrl: streamUrl,
          positionMs: Value(positionMs),
          durationMs: Value(durationMs),
          isCompleted: Value(completed),
          lastWatchedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> markEpisodeWatched({
    required String groupTitle,
    int? season,
    int? episode,
    String? streamUrl,
    required bool isWatched,
  }) async {
    final query = select(watchHistory)
      ..where((w) {
        if (season != null && episode != null) {
          return w.groupTitle.equals(groupTitle) &
              w.season.equals(season) &
              w.episode.equals(episode);
        } else if (streamUrl != null) {
          return w.groupTitle.equals(groupTitle) &
              w.streamUrl.equals(streamUrl);
        } else {
          return w.groupTitle.equals(groupTitle);
        }
      });

    final existing = await query.getSingleOrNull();
    if (existing != null) {
      await (update(
        watchHistory,
      )..where((w) => w.id.equals(existing.id))).write(
        WatchHistoryCompanion(
          isCompleted: Value(isWatched),
          positionMs: Value(isWatched ? existing.durationMs : 0),
          lastWatchedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(watchHistory).insert(
        WatchHistoryCompanion.insert(
          groupTitle: groupTitle,
          season: Value(season),
          episode: Value(episode),
          streamUrl: streamUrl ?? '',
          positionMs: const Value(0),
          durationMs: const Value(0),
          isCompleted: Value(isWatched),
          lastWatchedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> markEpisodesUpToWatched({
    required String groupTitle,
    required int? season,
    required int episodeNumber,
    required bool isWatched,
  }) async {
    final items =
        await (select(mediaItems)..where(
              (m) =>
                  m.groupTitle.equals(groupTitle) &
                  (season != null
                      ? m.season.equals(season)
                      : m.season.isNull()) &
                  m.episode.isNotNull() &
                  m.episode.isSmallerOrEqualValue(episodeNumber),
            ))
            .get();

    final distinctEpisodes = <int?>{};
    for (final item in items) {
      if (distinctEpisodes.add(item.episode)) {
        await markEpisodeWatched(
          groupTitle: groupTitle,
          season: season,
          episode: item.episode,
          streamUrl: item.directUrl,
          isWatched: isWatched,
        );
      }
    }
  }

  Future<WatchHistoryData?> getPlaybackProgress(
    String groupTitle, {
    int? season,
    int? episode,
    String? streamUrl,
  }) async {
    final query = select(watchHistory)
      ..where((w) {
        if (episode != null) {
          if (season != null) {
            return w.groupTitle.equals(groupTitle) &
                w.season.equals(season) &
                w.episode.equals(episode);
          } else {
            return w.groupTitle.equals(groupTitle) &
                w.episode.equals(episode);
          }
        } else if (streamUrl != null) {
          return w.groupTitle.equals(groupTitle) &
              (w.streamUrl.equals(streamUrl) | w.season.isNull() & w.episode.isNull());
        } else {
          return w.groupTitle.equals(groupTitle);
        }
      })
      ..orderBy([(w) => OrderingTerm.desc(w.lastWatchedAt)])
      ..limit(1);

    final results = await query.get();
    return results.firstOrNull;
  }

  Stream<List<WatchHistoryData>> watchPlaybackProgressForShow(
    String groupTitle,
  ) {
    return (select(
      watchHistory,
    )..where((w) => w.groupTitle.equals(groupTitle))).watch();
  }

  Stream<List<Map<String, dynamic>>> watchContinueWatching() {
    return customSelect(
      '''
      SELECT
        w.id as watch_id,
        w.group_title,
        w.season,
        w.episode,
        w.episode_title,
        w.stream_url,
        w.position_ms,
        w.duration_ms,
        w.is_completed,
        w.last_watched_at,
        s.resolved_title,
        s.title_en,
        s.poster_path,
        s.fanart_path,
        s.media_type,
        s.year,
        (SELECT COUNT(m.id) FROM media_items m WHERE m.group_title = w.group_title) as item_count
      FROM watch_history w
      LEFT JOIN media_shows s ON w.group_title = s.group_title
      WHERE (SELECT COUNT(m.id) FROM media_items m WHERE m.group_title = w.group_title) > 0
      GROUP BY w.group_title
      HAVING w.last_watched_at = MAX(w.last_watched_at)
      ORDER BY w.last_watched_at DESC
      LIMIT 20
      ''',
      readsFrom: {watchHistory, mediaShows, mediaItems},
    ).watch().map((rows) => rows.map((row) => row.data).toList());
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
