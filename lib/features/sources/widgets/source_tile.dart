import 'dart:async';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/data/scrapers/directory_scraper.dart';
import 'package:argus/features/sources/widgets/source_form_dialog.dart';
import 'package:argus/features/sources/source_items_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SourceTile extends ConsumerStatefulWidget {
  final Source source;
  const SourceTile({super.key, required this.source});

  @override
  ConsumerState<SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends ConsumerState<SourceTile> {
  bool _isScraping = false;
  ScrapeProgress? _progress;
  StreamSubscription<ScrapeProgress>? _scrapeSubscription;

  @override
  void dispose() {
    _scrapeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    final folderCountAsync = ref.watch(
      indexedFoldersCountBySourceProvider(source.id),
    );
    final mediaItemsCountAsync = ref.watch(
      mediaItemsCountBySourceProvider(source.id),
    );
    final scrapedIds = ref.watch(scrapedSourcesProvider);
    final hasBeenScraped = scrapedIds.contains(source.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          Icons.circle,
          size: 12,
          color: source.isOnline ? Colors.green : Colors.red,
        ),
        title: Text(source.name),
        subtitle: Text(
          source.baseUrl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                folderCountAsync.when(
                  data: (foldersCount) {
                    if (foldersCount > 0) {
                      return Text('$foldersCount folders indexed');
                    }
                    return mediaItemsCountAsync.when(
                      data: (itemsCount) => Text('$itemsCount items indexed'),
                      loading: () => const Text('Loading items...'),
                      error: (err, stack) => const Text('0 folders indexed'),
                    );
                  },
                  loading: () => const Text('Loading...'),
                  error: (e, st) => mediaItemsCountAsync.when(
                    data: (itemsCount) => Text('$itemsCount items indexed'),
                    loading: () => const Text('Loading items...'),
                    error: (err, stack) => const Text('0 folders indexed'),
                  ),
                ),
                if (source.lastScraped != null)
                  Text(
                    'Last scraped: ${_formatDate(source.lastScraped!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (_progress != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (!_progress!.isDone)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 16,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _progress!.message,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!_progress!.isDone) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _StatChip(
                                Icons.language,
                                '${_progress!.urlsVisited} pages',
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                Icons.queue,
                                '${_progress!.urlsQueued} queued',
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                _progress!.isShallow
                                    ? Icons.folder_open_outlined
                                    : Icons.movie,
                                '${_progress!.filesFound} ${_progress!.isShallow ? "folders" : "files"}',
                              ),
                            ],
                          ),
                          if (_progress!.currentUrl != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _progress!.currentUrl!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final actions = ref.read(sourceActionsProvider);
                        final online = await actions.pingSource(source);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '${source.name} is ${online ? "online" : "offline"}',
                              ),
                            ),
                          );
                        }
                        ref.invalidate(sourcesProvider);
                      },
                      icon: const Icon(Icons.wifi_find_rounded, size: 18),
                      label: const Text('Ping'),
                    ),
                    const SizedBox(width: 8),
                    _isScraping
                        ? FilledButton.icon(
                            onPressed: _abortScrape,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red[800],
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            label: const Text('Abort'),
                          )
                        : FilledButton.icon(
                            onPressed: () => _startScrapeFlow(source),
                            icon: Icon(
                              hasBeenScraped
                                  ? Icons.refresh_rounded
                                  : Icons.downloading_outlined,
                              size: 18,
                            ),
                            label: Text(hasBeenScraped ? 'Refresh' : 'Scrape'),
                          ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Browse items',
                      icon: const Icon(Icons.folder_shared_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                SourceItemsScreen(source: source),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () => _showEditDialog(source),
                      tooltip: 'Edit source',
                      icon: const Icon(Icons.settings_suggest),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(source),
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Source source) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Source'),
        content: Text('Remove "${source.name}" and all its indexed items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final actions = ref.read(sourceActionsProvider);
      await actions.deleteSource(source.id);
      if (mounted) {
        ref.invalidate(sourcesProvider);
        ref.invalidate(mediaItemCountProvider);
      }
    }
  }

  void _abortScrape() {
    _scrapeSubscription?.cancel();
    setState(() {
      _isScraping = false;
      _progress = ScrapeProgress(message: 'Scrape aborted.', isDone: true);
    });
  }

  void _startScrapeFlow(Source source) async {
    final fullScrape = ref.read(settingsProvider).fullScrapeMode;
    if (fullScrape) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Full Scrape Warning'),
            ],
          ),
          content: const Text(
            'Full scrape mode is currently enabled in settings. '
            'This will scrape all media files recursively, which can take a lot of time and network requests. '
            'This might get rate-limited or blocked by the provider. '
            'Do you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    _scrapeWithProgress(source);
  }

  void _scrapeWithProgress(Source source) {
    _scrapeSubscription?.cancel();
    setState(() {
      _isScraping = true;
      _progress = null;
    });

    final actions = ref.read(sourceActionsProvider);
    final fullScrape = ref.read(settingsProvider).fullScrapeMode;

    _scrapeSubscription = actions
        .scrapeSourceWithProgress(
          source,
          fullScrape: fullScrape,
          maxDepth: source.maxDepth,
        )
        .listen(
          (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
              if (progress.isDone) {
                _isScraping = false;
                ref.invalidate(sourcesProvider);
                ref.invalidate(mediaItemCountProvider);
                ref.invalidate(mediaItemsBySourceProvider(source.id));
                ref.invalidate(mediaItemsCountBySourceProvider(source.id));
                ref.invalidate(indexedFoldersCountBySourceProvider(source.id));
              }
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isScraping = false;
              _progress = ScrapeProgress(
                message: 'Error: $error',
                isDone: true,
                error: error.toString(),
              );
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $error')));
          },
        );
  }

  void _showEditDialog(Source source) {
    showDialog(
      context: context,
      builder: (ctx) => SourceFormDialog(
        source: source,
        onSave: (name, url, maxDepth) async {
          final actions = ref.read(sourceActionsProvider);
          final warning = await actions.updateSource(
            source.id,
            name,
            url,
            maxDepth,
          );
          if (mounted) {
            ref.invalidate(sourcesProvider);
            ref.invalidate(mediaItemCountProvider);
            ref.invalidate(mediaItemsBySourceProvider(source.id));
            ref.invalidate(indexedFoldersCountBySourceProvider(source.id));
          }
          return warning;
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
