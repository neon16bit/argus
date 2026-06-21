import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/features/detail/show_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchResultCard extends ConsumerWidget {
  final SearchResult result;

  const SearchResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // enqueue background deep scrape when this card becomes visible (on build)
    if (!result.isScraped && result.folderUrl != null) {
      Future.microtask(
        () => ref.read(scrapeQueueProvider.notifier).enqueue(result.folderUrl!),
      );
    }

    // only watch metadata for fully scraped results (need filenames for accuracy)
    final metadataAsync = result.isScraped
        ? ref.watch(metadataProvider(result.groupTitle))
        : const AsyncData(null);
    final metadata = metadataAsync.value;

    // use cached db result if available, otherwise fallback to live metadata
    final posterUrl = result.posterUrl ?? metadata?.posterUrl;
    final displayTitle =
        result.resolvedTitle ?? metadata?.title ?? result.displayTitle;

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
              SizedBox(
                width: 60,
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[800]),
                        errorWidget: (context, url, error) =>
                            _defaultPoster(context),
                      )
                    : _defaultPoster(context),
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
                        displayTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            result.isScraped
                                ? Icons.storage_rounded
                                : Icons.cloud_sync_rounded,
                            size: 14,
                            color: result.isScraped
                                ? Theme.of(context).colorScheme.primary
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              result.isScraped
                                  ? '${result.itemCount} items'
                                  : 'Indexing...',
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
