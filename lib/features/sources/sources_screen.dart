import 'package:flutter/material.dart';
import 'package:argus/features/sources/widgets/source_tile.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen> {
  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(sourcesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sources')),
      body: sources.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sources.length,
              itemBuilder: (context, index) {
                return SourceTile(
                  source: sources[index],
                  onDelete: () {
                    ref.read(sourcesProvider.notifier).removeSourceAt(index);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Movies Folder',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'http://ftp.example.com/',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final url = urlController.text.trim();
              if (name.isEmpty || url.isEmpty) return;

              Navigator.pop(ctx);
              ref
                  .read(sourcesProvider.notifier)
                  .addSource(Source(name: name, baseUrl: url));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
