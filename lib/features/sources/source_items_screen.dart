import 'dart:async';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/features/detail/show_detail_screen.dart';
import 'package:argus/features/sources/widgets/confirm_clear_source_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SourceItemsScreen extends ConsumerStatefulWidget {
  final Source source;

  const SourceItemsScreen({super.key, required this.source});

  @override
  ConsumerState<SourceItemsScreen> createState() => _SourceItemsScreenState();
}

class _SourceItemsScreenState extends ConsumerState<SourceItemsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<SearchResult> _items = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 100;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final db = ref.read(databaseProvider);
      final rawList = await db.getShowsBySource(
        widget.source.id,
        searchQuery: _searchQuery,
        limit: _limit,
        offset: _offset,
      );
      final list = rawList
          .map(
            (row) => SearchResult(
              groupTitle: row['group_title'] as String,
              folderUrl: row['folder_url'] as String?,
              isScraped: (row['is_scraped'] as int? ?? 1) == 1,
              year: row['year'] as int?,
              autoScrape: widget.source.autoScrape,
            ),
          )
          .toList();
      if (mounted) {
        setState(() {
          _items = list;
          _offset += list.length;
          _hasMore = list.length == _limit;
          _isInitialLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final db = ref.read(databaseProvider);
      final rawList = await db.getShowsBySource(
        widget.source.id,
        searchQuery: _searchQuery,
        limit: _limit,
        offset: _offset,
      );
      final list = rawList
          .map(
            (row) => SearchResult(
              groupTitle: row['group_title'] as String,
              folderUrl: row['folder_url'] as String?,
              isScraped: (row['is_scraped'] as int? ?? 1) == 1,
              year: row['year'] as int?,
              autoScrape: widget.source.autoScrape,
            ),
          )
          .toList();
      if (mounted) {
        setState(() {
          _items = [..._items, ...list];
          _offset += list.length;
          _hasMore = list.length == _limit;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final query = _searchController.text.trim();
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
          _items.clear();
          _offset = 0;
          _hasMore = true;
          _isInitialLoading = true;
        });
        _loadItems();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.source.name),
            Text(
              'Indexed Shows',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear indexed folders',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              showConfirmClearSourceDialog(
                context,
                ref,
                widget.source,
                onCleared: () {
                  if (mounted) {
                    setState(() {
                      _items.clear();
                      _offset = 0;
                      _hasMore = false;
                    });
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search indexed shows...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.folder_off_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withAlpha(127),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No matches found for "$_searchQuery"'
                              : 'No items indexed from this source yet.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withAlpha(127),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.movie_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          title: Text(
                            item.displayTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: !item.isScraped
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.cloud_sync_rounded,
                                      size: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Not indexed yet',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withAlpha(178),
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ShowDetailScreen(
                                  result: item,
                                  initialSourceId: widget.source.id,
                                ),
                              ),
                            );
                            // wait until all route transitions are completely done
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _offset = 0;
                                _hasMore = true;
                                _loadItems();
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
