import 'package:drift/drift.dart';
import 'media_items.dart';

@TableIndex(
  name: 'idx_watch_history_lookup',
  columns: {#groupTitle, #season, #episode},
)
@TableIndex(name: 'idx_watch_history_last_watched', columns: {#lastWatchedAt})
class WatchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get groupTitle => text()();
  IntColumn get mediaItemId =>
      integer().nullable().references(MediaItems, #id)();
  IntColumn get season => integer().nullable()();
  IntColumn get episode => integer().nullable()();
  TextColumn get episodeTitle => text().nullable()();
  TextColumn get streamUrl => text()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastWatchedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
