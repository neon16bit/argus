import 'dart:async';

import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// models
class SearchResult {
  final String cleanTitle;
  final List<MediaItem> _items;

  SearchResult({required this.cleanTitle, List<MediaItem>? items})
    : _items = items ?? [];

  // unmodifiable view of the items list
  List<MediaItem> get items => List.unmodifiable(_items);

  int get totalSources => _items.length;

  // internal used only during grouping in the provider
  void addItem(MediaItem item) => _items.add(item);
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

final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final db = ref.watch(databaseProvider);
  final items = await db.searchMedia(query);

  final grouped = <String, SearchResult>{};
  for (final item in items) {
    final key = item.groupTitle.toLowerCase();
    final existing = grouped[key];
    if (existing != null) {
      existing.addItem(item);
    } else {
      grouped[key] = SearchResult(cleanTitle: item.groupTitle, items: [item]);
    }
  }
  return grouped.values.toList();
});
