import 'package:argus/core/providers/providers.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> showConfirmClearSourceDialog(
  BuildContext context,
  WidgetRef ref,
  Source source, {
  VoidCallback? onCleared,
}) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Clear Indexed Folders'),
      content: Text(
        'Delete all indexed folders and media items from "${source.name}"?\n\nThe source configuration itself will be kept.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Clear All'),
        ),
      ],
    ),
  );

  if (confirm == true && context.mounted) {
    final actions = ref.read(sourceActionsProvider);
    await actions.clearSourceData(source.id);
    if (context.mounted) {
      ref.invalidate(sourcesProvider);
      ref.invalidate(indexedFoldersCountBySourceProvider(source.id));
      ref.invalidate(mediaItemsCountBySourceProvider(source.id));
      ref.invalidate(mediaItemCountProvider);
      onCleared?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleared indexed folders for ${source.name}')),
      );
    }
    return true;
  }
  return false;
}
