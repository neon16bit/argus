import 'package:argus/data/database/tables/sources.dart';
import 'package:drift/drift.dart';

class IndexedFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get folderName => text()(); // raw decoded folder name
  TextColumn get cleanTitle => text()(); // cleaned title for display/search
  TextColumn get folderUrl =>
      text().unique()(); // full URL to this shows folder
  IntColumn get year => integer().nullable()();
  BoolColumn get isScraped => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastScraped => dateTime().nullable()();
  DateTimeColumn get indexedAt => dateTime().withDefault(currentDateAndTime)();
}
