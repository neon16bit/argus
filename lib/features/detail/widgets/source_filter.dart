import 'package:flutter/material.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/core/utils/audio_tag_helper.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/features/detail/show_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SourceFilterBar extends ConsumerWidget {
  final ShowViewModel viewModel;
  final int? selectedSourceId;
  final int totalItems;
  final ValueChanged<int?> onSourceSelected;
  final List<IndexedFolder> folders;
  final String? preferredFolderUrl;
  final ValueChanged<String?> onVersionSelected;

  const SourceFilterBar({
    super.key,
    required this.viewModel,
    required this.selectedSourceId,
    required this.totalItems,
    required this.onSourceSelected,
    this.folders = const [],
    this.preferredFolderUrl,
    required this.onVersionSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (totalItems == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final contributingSources = viewModel.contributingSources;
    final hasMultipleFolders = folders.length > 1;
    final hasFilterActive =
        selectedSourceId != null || preferredFolderUrl != null;

    IndexedFolder? preferredFolder;
    if (preferredFolderUrl != null && folders.isNotEmpty) {
      try {
        preferredFolder = folders.firstWhere(
          (f) => f.folderUrl == preferredFolderUrl,
        );
      } catch (_) {
        preferredFolder = null;
      }
    }

    final dubOverrides = ref.watch(dubOverrideProvider);
    final isPreferredDub = preferredFolder != null
        ? AudioTagHelper.isDub(
            preferredFolder.folderUrl,
            override: dubOverrides[preferredFolder.folderUrl],
          )
        : false;

    final countText = selectedSourceId == null
        ? '$totalItems ${totalItems == 1 ? 'item' : 'items'}'
        : '${viewModel.filteredItems.length} of $totalItems items';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  countText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasMultipleFolders) ...[
                  const SizedBox(height: 2),
                  if (preferredFolder != null)
                    Row(
                      children: [
                        if (isPreferredDub) ...[
                          const DubBadge(),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            'Default: ${preferredFolder.folderName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Multiple versions · tap filter to set default',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (folders.isNotEmpty || contributingSources.isNotEmpty)
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: hasFilterActive
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                foregroundColor: hasFilterActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Filter sources & versions',
              onPressed: () => _showFilterSheet(context, ref),
            ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contributingSources = viewModel.contributingSources;
    final hasMultipleSources = contributingSources.length > 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        var currentSelectedSourceId = selectedSourceId;
        var currentPreferredFolderUrl = preferredFolderUrl;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer(
              builder: (context, sheetRef, _) {
                final hasFilterActive =
                    currentSelectedSourceId != null ||
                    currentPreferredFolderUrl != null;
                final displayedFolders = currentSelectedSourceId == null
                    ? folders
                    : folders
                          .where((f) => f.sourceId == currentSelectedSourceId)
                          .toList();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sources & Versions',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (hasFilterActive)
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  currentSelectedSourceId = null;
                                  currentPreferredFolderUrl = null;
                                });
                                onSourceSelected(null);
                                onVersionSelected(null);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Reset All'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (hasMultipleSources) ...[
                        Text(
                          'Source Filter',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                showCheckmark: false,
                                selected: currentSelectedSourceId == null,
                                label: const Text('All Sources'),
                                onSelected: (selected) {
                                  if (selected) {
                                    setSheetState(() {
                                      currentSelectedSourceId = null;
                                    });
                                    onSourceSelected(null);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              ...contributingSources.map((source) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    showCheckmark: false,
                                    selected:
                                        currentSelectedSourceId == source.id,
                                    label: Text(source.name),
                                    onSelected: (selected) {
                                      final nextId = selected
                                          ? source.id
                                          : null;
                                      setSheetState(() {
                                        currentSelectedSourceId = nextId;
                                      });
                                      onSourceSelected(nextId);
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (displayedFolders.isNotEmpty) ...[
                        Text(
                          displayedFolders.length > 1
                              ? 'Default Version'
                              : 'Version',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (displayedFolders.length > 1) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Directly plays this version on tap',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (displayedFolders.length > 1)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              currentPreferredFolderUrl == null
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: currentPreferredFolderUrl == null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            title: const Text('All Versions (Ask on play)'),
                            onTap: () {
                              setSheetState(() {
                                currentPreferredFolderUrl = null;
                              });
                              onVersionSelected(null);
                              Navigator.pop(ctx);
                            },
                          ),
                        ...displayedFolders.map((folder) {
                          final dubOverrides = sheetRef.watch(
                            dubOverrideProvider,
                          );
                          final isDub = AudioTagHelper.isDub(
                            folder.folderUrl,
                            override: dubOverrides[folder.folderUrl],
                          );
                          final isSelected =
                              currentPreferredFolderUrl == folder.folderUrl;

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: displayedFolders.length > 1
                                ? Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    size: 20,
                                  )
                                : null,
                            title: Text(
                              folder.folderName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                if (isDub) ...[
                                  const DubBadge(),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    Uri.tryParse(folder.folderUrl)?.host ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              tooltip: 'Audio tag options',
                              onSelected: (value) async {
                                String msg = '';
                                if (value == 'dub') {
                                  await sheetRef
                                      .read(dubOverrideProvider.notifier)
                                      .setOverride(folder.folderUrl, true);
                                  msg = 'Marked "${folder.folderName}" as DUB';
                                } else if (value == 'sub') {
                                  await sheetRef
                                      .read(dubOverrideProvider.notifier)
                                      .setOverride(folder.folderUrl, false);
                                  msg = 'Marked "${folder.folderName}" as SUB';
                                } else if (value == 'auto') {
                                  await sheetRef
                                      .read(dubOverrideProvider.notifier)
                                      .setOverride(folder.folderUrl, null);
                                  msg =
                                      'Reset "${folder.folderName}" to auto-detection';
                                }
                                if (context.mounted && msg.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'dub',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.record_voice_over_rounded,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Mark as DUB'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'sub',
                                  child: Row(
                                    children: [
                                      Icon(Icons.subtitles_rounded, size: 18),
                                      SizedBox(width: 10),
                                      Text('Mark as SUB'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'auto',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Reset to Auto-detect'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              setSheetState(() {
                                currentPreferredFolderUrl = folder.folderUrl;
                              });
                              onVersionSelected(folder.folderUrl);
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
