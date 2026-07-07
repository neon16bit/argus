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
    // prioritize scraping any unscraped folders for this show on any active sources
    Future.microtask(() async {
      if (!mounted) return;
      final db = ref.read(databaseProvider);
      final folders = await db.getFoldersByGroupTitle(widget.result.groupTitle);
      if (!mounted) return;
      for (final folder in folders) {
        if (!folder.isScraped) {
          ref.read(scrapeQueueProvider.notifier).prioritize(folder.folderUrl);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String activeGroupTitle = widget.result.groupTitle;
    if (widget.result.folderUrl != null) {
      final resultFolder = ref
          .watch(folderByUrlProvider(widget.result.folderUrl!))
          .value;
      if (resultFolder != null) {
        activeGroupTitle = resultFolder.cleanTitle;
      }
    }

    final metadataAsync = ref.watch(metadataProvider(activeGroupTitle));
    final metadata = metadataAsync.value;

    final itemsAsync = ref.watch(showItemsProvider(activeGroupTitle));
    final items = itemsAsync.value ?? [];

    final sourcesAsync = ref.watch(sourcesProvider);
    final allSources = sourcesAsync.value ?? [];

    final foldersAsync = ref.watch(showFoldersProvider(activeGroupTitle));
    final folders = foldersAsync.value ?? [];
    final isAnyUnscraped =
        folders.isNotEmpty && folders.any((f) => !f.isScraped);

    // invalidate metadata when scraping finishes
    ref.listen<bool>(
      showFoldersProvider(activeGroupTitle).select((v) {
        final folderList = v.value ?? [];
        return folderList.isNotEmpty &&
            folderList.any((folder) => !folder.isScraped);
      }),
      (previous, currentIsUnscraped) {
        if (previous == true && currentIsUnscraped == false) {
          ref.invalidate(metadataProvider(activeGroupTitle));
        }
      },
    );

    // reactive filtering, grouping and sorting calculations
    final viewModel = ShowViewModel.compute(
      items: items,
      allSources: allSources,
      selectedSourceId: _selectedSourceId,
    );

    final commonSlivers = [
      SliverAppBar(
        expandedHeight: 200,
        pinned: true,
        leading: Center(
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black38,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          if (isAnyUnscraped)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (folders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.cloud_sync_rounded),
                tooltip: 'Refresh Folder',
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  // clear media items for this show across all matching sources
                  await (db.delete(
                    db.mediaItems,
                  )..where((m) => m.groupTitle.equals(activeGroupTitle))).go();
                  for (final folder in folders) {
                    await (db.update(db.indexedFolders)
                          ..where((f) => f.folderUrl.equals(folder.folderUrl)))
                        .write(
                          const IndexedFoldersCompanion(
                            isScraped: Value(false),
                          ),
                        );
                    ref
                        .read(scrapeQueueProvider.notifier)
                        .prioritize(folder.folderUrl);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Refreshing folders for $activeGroupTitle...',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                foregroundColor: Colors.white,
              ),
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
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          title: Text(
            metadata?.titleEn ?? metadata?.title ?? widget.result.displayTitle,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 6,
                  color: Colors.black87,
                  offset: Offset(1.5, 1.5),
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
      key: ValueKey(
        '${widget.result.groupTitle}_${viewModel.sortedSeasons.length}',
      ),
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
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: ListView.builder(
                    key: PageStorageKey(
                      'season_${widget.result.groupTitle}_$season',
                    ),
                    primary: true,
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    itemCount: viewModel.seasonMap[season]!.length,
                    itemBuilder: (context, index) {
                      final group = viewModel.seasonMap[season]![index];
                      return FileCard(group: group);
                    },
                  ),
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
