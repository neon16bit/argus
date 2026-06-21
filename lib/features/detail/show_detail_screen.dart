import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:drift/drift.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/features/detail/widgets/metadata_card.dart';
import 'package:argus/features/detail/widgets/file_card.dart';
import 'package:argus/features/detail/widgets/source_filter.dart';
import 'package:argus/features/detail/show_view_model.dart';

class ShowDetailScreen extends ConsumerStatefulWidget {
  final SearchResult result;

  const ShowDetailScreen({super.key, required this.result});

  @override
  ConsumerState<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends ConsumerState<ShowDetailScreen> {
  int? _selectedSourceId;

  @override
  void initState() {
    super.initState();
    // prioritize scrape if this result was opened from a shallow indexed folder
    final folderUrl = widget.result.folderUrl;
    if (!widget.result.isScraped && folderUrl != null) {
      Future.microtask(
        () => ref.read(scrapeQueueProvider.notifier).prioritize(folderUrl),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadataAsync = ref.watch(metadataProvider(widget.result.groupTitle));
    final metadata = metadataAsync.value;

    final itemsAsync = ref.watch(showItemsProvider(widget.result.groupTitle));
    final items = itemsAsync.value ?? [];

    final sourcesAsync = ref.watch(sourcesProvider);
    final allSources = sourcesAsync.value ?? [];

    // reactive filtering, grouping and sorting calculations
    final viewModel = ShowViewModel.compute(
      items: items,
      allSources: allSources,
      selectedSourceId: _selectedSourceId,
    );

    final commonSlivers = [
      SliverAppBar(
        expandedHeight: 280,
        pinned: true,
        actions: [
          if (!widget.result.isScraped)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (widget.result.folderUrl != null)
            IconButton(
              icon: const Icon(Icons.cloud_sync_rounded),
              tooltip: 'Re-scrape Folder',
              onPressed: () async {
                final db = ref.read(databaseProvider);
                await (db.delete(db.mediaItems)..where(
                      (m) => m.groupTitle.equals(widget.result.groupTitle),
                    ))
                    .go();
                await (db.update(db.indexedFolders)..where(
                      (f) => f.folderUrl.equals(widget.result.folderUrl!),
                    ))
                    .write(
                      const IndexedFoldersCompanion(isScraped: Value(false)),
                    );
                ref
                    .read(scrapeQueueProvider.notifier)
                    .prioritize(widget.result.folderUrl!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Re-scraping ${widget.result.displayTitle}...',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
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
              DetailHeader(metadata: metadata),
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
      SliverToBoxAdapter(child: MetadataCard(metadata: metadata)),
      SliverToBoxAdapter(
        child: SourceFilterBar(
          viewModel: viewModel,
          selectedSourceId: _selectedSourceId,
          totalItems: items.length,
          onSourceSelected: (sourceId) {
            setState(() {
              _selectedSourceId = sourceId;
            });
          },
        ),
      ),
    ];

    final hasOnlyNullSeason =
        viewModel.seasonMap.length == 1 &&
        viewModel.seasonMap.containsKey(null);

    if (viewModel.seasonMap.isEmpty || hasOnlyNullSeason) {
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
                  ...viewModel.seasonMap[null]!.map(
                    (group) => FileCard(group: group),
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
      length: viewModel.sortedSeasons.length,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              ...commonSlivers,
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    isScrollable: true,
                    tabs: [
                      for (final season in viewModel.sortedSeasons)
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
              for (final season in viewModel.sortedSeasons)
                ListView.builder(
                  key: PageStorageKey(
                    'season_${widget.result.groupTitle}_$season',
                  ),
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  itemCount: viewModel.seasonMap[season]!.length,
                  itemBuilder: (context, index) {
                    final group = viewModel.seasonMap[season]![index];
                    return FileCard(group: group);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

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
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
