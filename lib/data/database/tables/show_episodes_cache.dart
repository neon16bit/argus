import 'package:drift/drift.dart';

// episode names cache (one row per unique show)
class ShowEpisodesCache extends Table {
  TextColumn get groupTitle => text()();
  TextColumn get episodesJson => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {groupTitle};
}
