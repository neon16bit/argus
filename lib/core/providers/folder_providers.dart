import 'dart:async';
import 'package:argus/core/constants.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/core/providers/settings_provider.dart';
import 'package:argus/core/providers/source_providers.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// manages a priority queue of folder scrape tasks
class ScrapeQueueNotifier extends Notifier<void> {
  final _queue = <String>{}; // ordered set (insertion order, url is key)
  final _inProgress = <String>{};
  int _active = 0;

  @override
  void build() {}

  void enqueue(String folderUrl) {
    if (_queue.contains(folderUrl) || _inProgress.contains(folderUrl)) return;
    _queue.add(folderUrl);
    _pump();
  }

  void prioritize(String folderUrl) {
    if (_inProgress.contains(folderUrl)) return;
    _queue.remove(folderUrl);
    // re-insert at front by rebuilding with it first
    final rest = List<String>.from(_queue);
    _queue.clear();
    _queue.add(folderUrl);
    _queue.addAll(rest);
    _pump();
  }

  void _pump() {
    while (_active < kMaxConcurrentRequests && _queue.isNotEmpty) {
      final url = _queue.first;
      _queue.remove(url);
      _inProgress.add(url);
      _active++;
      _scrape(url).whenComplete(() {
        _inProgress.remove(url);
        _active--;
        _pump();
      });
    }
  }

  Future<void> _scrape(String folderUrl) async {
    final db = ref.read(databaseProvider);
    final folder = await db.getFolderByUrl(folderUrl);
    if (folder == null || folder.isScraped) return;

    final settings = ref.read(settingsProvider);
    final delay = settings.scrapeDelay;

    final actions = ref.read(sourceActionsProvider);
    await actions.deepScrapeFolder(folder, requestDelay: delay);
  }
}

final scrapeQueueProvider = NotifierProvider<ScrapeQueueNotifier, void>(
  ScrapeQueueNotifier.new,
);

final showFoldersProvider = StreamProvider.family<List<IndexedFolder>, String>((
  ref,
  groupTitle,
) {
  final db = ref.watch(databaseProvider);
  return db.watchFoldersByGroupTitle(groupTitle);
});
