import 'package:argus/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:argus/data/remote/metadata/metadata_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShowDetailScreen extends ConsumerStatefulWidget {
  final SearchResult result;

  const ShowDetailScreen({super.key, required this.result});

  @override
  ConsumerState<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends ConsumerState<ShowDetailScreen> {
  int? _selectedSourceId;

  @override
  Widget build(BuildContext context) {
    final metadataAsync = ref.watch(metadataProvider(widget.result.groupTitle));
    final metadata = metadataAsync.value;

    // load items on-demand
    final itemsAsync = ref.watch(showItemsProvider(widget.result.groupTitle));
    final items = itemsAsync.value ?? [];

    // get all sources to match source names
    final sourcesAsync = ref.watch(sourcesProvider);
    final allSources = sourcesAsync.value ?? [];

    // determine which sources are contributing to this show's items
    final showSourceIds = items.map((i) => i.sourceId).toSet();
    final contributingSources = allSources
        .where((s) => showSourceIds.contains(s.id))
        .toList();

    // group items by season
    final tempSeasonMap = <int?, List<dynamic>>{};
    for (final item in items) {
      tempSeasonMap.putIfAbsent(item.season, () => []).add(item);
    }

    final filteredItems = <dynamic>[];
    final seasonMap = <int?, List<List<dynamic>>>{};

    for (final entry in tempSeasonMap.entries) {
      final season = entry.key;
      final episodes = entry.value;

      // filter episodes by selected source
      final filteredEpisodesForSeason = _selectedSourceId == null
          ? episodes
          : episodes.where((i) => i.sourceId == _selectedSourceId).toList();

      // if the selected source doesnt have this season, fall back to all sources
      final finalEpisodesForSeason = filteredEpisodesForSeason.isNotEmpty
          ? filteredEpisodesForSeason
          : episodes;

      filteredItems.addAll(finalEpisodesForSeason);

      final groupedEpisodes = <int?, List<dynamic>>{};
      final nullEpisodes = <dynamic>[];

      for (final item in finalEpisodesForSeason) {
        if (item.episode == null) {
          nullEpisodes.add(item);
        } else {
          groupedEpisodes.putIfAbsent(item.episode, () => []).add(item);
        }
      }

      final sortedGrouped = groupedEpisodes.values.toList()
        ..sort(
          (a, b) => (a.first.episode ?? 0).compareTo(b.first.episode ?? 0),
        );

      seasonMap[season] = [
        ...sortedGrouped,
        ...nullEpisodes.map((e) => [e]),
      ];
    }

    final sortedSeasons = seasonMap.keys.toList()
      ..sort((a, b) {
        final aVal = a ?? 0;
        final bVal = b ?? 0;
        if (aVal == 0 && bVal != 0) return 1;
        if (bVal == 0 && aVal != 0) return -1;
        return aVal.compareTo(bVal);
      });

    final commonSlivers = [
      SliverAppBar(
        expandedHeight: 280,
        pinned: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metadata',
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.clearShowCache(widget.result.groupTitle);
              ref.invalidate(metadataProvider(widget.result.groupTitle));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Refreshing metadata for ${widget.result.displayTitle}...',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          title: Text(
            metadata?.titleEn ?? metadata?.title ?? widget.result.displayTitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          background: Stack(
            fit: StackFit.expand,
            children: [
              _buildHeader(context, metadata),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.5, 1.0],
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // metadata card (poster, info)
      SliverToBoxAdapter(
        child: _buildMetadataCard(
          context,
          metadata,
          items,
          filteredItems,
          contributingSources,
        ),
      ),
    ];

    final hasOnlyNullSeason =
        seasonMap.length == 1 && seasonMap.containsKey(null);

    if (seasonMap.isEmpty || hasOnlyNullSeason) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            ...commonSlivers,
            if (hasOnlyNullSeason) ...[
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
                  ...seasonMap[null]!.map(
                    (item) => _buildFileCard(context, item),
                  ),
                ]),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: sortedSeasons.length,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              ...commonSlivers,
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    isScrollable: true,
                    tabs: [
                      for (final season in sortedSeasons)
                        Tab(
                          text: season == 0
                              ? 'Specials'
                              : (season == null ? 'Extras' : 'Season $season'),
                        ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              for (final season in sortedSeasons)
                ListView.builder(
                  key: PageStorageKey(
                    'season_${widget.result.groupTitle}_$season',
                  ),
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  itemCount: seasonMap[season]!.length,
                  itemBuilder: (context, index) {
                    final item = seasonMap[season]![index];
                    return _buildFileCard(context, item);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, List<dynamic> group) {
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
        onTap: () => _showPlayOptions(context, titleStr, group),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ShowMetadata? metadata) {
    if (metadata?.backdropUrl != null) {
      return CachedNetworkImage(
        imageUrl: metadata!.backdropUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => _defaultHeader(context),
      );
    } else if (metadata?.posterUrl != null) {
      return CachedNetworkImage(
        imageUrl: metadata!.posterUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorWidget: (_, _, _) => _defaultHeader(context),
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

  Widget _buildMetadataCard(
    BuildContext context,
    ShowMetadata? metadata,
    List<dynamic> items,
    List<dynamic> filteredItems,
    List<Source> contributingSources,
  ) {
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedSourceId == null
                    ? '${items.length} items'
                    : '${filteredItems.length} of ${items.length} items',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          if (contributingSources.length > 1) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    selected: _selectedSourceId == null,
                    label: const Text('All Sources'),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedSourceId = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ...contributingSources.map((source) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: _selectedSourceId == source.id,
                        label: Text(source.name),
                        onSelected: (selected) {
                          setState(() {
                            _selectedSourceId = selected ? source.id : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
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
          Text(
            provider,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayOptions(
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
