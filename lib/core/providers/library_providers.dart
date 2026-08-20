import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/core/providers/search_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// stream of all saved shows for the Library tab
final savedShowsProvider = StreamProvider<List<SearchResult>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchSavedShows().map(
    (rows) => rows
        .map(
          (row) => SearchResult(
            groupTitle: row['group_title'] as String,
            resolvedTitle: row['resolved_title'] as String?,
            titleEn: row['title_en'] as String?,
            posterPath: row['poster_path'] as String?,
            mediaType: row['media_type'] as String?,
            year: row['year'] as int?,
            itemCount: row['item_count'] as int? ?? 0,
            folderUrl: row['folder_url'] as String?,
            isScraped: (row['is_scraped'] as int? ?? 1) == 1,
            autoScrape: (row['auto_scrape'] as int? ?? 1) == 1,
          ),
        )
        .toList(),
  );
});

final isShowSavedProvider = StreamProvider.family<bool, String>((
  ref,
  groupTitle,
) {
  final db = ref.watch(databaseProvider);
  return db.watchIsShowSaved(groupTitle);
});

const _kLibraryViewGrid = 'library_view_grid';

class LibraryViewGridNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_kLibraryViewGrid) ?? true;
  }

  Future<void> toggle() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = !state;
    await prefs.setBool(_kLibraryViewGrid, next);
    state = next;
  }
}

final libraryViewGridProvider = NotifierProvider<LibraryViewGridNotifier, bool>(
  LibraryViewGridNotifier.new,
);
