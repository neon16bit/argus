import 'package:drift/drift.dart';
import 'package:argus/data/scrapers/scrape_result.dart';
import 'sources.dart';

class MediaItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get rawName => text()();
  TextColumn get cleanTitle => text()();
  TextColumn get directUrl => text()();
  TextColumn get type => textEnum<ScrapeItemType>()();
  IntColumn get season => integer().nullable()();
  IntColumn get episode => integer().nullable()();
  TextColumn get fileExtension => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  DateTimeColumn get indexedAt => dateTime().withDefault(currentDateAndTime)();
}
