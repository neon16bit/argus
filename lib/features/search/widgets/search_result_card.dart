import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/features/detail/show_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchResultCard extends ConsumerStatefulWidget {
  final SearchResult result;

  const SearchResultCard({super.key, required this.result});

  @override
  ConsumerState<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends ConsumerState<SearchResultCard> {
  @override
  void initState() {
    super.initState();
    _enqueueScrapeIfNeeded();
  }

  @override
  void didUpdateWidget(SearchResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result.folderUrl != oldWidget.result.folderUrl ||
        widget.result.isScraped != oldWidget.result.isScraped) {
      _enqueueScrapeIfNeeded();
    }
  }

  void _enqueueScrapeIfNeeded() {
    if (!widget.result.isScraped &&
        widget.result.folderUrl != null &&
        widget.result.autoScrape) {
      Future.microtask(() {
        if (mounted) {
          ref
              .read(scrapeQueueProvider.notifier)
              .enqueue(widget.result.folderUrl!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // only watch metadata for fully scraped results (need filenames for accuracy)
    final metadataAsync = widget.result.isScraped
        ? ref.watch(metadataProvider(widget.result.groupTitle))
        : const AsyncData(null);
    final metadata = metadataAsync.value;

    // use cached db result if available, otherwise fallback to live metadata
    final posterUrl = widget.result.posterUrl ?? metadata?.posterUrl;
    final displayTitle = widget.result.displayTitle != widget.result.groupTitle
        ? widget.result.displayTitle
        : metadata?.titleEn ?? metadata?.title ?? widget.result.displayTitle;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShowDetailScreen(result: widget.result),
          ),
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
                            widget.result.isScraped
                                ? Icons.storage_rounded
                                : widget.result.autoScrape
                                ? Icons.cloud_sync_rounded
                                : Icons.cloud_off_rounded,
                            size: 14,
                            color: widget.result.isScraped
                                ? Theme.of(context).colorScheme.primary
                                : widget.result.autoScrape
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.result.isScraped
                                  ? '${widget.result.itemCount} items'
                                  : widget.result.autoScrape
                                  ? 'Indexing...'
                                  : 'Not indexed',
                              style: Theme.of(context).textTheme.bodySmall,
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

              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
