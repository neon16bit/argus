import 'package:argus/core/constants.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/features/detail/show_detail_screen.dart';
import 'package:argus/features/home/widgets/continue_watching_card.dart';
import 'package:argus/features/search/search_screen.dart';
import 'package:argus/features/settings/settings_screen.dart';
import 'package:argus/features/shell/app_shell.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatchingAsync = ref.watch(continueWatchingProvider);
    final savedShowsAsync = ref.watch(savedShowsProvider);
    final sourcesAsync = ref.watch(sourcesProvider);
    final isDesktop = context.isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Argus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search',
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
              },
            ),
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              tooltip: 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
        ],
      ),
      body: continueWatchingAsync.when(
        data: (continueWatching) {
          final savedShows = savedShowsAsync.value ?? [];
          final sources = sourcesAsync.value ?? [];
          final hasSources = sources.isNotEmpty;
          final hasContinueWatching = continueWatching.isNotEmpty;
          final hasSavedShows = savedShows.isNotEmpty;

          if (!hasSources) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/argus_icon.svg',
                      width: 64,
                      height: 64,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Argus',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sources found. Add a media source directory to start discovering shows.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(navigationIndexProvider.notifier).setIndex(2);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Source'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!hasContinueWatching && !hasSavedShows) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/argus_icon.svg',
                      width: 64,
                      height: 64,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Argus',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search and explore. Shows you watch or bookmark will appear here for easy access.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        if (isDesktop) {
                          ref
                              .read(navigationIndexProvider.notifier)
                              .setIndex(4);
                          ref
                              .read(searchFocusTriggerProvider.notifier)
                              .trigger();
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Search & Explore'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              if (hasContinueWatching) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Continue Watching',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 235,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: continueWatching.length,
                    itemBuilder: (context, index) {
                      return ContinueWatchingCard(
                        item: continueWatching[index],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (hasSavedShows)
                _LibraryShelf(
                  shows: savedShows,
                  isDesktop: isDesktop,
                  onViewAll: () {
                    ref.read(navigationIndexProvider.notifier).setIndex(1);
                  },
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _LibraryShelf extends StatefulWidget {
  final List<SearchResult> shows;
  final bool isDesktop;
  final VoidCallback onViewAll;

  const _LibraryShelf({
    required this.shows,
    required this.isDesktop,
    required this.onViewAll,
  });

  @override
  State<_LibraryShelf> createState() => _LibraryShelfState();
}

class _LibraryShelfState extends State<_LibraryShelf> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void didUpdateWidget(covariant _LibraryShelf oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shows.length != widget.shows.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateScrollButtons(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final canLeft = pos.pixels > 5;
    final canRight = pos.pixels < pos.maxScrollExtent - 5;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scroll(bool forward) {
    if (!_scrollController.hasClients) return;
    final delta = (_scrollController.position.viewportDimension * 0.75).clamp(
      240.0,
      900.0,
    );
    final target = forward
        ? (_scrollController.offset + delta).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          )
        : (_scrollController.offset - delta).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = widget.isDesktop ? 140.0 : 120.0;
    final shelfHeight = widget.isDesktop ? 250.0 : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'From Your Library',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  iconSize: 22,
                  tooltip: 'Scroll left',
                  onPressed: _canScrollLeft ? () => _scroll(false) : null,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withAlpha(_canScrollLeft ? 120 : 40),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  iconSize: 22,
                  tooltip: 'Scroll right',
                  onPressed: _canScrollRight ? () => _scroll(true) : null,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withAlpha(_canScrollRight ? 120 : 40),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              TextButton(
                onPressed: widget.onViewAll,
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: shelfHeight,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: widget.shows.length,
            itemBuilder: (context, index) {
              final show = widget.shows[index];
              final posterUrl = show.posterUrl;
              return Container(
                width: cardWidth,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShowDetailScreen(result: show),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: posterUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: posterUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      _defaultPoster(context),
                                )
                              : _defaultPoster(context),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            show.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: widget.isDesktop ? 13 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _defaultPoster(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          size: 36,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
