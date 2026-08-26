import 'package:argus/core/providers/providers.dart';
import 'package:argus/core/utils/audio_tag_helper.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:argus/core/utils/player_launcher.dart';

class FileCard extends ConsumerWidget {
  final List<dynamic> group;
  final String? preferredFolderUrl;

  const FileCard({super.key, required this.group, this.preferredFolderUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (group.isEmpty) return const SizedBox.shrink();

    final item = group.first;
    final isMulti = group.length > 1;
    final hasPreference = preferredFolderUrl != null;

    final titleStr = item.episode != null
        ? 'Episode ${item.episode}'
        : item.rawName;
    final subtitleStr = isMulti && !hasPreference
        ? 'Multiple versions available (${group.length})'
        : item.rawName;

    final dubOverrides = ref.watch(dubOverrideProvider);
    bool checkItemDub(dynamic it) {
      bool? itemOverride;
      for (final entry in dubOverrides.entries) {
        if (entry.value != null &&
            it.directUrl.toLowerCase().contains(entry.key.toLowerCase())) {
          itemOverride = entry.value;
          break;
        }
      }
      return AudioTagHelper.isDub(it.directUrl, override: itemOverride) ||
          (itemOverride == null && AudioTagHelper.isDub(it.rawName));
    }

    final isItemDub = checkItemDub(item);
    final showDubBadge = !isMulti || hasPreference ? isItemDub : false;

    final historyList =
        ref.watch(showWatchHistoryProvider(item.groupTitle)).value ?? [];
    WatchHistoryData? history;
    for (final w in historyList) {
      if (item.season != null && item.episode != null) {
        if (w.season == item.season && w.episode == item.episode) {
          history = w;
          break;
        }
      } else if (group.any((g) => g.directUrl == w.streamUrl)) {
        history = w;
        break;
      }
    }

    final isWatched = history?.isCompleted ?? false;
    final hasProgress =
        history != null &&
        !isWatched &&
        history.durationMs > 0 &&
        history.positionMs > 0;
    final progressPercent = hasProgress
        ? (history.positionMs / history.durationMs).clamp(0.0, 1.0)
        : 0.0;

    void openSheet() {
      _showPlayOptionsBottomSheet(
        context,
        ref,
        titleStr,
        group,
        isWatched,
        historyList,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onSecondaryTap: openSheet,
            child: ListTile(
              dense: true,
              leading: Icon(
                isWatched
                    ? Icons.check_circle_rounded
                    : (isMulti && !hasPreference
                          ? Icons.video_library_rounded
                          : Icons.play_circle_rounded),
                color: isWatched
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                titleStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isWatched ? FontWeight.normal : FontWeight.w600,
                  color: isWatched
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7)
                      : null,
                ),
              ),
              subtitle: Row(
                children: [
                  if (showDubBadge) ...[
                    const DubBadge(),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      subtitleStr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  isWatched
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isWatched
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                tooltip: isWatched ? 'Mark as unwatched' : 'Mark as watched',
                onPressed: () => _handleCheckmarkTap(
                  context,
                  ref,
                  item,
                  isWatched,
                  historyList,
                ),
              ),
              onTap: () {
                if (!isMulti || hasPreference) {
                  PlayerLauncher.playMedia(
                    context,
                    ref,
                    url: item.directUrl,
                    title: item.cleanTitle,
                    groupTitle: item.groupTitle,
                    season: item.season,
                    episode: item.episode,
                    mediaItemId: item.id,
                  );
                } else {
                  openSheet();
                }
              },
              onLongPress: openSheet,
            ),
          ),
          if (hasProgress)
            LinearProgressIndicator(
              value: progressPercent,
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleCheckmarkTap(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    bool isWatched,
    List<WatchHistoryData> historyList,
  ) async {
    if (isWatched) {
      ref
          .read(databaseProvider)
          .markEpisodeWatched(
            groupTitle: item.groupTitle,
            season: item.season,
            episode: item.episode,
            streamUrl: item.directUrl,
            isWatched: false,
          );
      return;
    }

    final epNum = item.episode;
    bool hasUnwatchedPrevious = false;
    if (epNum != null && epNum > 1) {
      for (int i = 1; i < epNum; i++) {
        final isPrevCompleted = historyList.any(
          (w) => w.season == item.season && w.episode == i && w.isCompleted,
        );
        if (!isPrevCompleted) {
          hasUnwatchedPrevious = true;
          break;
        }
      }
    }

    if (!hasUnwatchedPrevious || epNum == null || epNum <= 1) {
      ref
          .read(databaseProvider)
          .markEpisodeWatched(
            groupTitle: item.groupTitle,
            season: item.season,
            episode: item.episode,
            streamUrl: item.directUrl,
            isWatched: true,
          );
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark previous episodes?'),
        content: const Text(
          'Previous episodes are currently unwatched. Would you like to mark all previous episodes as watched as well?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'single'),
            child: Text('Only Episode $epNum'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'all'),
            child: const Text('Mark all previous episodes'),
          ),
        ],
      ),
    );

    if (result == 'all') {
      await ref
          .read(databaseProvider)
          .markEpisodesUpToWatched(
            groupTitle: item.groupTitle,
            season: item.season,
            episodeNumber: epNum,
            isWatched: true,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked previous episodes as watched'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (result == 'single') {
      await ref
          .read(databaseProvider)
          .markEpisodeWatched(
            groupTitle: item.groupTitle,
            season: item.season,
            episode: item.episode,
            streamUrl: item.directUrl,
            isWatched: true,
          );
    }
  }

  void _showPlayOptionsBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<dynamic> items,
    bool isWatched,
    List<WatchHistoryData> historyList,
  ) {
    final firstItem = items.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Play: $title',
                    style: Theme.of(ctx).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(
                    isWatched
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(isWatched ? 'Watched' : 'Mark Watched'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleCheckmarkTap(
                      context,
                      ref,
                      firstItem,
                      isWatched,
                      historyList,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.map<Widget>((item) {
                    final dubOverrides = ref.watch(dubOverrideProvider);
                    bool? itemOverride;
                    for (final entry in dubOverrides.entries) {
                      if (entry.value != null &&
                          (item.directUrl as String).toLowerCase().contains(
                            entry.key.toLowerCase(),
                          )) {
                        itemOverride = entry.value;
                        break;
                      }
                    }
                    final isItemDub =
                        AudioTagHelper.isDub(
                          item.directUrl,
                          override: itemOverride,
                        ) ||
                        (itemOverride == null &&
                            AudioTagHelper.isDub(item.rawName));
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_arrow_rounded),
                      title: Text(
                        item.rawName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Flexible(
                            child: Text(
                              Uri.parse(item.directUrl).host,
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: 'Copy URL',
                            onPressed: () {
                              Navigator.pop(ctx);
                              Clipboard.setData(
                                ClipboardData(text: item.directUrl),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('URL copied to clipboard'),
                                ),
                              );
                            },
                          ),
                          (() {
                            final useExternal = ref
                                .watch(settingsProvider)
                                .useExternalPlayer;
                            return IconButton(
                              icon: Icon(
                                useExternal
                                    ? Icons.smart_display_outlined
                                    : Icons.open_in_new_rounded,
                              ),
                              tooltip: useExternal
                                  ? 'Play in App'
                                  : 'Open in External Player',
                              onPressed: () {
                                Navigator.pop(ctx);
                                if (useExternal) {
                                  PlayerLauncher.playInApp(
                                    context,
                                    url: item.directUrl,
                                    title: item.cleanTitle,
                                    groupTitle: item.groupTitle,
                                    season: item.season,
                                    episode: item.episode,
                                    mediaItemId: item.id,
                                  );
                                } else {
                                  PlayerLauncher.launchExternalPlayer(
                                    context,
                                    ref,
                                    url: item.directUrl,
                                    title: item.cleanTitle,
                                    groupTitle: item.groupTitle,
                                    season: item.season,
                                    episode: item.episode,
                                    mediaItemId: item.id,
                                  );
                                }
                              },
                            );
                          })(),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        PlayerLauncher.playMedia(
                          context,
                          ref,
                          url: item.directUrl,
                          title: item.cleanTitle,
                          groupTitle: item.groupTitle,
                          season: item.season,
                          episode: item.episode,
                          mediaItemId: item.id,
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
