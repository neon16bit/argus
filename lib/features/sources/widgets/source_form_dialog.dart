import 'package:flutter/material.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/core/constants.dart';

class SourceFormDialog extends StatefulWidget {
  final Source? source;
  final Future<String?> Function(
    String name,
    String url,
    int maxDepth,
    bool autoScrape,
    int? requestDelayMs,
  )
  onSave;

  const SourceFormDialog({super.key, this.source, required this.onSave});

  @override
  State<SourceFormDialog> createState() => _SourceFormDialogState();
}

class _SourceFormDialogState extends State<SourceFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late int _selectedDepth;
  late bool _autoScrape;
  int? _requestDelayMs;
  bool _urlModified = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.source?.name ?? '');
    _urlController = TextEditingController(text: widget.source?.baseUrl ?? '');
    _selectedDepth = widget.source?.maxDepth ?? kFlatScrapeDepth;
    _autoScrape = widget.source?.autoScrape ?? false;
    _requestDelayMs = widget.source?.requestDelayMs;

    if (widget.source != null) {
      _urlController.addListener(_checkIfModified);
    }
  }

  void _checkIfModified() {
    if (widget.source == null) return;
    final urlChanged = _urlController.text.trim() != widget.source!.baseUrl;
    final depthChanged = _selectedDepth != widget.source!.maxDepth;
    final modified = urlChanged || depthChanged;
    if (modified != _urlModified) {
      setState(() {
        _urlModified = modified;
      });
    }
  }

  @override
  void dispose() {
    if (widget.source != null) {
      _urlController.removeListener(_checkIfModified);
    }
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.source != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Source' : 'Add Source'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Movies Folder',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'http://ftp.example.com/',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Grouped structure'),
                subtitle: const Text('Nested by year or letter (e.g. /2010/)'),
                value: _selectedDepth == kGroupedScrapeDepth,
                onChanged: (bool val) {
                  setState(() {
                    _selectedDepth = val
                        ? kGroupedScrapeDepth
                        : kFlatScrapeDepth;
                  });
                  _checkIfModified();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-index on search'),
                subtitle: const Text(
                  'Only enable for sources you own or that won\'t rate-limit you',
                  style: TextStyle(fontSize: 11),
                ),
                value: _autoScrape,
                onChanged: (bool val) {
                  setState(() {
                    _autoScrape = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _requestDelayMs,
                decoration: const InputDecoration(
                  labelText: 'Request delay',
                  helperText: 'Override global delay for this source',
                  helperMaxLines: 2,
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Default (Global)'),
                  ),
                  DropdownMenuItem(value: 0, child: Text('0ms (None)')),
                  DropdownMenuItem(value: 100, child: Text('100ms')),
                  DropdownMenuItem(value: 250, child: Text('250ms')),
                  DropdownMenuItem(value: 500, child: Text('500ms')),
                  DropdownMenuItem(value: 1000, child: Text('1s')),
                  DropdownMenuItem(value: 2000, child: Text('2s')),
                  DropdownMenuItem(value: 3000, child: Text('3s')),
                  DropdownMenuItem(value: 5000, child: Text('5s')),
                ],
                onChanged: (val) {
                  setState(() {
                    _requestDelayMs = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Expected folder structure:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  _selectedDepth == kFlatScrapeDepth
                      ? 'root/\n└── [Show or Movie Folder]/'
                            '\n└── [Show or Movie Folder]/'
                      : 'root/\n└── [Year / Alphabet Group]/'
                            '\n     └── [Show or Movie Folder]/'
                            '\n     └── [Show or Movie Folder]/'
                            '\n└── [Year / Alphabet Group]/'
                            '\n     └── [Show or Movie Folder]/'
                            '\n     └── [Show or Movie Folder]/',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_urlModified) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Changing the URL or folder structure will reset scrape state and delete all indexed items from this source.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            final url = _urlController.text.trim();
            if (name.isEmpty || url.isEmpty) return;

            Navigator.pop(context);
            final messenger = ScaffoldMessenger.of(context);
            final warning = await widget.onSave(
              name,
              url,
              _selectedDepth,
              _autoScrape,
              _requestDelayMs,
            );
            if (context.mounted && warning != null) {
              messenger.showSnackBar(SnackBar(content: Text(warning)));
            }
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
