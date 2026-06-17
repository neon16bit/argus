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
        child: Icon(Icons.movie_rounded, size: 64, color: Colors.grey[700]),
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
                          Colors.amber[700]!,
                        ),
                      if (metadata?.ratingMal != null)
                        _buildRatingBadge(
                          context,
                          'MAL',
                          metadata!.ratingMal!,
                          Colors.blue[600]!,
                        ),
                      if (metadata?.ratingSimkl != null)
                        _buildRatingBadge(
                          context,
                          'Simkl',
                          metadata!.ratingSimkl!,
                          Colors.red[600]!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (metadata?.overview != null)
                  Text(
                    metadata!.overview!,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            provider,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
