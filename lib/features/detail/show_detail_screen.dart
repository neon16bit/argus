import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:argus/data/remote/metadata/metadata_provider.dart';

class ShowDetailScreen extends ConsumerWidget {
  final SearchResult result;

  const ShowDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataAsync = ref.watch(metadataProvider(result.cleanTitle));
    final metadata = metadataAsync.value;

    // group items by season
    final seasonMap = <int?, List<dynamic>>{};
    for (final item in result.items) {
      seasonMap.putIfAbsent(item.season, () => []).add(item);
    }
    for (final episodes in seasonMap.values) {
      episodes.sort((a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0));
    }
    final sortedSeasons = seasonMap.keys.toList()
      ..sort((a, b) => (a ?? 0).compareTo(b ?? 0));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // collapsing header with poster/fanart
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                metadata?.title ?? result.cleanTitle,
                style: const TextStyle(
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
              background: _buildHeader(context, metadata),
            ),
          ),

          // metadata card (poster, info)
          SliverToBoxAdapter(child: _buildMetadataCard(context, metadata)),

          // files by season
          if (seasonMap.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Available Files',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                for (final season in sortedSeasons) ...[
                  if (season != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Season $season',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ...seasonMap[season]!.map(
                    (item) => Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.play_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          item.episode != null
                              ? 'Episode ${item.episode}'
                              : item.rawName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item.rawName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          item.fileExtension?.toUpperCase() ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () => _showPlayOptions(context, item.rawName, [
                          item.directUrl,
                        ]),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ],

          // bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ShowMetadata? metadata) {
    if (metadata?.backdropUrl != null) {
      return Image.network(
        metadata!.backdropUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _defaultHeader(context),
      );
    } else if (metadata?.posterUrl != null) {
      return Image.network(
        metadata!.posterUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) => _defaultHeader(context),
      );
    }
    return _defaultHeader(context);
  }

  Widget _defaultHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.movie_rounded, size: 64, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context, ShowMetadata? metadata) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              if (metadata?.posterUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    metadata!.posterUrl!,
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
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
              // Info
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
          const SizedBox(height: 16),
          Text(
            '${result.items.length} items',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showPlayOptions(BuildContext context, String title, List<String> urls) {
    showModalBottomSheet(
      context: context,
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
            ...urls.map(
              (url) => ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('Play In-App'),
                subtitle: Text(
                  Uri.parse(url).host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _playInApp(context, url);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open in External Player'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: implement open in external player/urilauncher
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy URL'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: urls.first));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _playInApp(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _VideoPlayerScreen(url: url)),
    );
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  final String url;

  const _VideoPlayerScreen({required this.url});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.url));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(child: Video(controller: _controller)),
    );
  }
}
