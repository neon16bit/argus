import 'package:argus/core/providers/providers.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/features/sources/widgets/scrape_progress_sheet.dart';
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

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    final itemCountAsync = ref.watch(mediaItemsBySourceProvider(source.id));

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
                itemCountAsync.when(
                  data: (items) => Text('${items.length} items indexed'),
                  loading: () => const Text('Loading...'),
                  error: (e, st) => const Text('0 items'),
                ),
                if (source.lastScraped != null)
                  Text(
                    'Last scraped: ${_formatDate(source.lastScraped!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                    FilledButton.icon(
                      onPressed: _isScraping
                          ? null
                          : () => _scrapeWithProgress(source),
                      icon: _isScraping
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.downloading_outlined, size: 18),
                      label: Text(_isScraping ? 'Scraping...' : 'Scrape'),
                    ),
                    const Spacer(),
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
      ref.invalidate(sourcesProvider);
      ref.invalidate(mediaItemCountProvider);
    }
  }

  void _scrapeWithProgress(Source source) async {
    const int kFlatScrapeDepth = 1;
    const int kGroupedScrapeDepth = 2;
    final int? selectedDepth = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int tempDepth = kFlatScrapeDepth;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Scrape Options'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Grouped structure'),
                      subtitle: const Text(
                        'Nested by year or letter (e.g. /2010/)',
                      ),
                      value: tempDepth == kGroupedScrapeDepth,
                      onChanged: (bool val) {
                        setStateDialog(() {
                          tempDepth = val
                              ? kGroupedScrapeDepth
                              : kFlatScrapeDepth;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Expected folder structure:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      child: Text(
                        tempDepth == kFlatScrapeDepth
                            ? 'root/\n└── [Show or Movie Folder]/'
                                  '\n└── [Show or Movie Folder]/'
                            : 'root/\n└── [Year / Alphabet Group]/'
                                  '\n     └── [Show or Movie Folder]/'
                                  '\n     └── [Show or Movie Folder]/'
                                  '\n└── [Year / Alphabet Group]/'
                                  '\n     └── [Show or Movie Folder]/'
                                  '\n     └── [Show or Movie Folder]/',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, tempDepth),
                  child: const Text('Scrape'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedDepth == null) return;

    setState(() => _isScraping = true);
    final actions = ref.read(sourceActionsProvider);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => ScrapeProgressSheet(
        sourceActions: actions,
        source: source,
        maxDepth: selectedDepth,
        onDone: (count) {
          Navigator.pop(ctx);
          setState(() => _isScraping = false);
          ref.invalidate(sourcesProvider);
          ref.invalidate(mediaItemCountProvider);
          ref.invalidate(mediaItemsBySourceProvider(source.id));
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Indexed $count items')));
          }
        },
        onError: (error) {
          Navigator.pop(ctx);
          setState(() => _isScraping = false);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $error')));
          }
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
