import 'package:drift/drift.dart';

class SavedShows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get groupTitle => text().unique()();
  DateTimeColumn get savedAt => dateTime().withDefault(currentDateAndTime)();
}
