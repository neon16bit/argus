import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/core/utils/episode_fixer.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:argus/data/database/app_database.dart';
import 'package:argus/features/detail/widgets/metadata_card.dart';
import 'package:argus/features/detail/widgets/file_card.dart';
import 'package:argus/features/detail/widgets/source_filter.dart';
import 'package:argus/features/detail/show_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ShowDetailScreen extends ConsumerStatefulWidget {
  final SearchResult result;

  const ShowDetailScreen({super.key, required this.result});

  @override
  ConsumerState<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends ConsumerState<ShowDetailScreen> {
  int? _selectedSourceId;
  bool _isRetryingErrors = false;

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

  Future<void> _refreshFolders(
    BuildContext context,
    String activeGroupTitle,
    List<IndexedFolder> folders,
  ) async {
    final db = ref.read(databaseProvider);
    // clear media items for this show across all matching sources
    await (db.delete(
      db.mediaItems,
    )..where((m) => m.groupTitle.equals(activeGroupTitle))).go();
    for (final folder in folders) {
      await (db.update(db.indexedFolders)
            ..where((f) => f.folderUrl.equals(folder.folderUrl)))
          .write(const IndexedFoldersCompanion(isScraped: Value(false)));
      ref.read(scrapeQueueProvider.notifier).prioritize(folder.folderUrl);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refreshing folders for $activeGroupTitle...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _refreshMetadata(
    BuildContext context,
    String groupTitle,
    String displayTitle,
  ) async {
    final db = ref.read(databaseProvider);
    await db.clearShowCache(groupTitle);
    ref.invalidate(metadataProvider(groupTitle));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refreshing metadata for $displayTitle...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fixEpisodeNumbers(
    BuildContext context,
    String activeGroupTitle,
  ) async {
    final db = ref.read(databaseProvider);
    final items = await db.getMediaItemsByGroupTitle(activeGroupTitle);
    final result = EpisodeFixer.detect(items);

    if (result.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No episode number issues detected'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final sortedSeasons = result.seasons.keys.toList()
      ..sort((a, b) {
        final aVal = a ?? 0;
        final bVal = b ?? 0;
        if (aVal == 0 && bVal != 0) return 1;
        if (bVal == 0 && aVal != 0) return -1;
        return aVal.compareTo(bVal);
      });

    // regular seasons are selected
    // specials (season == 0) are unselected
    final selectedSeasons = <int?>{
      for (final s in sortedSeasons)
        if (s != null && s > 0) s,
    };
    if (selectedSeasons.isEmpty && sortedSeasons.isNotEmpty) {
      selectedSeasons.add(sortedSeasons.first);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalSelectedItems = selectedSeasons.fold<int>(
              0,
              (sum, s) => sum + (result.seasons[s]?.itemCount ?? 0),
            );

            return AlertDialog(
              title: const Text('Fix Episode Listing'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select the seasons to apply detected episode numbers:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ...sortedSeasons.map((season) {
                      final info = result.seasons[season]!;
                      final seasonLabel = season == null
                          ? 'Extras'
                          : season == 0
                          ? 'Specials'
                          : 'Season $season';

                      final detailStr = info.itemCount == info.episodeCount
                          ? '${info.episodeCount} episodes'
                          : '${info.episodeCount} episodes (${info.itemCount} files)';

                      final isSelected = selectedSeasons.contains(season);

                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(seasonLabel),
                        subtitle: Text(detailStr),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedSeasons.add(season);
                            } else {
                              selectedSeasons.remove(season);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedSeasons.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  child: Text(
                    totalSelectedItems > 0
                        ? 'Apply ($totalSelectedItems)'
                        : 'Apply',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      final updatesToApply = <int, int>{};
      for (final s in selectedSeasons) {
        if (result.seasons.containsKey(s)) {
          updatesToApply.addAll(result.seasons[s]!.updates);
        }
      }

      if (updatesToApply.isNotEmpty) {
        await db.updateEpisodeNumbers(updatesToApply);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fixed episode numbers for ${updatesToApply.length} items',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _copyFolderUrl(BuildContext context, String? url) {
    if (url == null || url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Folder URL copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openInBrowser(String? url) {
    if (url == null || url.isEmpty) return;
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
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
    final folderUrl = widget.result.folderUrl ?? folders.firstOrNull?.folderUrl;
    final isAnyUnscraped =
        folders.isNotEmpty && folders.any((f) => !f.isScraped);
    final foldersWithErrors = folders
        .where((f) => f.scrapeErrors != null)
        .toList();

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

    final isSaved =
        ref.watch(isShowSavedProvider(activeGroupTitle)).value ?? false;

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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                foregroundColor: isSaved
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
              icon: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
              tooltip: isSaved ? 'In Library' : 'Add to Library',
              onPressed: () async {
                final db = ref.read(databaseProvider);
                final nowSaved = await db.toggleSaveShow(activeGroupTitle);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nowSaved
                            ? 'Added "${widget.result.displayTitle}" to Library'
                            : 'Removed "${widget.result.displayTitle}" from Library',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ),
          if (isWide) ...[
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
                  onPressed: () =>
                      _refreshFolders(context, activeGroupTitle, folders),
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
                onPressed: () => _refreshMetadata(
                  context,
                  widget.result.groupTitle,
                  widget.result.displayTitle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.auto_fix_high_rounded),
                tooltip: 'Fix Episode Listing',
                onPressed: () => _fixEpisodeNumbers(context, activeGroupTitle),
              ),
            ),
            if (folderUrl != null) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy Folder URL',
                  onPressed: () => _copyFolderUrl(context, folderUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.open_in_browser_rounded),
                  tooltip: 'Open in Browser',
                  onPressed: () => _openInBrowser(folderUrl),
                ),
              ),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String>(
                    tooltip: 'More actions',
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
                    onSelected: (value) {
                      if (value == 'refresh_folder') {
                        _refreshFolders(context, activeGroupTitle, folders);
                      } else if (value == 'refresh_metadata') {
                        _refreshMetadata(
                          context,
                          widget.result.groupTitle,
                          widget.result.displayTitle,
                        );
                      } else if (value == 'fix_episodes') {
                        _fixEpisodeNumbers(context, activeGroupTitle);
                      } else if (value == 'copy_folder_url') {
                        _copyFolderUrl(context, folderUrl);
                      } else if (value == 'open_in_browser') {
                        _openInBrowser(folderUrl);
                      }
                    },
                    itemBuilder: (context) => [
                      if (folders.isNotEmpty)
                        const PopupMenuItem(
                          value: 'refresh_folder',
                          child: Row(
                            children: [
                              Icon(Icons.cloud_sync_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Refresh Folder'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'refresh_metadata',
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Refresh Metadata'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'fix_episodes',
                        child: Row(
                          children: [
                            Icon(Icons.auto_fix_high_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Fix Episode Listing'),
                          ],
                        ),
                      ),
                      if (folderUrl != null) ...[
                        const PopupMenuItem(
                          value: 'copy_folder_url',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Copy Folder URL'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'open_in_browser',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_browser_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Open in Browser'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
      if (foldersWithErrors.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Some folders couldn\'t be fully indexed due to rate limits or errors.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_isRetryingErrors)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      FilledButton.tonal(
                        onPressed: () async {
                          setState(() {
                            _isRetryingErrors = true;
                          });
                          final actions = ref.read(sourceActionsProvider);
                          final settings = ref.read(settingsProvider);
                          final db = ref.read(databaseProvider);

                          for (final folder in foldersWithErrors) {
                            final source = await db.getSource(folder.sourceId);
                            final delay = source.requestDelayMs != null
                                ? Duration(milliseconds: source.requestDelayMs!)
                                : settings.scrapeDelay;

                            await actions.retryScrapeErrors(
                              folder,
                              requestDelay: delay,
                            );
                          }

                          if (mounted) {
                            setState(() {
                              _isRetryingErrors = false;
                            });
                          }
                        },
                        child: const Text('Retry Failed'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
