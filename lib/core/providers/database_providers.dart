import 'package:argus/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final packageInfoProvider = Provider<PackageInfo>((ref) {
  throw UnimplementedError('Initialized in main()');
});
