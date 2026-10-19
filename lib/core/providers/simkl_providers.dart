import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/core/providers/metadata_providers.dart';
import 'package:argus/data/remote/simkl/simkl_auth_service.dart';
import 'package:argus/data/remote/simkl/simkl_sync_service.dart';

final simklAuthProvider =
    NotifierProvider<SimklAuthNotifier, SimklAccountState>(
      SimklAuthNotifier.new,
    );

final simklSyncServiceProvider = Provider<SimklSyncService>((ref) {
  final authNotifier = ref.watch(simklAuthProvider.notifier);
  final db = ref.watch(databaseProvider);
  final packageInfo = ref.watch(packageInfoProvider);
  final simkl = ref.watch(simklProvider);

  final syncService = SimklSyncService(
    authNotifier: authNotifier,
    db: db,
    appName: packageInfo.appName,
    appVersion: packageInfo.version,
    simklProvider: simkl,
  );

  // hook database watch status events to sync
  db.onWatchStatusChanged =
      ({
        required String groupTitle,
        int? season,
        int? episode,
        String? rawName,
        required bool isWatched,
      }) {
        syncService.syncEpisodeWatched(
          groupTitle: groupTitle,
          season: season,
          episode: episode,
          rawName: rawName,
          isWatched: isWatched,
        );
      };

  return syncService;
});
