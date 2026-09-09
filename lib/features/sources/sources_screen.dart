import 'package:flutter/material.dart';
import 'package:argus/features/sources/widgets/source_tile.dart';
import 'package:argus/features/settings/settings_screen.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:argus/features/sources/widgets/source_form_dialog.dart';

class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen> {
  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(sourcesProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 500;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sources'),
        actions: [
          if (isWide)
            FilledButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Source'),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add Source',
              onPressed: () => _showAddDialog(context),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sourcesAsync.when(
        data: (sources) {
          if (sources.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dns_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No sources yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Add an open directory URL to get started',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Source'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sources.length,
            itemBuilder: (context, index) => SourceTile(source: sources[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SourceFormDialog(
        onSave: (name, url, maxDepth, autoScrape, requestDelayMs) async {
          final actions = ref.read(sourceActionsProvider);
          final result = await actions.addSource(
            name,
            url,
            maxDepth,
            autoScrape,
            requestDelayMs,
          );
          if (mounted) {
            ref.invalidate(sourcesProvider);
            ref.invalidate(mediaItemCountProvider);
          }
          return result;
        },
      ),
    );
  }
}
