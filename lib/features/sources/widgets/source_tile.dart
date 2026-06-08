import 'package:flutter/material.dart';
import 'package:argus/data/scrapers/directory_scraper.dart';
import 'package:http/http.dart' as http;

class SourceTile extends StatefulWidget {
  final dynamic source;
  final VoidCallback onDelete;

  const SourceTile({super.key, required this.source, required this.onDelete});

  @override
  State<SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends State<SourceTile> {
  bool _isScraping = false;
  bool _isPinging = false;

  @override
  Widget build(BuildContext context) {
    final source = widget.source;

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
                Text('${source.items.length} items indexed'),
                if (source.lastScraped != null)
                  Text(
                    'Last scraped: ${_formatDate(source.lastScraped!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isPinging
                          ? null
                          : () async {
                              setState(() => _isPinging = true);
                              try {
                                final res = await http
                                    .get(Uri.parse(source.baseUrl))
                                    .timeout(const Duration(seconds: 5));
                                setState(() {
                                  source.isOnline = res.statusCode == 200;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${source.name} is ${source.isOnline ? "online" : "offline"}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => source.isOnline = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${source.name} is offline (timeout)',
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isPinging = false);
                              }
                            },
                      icon: _isPinging
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find_rounded, size: 18),
                      label: const Text('Ping'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isScraping
                          ? null
                          : () async {
                              setState(() => _isScraping = true);
                              try {
                                final results =
                                    await DirectoryScraper.scrapeDirectory(
                                      source.baseUrl,
                                    );
                                if (mounted) {
                                  setState(() {
                                    source.items = results;
                                    source.lastScraped = DateTime.now();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Scraped ${results.length} items from ${source.name}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Scrape failed: $e'),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isScraping = false);
                                }
                              }
                            },
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

  void _confirmDelete(dynamic source) async {
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
      widget.onDelete();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
