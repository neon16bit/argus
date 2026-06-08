import 'package:flutter/material.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/features/detail/show_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<SearchResult> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    final resultsMap = <String, SearchResult>{};
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      final sources = ref.read(sourcesProvider);
      for (final source in sources) {
        for (final item in source.items) {
          if (item.cleanTitle.toLowerCase().contains(lowerQuery)) {
            final title = item.cleanTitle;
            if (!resultsMap.containsKey(title)) {
              resultsMap[title] = SearchResult(cleanTitle: title, items: []);
            }
            resultsMap[title]!.items.add(item);
          }
        }
      }
    }

    setState(() {
      _results = resultsMap.values.toList()
        ..sort((a, b) => a.cleanTitle.compareTo(b.cleanTitle));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for a show, movie...',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: _onSearch,
          onSubmitted: _onSearch,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                _onSearch('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              'Search your indexed sources',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _SearchResultCard(result: result);
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final SearchResult result;

  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final localCount = result.items.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShowDetailScreen(result: result)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // poster thumbnail
              SizedBox(width: 60, child: _defaultPoster(context)),

              // result details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        result.cleanTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$localCount items',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultPoster(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: const Center(child: Icon(Icons.movie_rounded, color: Colors.grey)),
    );
  }
}
