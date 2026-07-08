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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sources'),
        actions: [
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
      body: sourcesAsync.when(
        data: (sources) {
          if (sources.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dns_rounded, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text('No sources yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Add an open directory URL to get started',
                    style: TextStyle(color: Colors.grey),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add_rounded),
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
