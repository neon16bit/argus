import 'package:argus/core/providers/providers.dart';
import 'package:argus/features/detail/show_detail_screen.dart';
import 'package:argus/features/search/widgets/search_result_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedShowsAsync = ref.watch(savedShowsProvider);
    final isGrid = ref.watch(libraryViewGridProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: Icon(
              isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            tooltip: isGrid ? 'Switch to list view' : 'Switch to grid view',
            onPressed: () {
              ref.read(libraryViewGridProvider.notifier).toggle();
            },
          ),
        ],
      ),
      body: savedShowsAsync.when(
        data: (shows) {
          if (shows.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Library is empty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shows you add to your library will appear here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (isGrid) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: shows.length,
              itemBuilder: (context, index) =>
                  _LibraryGridCard(result: shows[index]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shows.length,
            itemBuilder: (context, index) =>
                SearchResultCard(result: shows[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LibraryGridCard extends ConsumerWidget {
  final SearchResult result;

  const _LibraryGridCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataAsync = result.isScraped
        ? ref.watch(metadataProvider(result.groupTitle))
        : const AsyncData(null);
    final metadata = metadataAsync.value;

    final posterUrl = result.posterUrl ?? metadata?.posterUrl;
    final displayTitle = result.displayTitle != result.groupTitle
        ? result.displayTitle
        : metadata?.titleEn ?? metadata?.title ?? result.displayTitle;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShowDetailScreen(result: result)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster
            Expanded(
              child: posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (context, url, error) =>
                          _defaultPoster(context),
                    )
                  : _defaultPoster(context),
            ),
            // Title & Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.isScraped
                        ? '${result.itemCount} items'
                        : 'Indexing...',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultPoster(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          size: 36,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
