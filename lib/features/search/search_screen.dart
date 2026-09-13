import 'package:flutter/material.dart';
import 'package:argus/core/constants.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/features/search/widgets/search_result_card.dart';
import 'package:argus/features/shell/app_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(searchQueryProvider.notifier).set(query);
  }

  void _goToSources() {
    ref.read(navigationIndexProvider.notifier).setIndex(2);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final sourcesAsync = ref.watch(sourcesProvider);
    final hasIndexedContentAsync = ref.watch(hasIndexedContentProvider);
    final isDesktop = context.isDesktop;
    final theme = Theme.of(context);
    final query = ref.watch(searchQueryProvider);

    final sources = sourcesAsync.value ?? [];
    final hasSources = sources.isNotEmpty;

    final hasIndexedContent = hasIndexedContentAsync.value ?? true;

    ref.listen<int>(searchFocusTriggerProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          if (_controller.text.isNotEmpty) {
            _controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _controller.text.length,
            );
          }
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isDesktop,
        titleSpacing: isDesktop ? 20 : 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for a show, movie...',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _onSearch,
          onSubmitted: _onSearch,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                _onSearch('');
              },
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (!hasSources && !sourcesAsync.isLoading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/argus_icon.svg',
                      width: 56,
                      height: 56,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurfaceVariant.withAlpha(160),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No sources added',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        'Add a media source directory first to start discovering and searching shows.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _goToSources,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Source'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!hasIndexedContent && !hasIndexedContentAsync.isLoading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.manage_search_rounded,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nothing indexed yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        'You have sources added, but nothing has been indexed yet. Head to Sources to index your media library.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonalIcon(
                      onPressed: _goToSources,
                      icon: const Icon(Icons.folder_outlined),
                      label: const Text('Go to Sources'),
                    ),
                  ],
                ),
              ),
            );
          }

          return resultsAsync.when(
            data: (results) {
              if (query.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 56,
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(
                          150,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Search your indexed sources',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (results.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(
                            160,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No results found',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No shows or files matching "$query"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) =>
                        SearchResultCard(result: results[index]),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
      ),
    );
  }
}
