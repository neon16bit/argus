import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:argus/features/detail/widgets/video_player_screen.dart';

class FileCard extends StatelessWidget {
  final List<dynamic> group;

  const FileCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    if (group.isEmpty) return const SizedBox.shrink();

    final item = group.first;
    final isMulti = group.length > 1;

    final titleStr = item.episode != null
        ? 'Episode ${item.episode}'
        : item.rawName;
    final subtitleStr = isMulti
        ? 'Multiple versions available (${group.length})'
        : item.rawName;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        dense: true,
        leading: Icon(
          isMulti ? Icons.video_library_rounded : Icons.play_circle_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(titleStr, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          subtitleStr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Text(
          isMulti ? '' : (item.fileExtension?.toUpperCase() ?? ''),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        onTap: () => _showPlayOptionsBottomSheet(context, titleStr, group),
      ),
    );
  }

  void _showPlayOptionsBottomSheet(
    BuildContext context,
    String title,
    List<dynamic> items,
  ) {
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
              'Play: $title',
              style: Theme.of(ctx).textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items
                      .map<Widget>(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.play_arrow_rounded),
                          title: Text(
                            item.rawName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            Uri.parse(item.directUrl).host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                  // TODO: implement open in external player/urilauncher
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _playInApp(context, item.directUrl);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playInApp(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: url)),
    );
  }
}
