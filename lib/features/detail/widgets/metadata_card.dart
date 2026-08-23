import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:argus/data/remote/metadata/metadata_provider.dart';

class DetailHeader extends StatelessWidget {
  final ShowMetadata? metadata;

  const DetailHeader({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    if (metadata?.backdropUrl != null) {
      return CachedNetworkImage(
        imageUrl: metadata!.backdropUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => _buildDefaultHeader(context),
      );
    } else if (metadata?.posterUrl != null) {
      return CachedNetworkImage(
        imageUrl: metadata!.posterUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorWidget: (_, _, _) => _buildDefaultHeader(context),
      );
    }
    return _buildDefaultHeader(context);
  }

  Widget _buildDefaultHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class MetadataCard extends StatelessWidget {
  final ShowMetadata? metadata;

  const MetadataCard({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata?.posterUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: metadata!.posterUrl!,
                width: 100,
                height: 150,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox(
                  width: 100,
                  height: 150,
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            )
          else
            Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.movie_rounded)),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metadata?.year != null) ...[
                  Text(
                    metadata!.year.toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                ],
                if (metadata?.ratingImdb != null ||
                    metadata?.ratingMal != null ||
                    metadata?.ratingSimkl != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (metadata?.ratingImdb != null)
                        _buildRatingBadge(
                          context,
                          'IMDb',
                          metadata!.ratingImdb!,
                        ),
                      if (metadata?.ratingMal != null)
                        _buildRatingBadge(context, 'MAL', metadata!.ratingMal!),
                      if (metadata?.ratingSimkl != null)
                        _buildRatingBadge(
                          context,
                          'Simkl',
                          metadata!.ratingSimkl!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (metadata?.overview != null)
                  _ExpandableOverview(text: metadata!.overview!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(
    BuildContext context,
    String provider,
    double rating,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: colorScheme.primary),
          const SizedBox(width: 3),
          Text(
            provider,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableOverview extends StatefulWidget {
  final String text;

  const _ExpandableOverview({required this.text});

  @override
  State<_ExpandableOverview> createState() => _ExpandableOverviewState();
}

class _ExpandableOverviewState extends State<_ExpandableOverview> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topLeft,
        child: Text(
          widget.text,
          maxLines: _isExpanded ? null : 5,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
