import 'package:drift/drift.dart';

class Sources extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get baseUrl => text().unique()();
  BoolColumn get isOnline => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastScraped => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get maxDepth => integer().withDefault(const Constant(1))();
  BoolColumn get autoScrape => boolean().withDefault(const Constant(false))();
  IntColumn get requestDelayMs =>
      integer().nullable()(); // source delay override (ms)
}
