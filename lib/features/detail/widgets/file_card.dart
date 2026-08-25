import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/core/utils/audio_tag_helper.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/features/player/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class FileCard extends ConsumerWidget {
  final List<dynamic> group;

  const FileCard({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (group.isEmpty) return const SizedBox.shrink();

    final item = group.first;
    final isMulti = group.length > 1;

    final titleStr = item.episode != null
        ? 'Episode ${item.episode}'
        : item.rawName;
    final subtitleStr = isMulti
        ? 'Multiple versions available (${group.length})'
        : item.rawName;

    final isSingleDub =
        !isMulti &&
        (AudioTagHelper.isDub(item.directUrl) ||
            AudioTagHelper.isDub(item.rawName));

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            leading: Icon(
              isWatched
                  ? Icons.check_circle_rounded
                  : (isMulti
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
                if (isSingleDub) ...[
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
            onTap: () => _showPlayOptionsBottomSheet(
              context,
              ref,
              titleStr,
              group,
              isWatched,
              historyList,
            ),
            onLongPress: () => _showPlayOptionsBottomSheet(
              context,
              ref,
              titleStr,
              group,
              isWatched,
              historyList,
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
                    final isItemDub =
                        AudioTagHelper.isDub(item.directUrl) ||
                        AudioTagHelper.isDub(item.rawName);
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
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded),
                            tooltip: 'Open in External Player',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openInExternalPlayer(context, ref, item);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _playInApp(context, item);
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

  void _playInApp(BuildContext context, dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          url: item.directUrl,
          title: item.cleanTitle,
          groupTitle: item.groupTitle,
          season: item.season,
          episode: item.episode,
          mediaItemId: item.id,
        ),
      ),
    );
  }

  Future<void> _openInExternalPlayer(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
  ) async {
    final streamUrl = item.directUrl;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // update last watched timestamp
    ref
        .read(databaseProvider)
        .savePlaybackProgress(
          groupTitle: item.groupTitle,
          mediaItemId: item.id,
          season: item.season,
          episode: item.episode,
          episodeTitle: item.cleanTitle,
          streamUrl: streamUrl,
          positionMs: 0,
          durationMs: 0,
        );

    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'action_view',
          data: streamUrl,
          type: 'video/*',
        );
        await intent.launch();
      } else {
        final uri = Uri.parse(streamUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch URL';
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to open external player. Play in app or copy the link instead.',
          ),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: streamUrl));
            },
          ),
        ),
      );
    }
  }
}
