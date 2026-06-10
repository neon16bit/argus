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
  final _debounce = ValueNotifier<String>('');

  @override
  void dispose() {
    _controller.dispose();
    _debounce.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(searchQueryProvider.notifier).set(query);
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
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
      body: resultsAsync.when(
        data: (results) {
          if (ref.read(searchQueryProvider).isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'Search your indexed sources',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          if (results.isEmpty) {
            return const Center(child: Text('No results found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return _SearchResultCard(result: result);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SearchResultCard extends ConsumerWidget {
  final SearchResult result;

  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localCount = result.items.length;
    // trigger Simkl metadata fetch for this search result
    final metadataAsync = ref.watch(metadataProvider(result.cleanTitle));

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
              // Poster thumbnail
              SizedBox(
                width: 60,
                child: metadataAsync.when(
                  data: (meta) {
                    if (meta?.posterUrl != null) {
                      return Image.network(
                        meta!.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _defaultPoster(context),
                      );
                    }
                    return _defaultPoster(context);
                  },
                  loading: () => Container(color: Colors.grey[800]),
                  error: (_, _) => _defaultPoster(context),
                ),
              ),

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
