import 'dart:async';

import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/data/remote/metadata/simkl_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// models
class SearchResult {
  final String groupTitle; // raw folder based title
  final String? resolvedTitle; // simkl cached title
  final String? titleEn; // simkl English title
  final String? posterPath; // raw simkl poster path
  final String? mediaType; // tv, anime, movie
  final int? year;
  final int itemCount;

  const SearchResult({
    required this.groupTitle,
    this.resolvedTitle,
    this.titleEn,
    this.posterPath,
    this.mediaType,
    this.year,
    this.itemCount = 0,
  });

  // title to show in the ui (titleEn > resolvedTitle > groupTitle)
  String get displayTitle => titleEn ?? resolvedTitle ?? groupTitle;

  // build poster URL from cached path
  String? get posterUrl => SimklProvider.posterUrl(posterPath);
}

class SearchQueryNotifier extends Notifier<String> {
  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    return '';
  }

  void set(String query) {
    _timer?.cancel();
    if (query.trim().isEmpty) {
      state = '';
      return;
    }
    _timer = Timer(const Duration(milliseconds: 300), () {
      state = query;
    });
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final searchResultsProvider = StreamProvider<List<SearchResult>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return Stream.value([]);

  final db = ref.watch(databaseProvider);
  return db
      .watchSearchShows(query)
      .map(
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
              ),
            )
            .toList(),
      );
});
