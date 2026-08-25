import 'package:argus/core/providers/providers.dart';
import 'package:argus/core/utils/audio_tag_helper.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/features/detail/show_detail_screen.dart';
import 'package:argus/features/player/video_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContinueWatchingCard extends ConsumerWidget {
  final ContinueWatchingItem item;

  const ContinueWatchingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posterUrl = item.posterUrl;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowDetailScreen(
                result: SearchResult(
                  groupTitle: item.groupTitle,
                  resolvedTitle: item.resolvedTitle,
                  titleEn: item.titleEn,
                  posterPath: item.posterPath,
                  mediaType: item.mediaType,
                  year: item.year,
                  itemCount: item.itemCount,
                ),
              ),
            ),
          );
        },
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster & Play Overlay
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (posterUrl != null)
                      CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(
                            Icons.movie_outlined,
                            size: 40,
                            color: Colors.white54,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(
                          Icons.movie_outlined,
                          size: 40,
                          color: Colors.white54,
                        ),
                      ),

                    // Dark gradient at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 50,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ),

                    // Center Resume Play Button
                    Center(
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          tooltip: 'Resume Playback',
                          onPressed: () => _handlePlay(context, ref),
                        ),
                      ),
                    ),

                    if (item.progressFraction > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: item.progressFraction,
                          minHeight: 4,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.episodeLabel.isNotEmpty
                          ? item.episodeLabel
                          : (item.isCompleted ? 'Completed' : 'Resume'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlay(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);

    int? targetSeason = item.season;
    int? targetEpisode = item.episode;
    String? targetTitle = item.episodeTitle;

    // if current episode was completed (>= 90%) advance to the next episode
    if (item.isCompleted && targetEpisode != null) {
      final allItems = await db.getMediaItemsByGroupTitle(item.groupTitle);

      // try next episode in same season
      final nextInSeason = allItems
          .where(
            (m) =>
                (m.season == targetSeason ||
                    (targetSeason == null && m.season == null)) &&
                m.episode == targetEpisode! + 1,
          )
          .toList();

      if (nextInSeason.isNotEmpty) {
        targetEpisode = targetEpisode + 1;
        targetTitle = nextInSeason.first.cleanTitle;
      } else {
        // try first episode of next season
        final nextSeasonFirstEp = allItems
            .where(
              (m) =>
                  m.season == (targetSeason ?? 1) + 1 &&
                  (m.episode == 1 || m.episode == 0),
            )
            .toList();
        if (nextSeasonFirstEp.isNotEmpty) {
          targetSeason = (targetSeason ?? 1) + 1;
          targetEpisode = nextSeasonFirstEp.first.episode;
          targetTitle = nextSeasonFirstEp.first.cleanTitle;
        }
      }
    }

    final items = await db.getMediaItemsForEpisode(
      groupTitle: item.groupTitle,
      season: targetSeason,
      episode: targetEpisode,
    );

    if (!context.mounted) return;

    if (items.length > 1) {
      final prefVersionMap = ref.read(versionPreferenceProvider);
      final preferredFolderUrl = prefVersionMap[item.groupTitle];

      if (preferredFolderUrl != null && preferredFolderUrl.isNotEmpty) {
        bool matchesPreferred(MediaItem it) {
          final itemUrl = it.directUrl.toLowerCase();
          final prefUrl = preferredFolderUrl.toLowerCase();
          final prefDecoded = Uri.decodeFull(preferredFolderUrl).toLowerCase();
          final itemDecoded = Uri.decodeFull(it.directUrl).toLowerCase();
          return itemUrl.startsWith(prefUrl) ||
              itemDecoded.startsWith(prefDecoded) ||
              itemUrl.contains(prefUrl) ||
              itemDecoded.contains(prefDecoded);
        }

        final matchingItem = items.cast<MediaItem?>().firstWhere(
          (it) => it != null && matchesPreferred(it),
          orElse: () => null,
        );

        if (matchingItem != null) {
          _playDirect(
            context,
            matchingItem.directUrl,
            matchingItem.id,
            season: targetSeason,
            episode: targetEpisode,
            title: targetTitle ?? item.displayTitle,
          );
          return;
        }
      }

      _showSourceSelectionBottomSheet(
        context,
        ref,
        items,
        season: targetSeason,
        episode: targetEpisode,
        title: targetTitle ?? item.displayTitle,
      );
    } else if (items.length == 1) {
      _playDirect(
        context,
        items.first.directUrl,
        items.first.id,
        season: targetSeason,
        episode: targetEpisode,
        title: targetTitle ?? item.displayTitle,
      );
    } else {
      _playDirect(
        context,
        item.streamUrl,
        null,
        season: targetSeason,
        episode: targetEpisode,
        title: targetTitle ?? item.displayTitle,
      );
    }
  }

  void _playDirect(
    BuildContext context,
    String url,
    int? mediaItemId, {
    int? season,
    int? episode,
    String? title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          url: url,
          title: title ?? item.episodeTitle ?? item.displayTitle,
          groupTitle: item.groupTitle,
          season: season ?? item.season,
          episode: episode ?? item.episode,
          mediaItemId: mediaItemId,
        ),
      ),
    );
  }

  void _showSourceSelectionBottomSheet(
    BuildContext context,
    WidgetRef ref,
    List<MediaItem> items, {
    int? season,
    int? episode,
    String? title,
  }) {
    final dubOverrides = ref.read(dubOverrideProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Source: ${title ?? (item.episodeLabel.isNotEmpty ? item.episodeLabel : item.displayTitle)}',
              style: Theme.of(ctx).textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.map((mediaItem) {
                    bool? itemOverride;
                    for (final entry in dubOverrides.entries) {
                      if (entry.value != null &&
                          mediaItem.directUrl.toLowerCase().contains(
                            entry.key.toLowerCase(),
                          )) {
                        itemOverride = entry.value;
                        break;
                      }
                    }

                    final isItemDub =
                        AudioTagHelper.isDub(
                          mediaItem.directUrl,
                          override: itemOverride,
                        ) ||
                        (itemOverride == null &&
                            AudioTagHelper.isDub(mediaItem.rawName));

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_arrow_rounded),
                      title: Text(
                        mediaItem.rawName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Flexible(
                            child: Text(
                              Uri.tryParse(mediaItem.directUrl)?.host ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isItemDub) ...[
                            const SizedBox(width: 8),
                            const DubBadge(),
                          ],
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _playDirect(
                          context,
                          mediaItem.directUrl,
                          mediaItem.id,
                          season: season,
                          episode: episode,
                          title: title,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
