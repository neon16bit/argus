import 'package:drift/drift.dart';

// Metadata cache table, one row per unique show across all sources
// populated on first simkl lookup, reused for all sources that
// share the same groupTitle.
class MediaShows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get groupTitle => text().unique()();
  TextColumn get resolvedTitle => text().nullable()();
  TextColumn get mediaType => text().nullable()(); // 'tv', 'anime', 'movie'
  TextColumn get animeType =>
      text().nullable()(); // 'tv', 'movie', 'ova', 'ona', 'special'
  IntColumn get year => integer().nullable()();
  IntColumn get totalEpisodes => integer().nullable()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get fanartPath => text().nullable()();
  TextColumn get overview => text().nullable()();

  // external IDs from Simkl /search/file response
  IntColumn get simklId => integer().nullable()();
  TextColumn get simklSlug => text().nullable()();
  TextColumn get imdbId => text().nullable()();
  TextColumn get tmdbId => text().nullable()();
  IntColumn get malId => integer().nullable()();
  IntColumn get anilistId => integer().nullable()();
  IntColumn get tvdbId => integer().nullable()();
  TextColumn get anidbId => text().nullable()();

  DateTimeColumn get resolvedAt => dateTime().nullable()();
}
