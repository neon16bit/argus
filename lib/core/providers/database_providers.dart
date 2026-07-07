import 'package:argus/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final packageInfoProvider = Provider<PackageInfo>((ref) {
  throw UnimplementedError('Initialized in main()');
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialized in main()');
});

// fetches all items for a show when detail screen opens
final showItemsProvider = StreamProvider.family<List<MediaItem>, String>((
  ref,
  groupTitle,
) {
  final db = ref.watch(databaseProvider);
  return db.watchMediaItemsByGroupTitle(groupTitle);
});

final folderByUrlProvider = StreamProvider.family<IndexedFolder?, String>((
  ref,
  url,
) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.indexedFolders,
  )..where((f) => f.folderUrl.equals(url))).watchSingleOrNull();
});
