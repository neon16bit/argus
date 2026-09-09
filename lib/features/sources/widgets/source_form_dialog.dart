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
  late final TextEditingController _delayController;
  late String _delayUnit;
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
    final initialDelay = widget.source?.requestDelayMs;
    _requestDelayMs = initialDelay;
    if (initialDelay != null &&
        initialDelay >= 1000 &&
        initialDelay % 1000 == 0) {
      _delayUnit = 's';
      _delayController = TextEditingController(text: '${initialDelay ~/ 1000}');
    } else {
      _delayUnit = 'ms';
      _delayController = TextEditingController(text: '${initialDelay ?? 250}');
    }

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

  void _parseDelayInput(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _requestDelayMs = 0;
      return;
    }
    final val = num.tryParse(trimmed);
    if (val != null) {
      _requestDelayMs = _delayUnit == 's' ? (val * 1000).round() : val.toInt();
    }
  }

  void _switchDelayUnit(String newUnit) {
    if (newUnit == _delayUnit) return;
    setState(() {
      _delayUnit = newUnit;
      if (newUnit == 's') {
        final s = _requestDelayMs! / 1000.0;
        _delayController.text = s.toStringAsFixed(
          s.truncateToDouble() == s ? 0 : 2,
        );
      } else {
        _delayController.text = '$_requestDelayMs';
      }
    });
  }

  @override
  void dispose() {
    if (widget.source != null) {
      _urlController.removeListener(_checkIfModified);
    }
    _nameController.dispose();
    _urlController.dispose();
    _delayController.dispose();
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
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'http://ftp.example.com/',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default request delay'),
                subtitle: Text(
                  _requestDelayMs == null
                      ? 'Using global delay setting'
                      : 'Override global delay for this source',
                  style: const TextStyle(fontSize: 11),
                ),
                value: _requestDelayMs == null,
                onChanged: (bool useDefault) {
                  setState(() {
                    if (useDefault) {
                      _requestDelayMs = null;
                    } else {
                      _requestDelayMs = 250;
                      _delayUnit = 'ms';
                      _delayController.text = '250';
                    }
                  });
                },
              ),
              if (_requestDelayMs != null) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _delayController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: _delayUnit == 's' ? '0.25' : '250',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: _parseDelayInput,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 0.8,
                        ),
                      ),
                      segments: const [
                        ButtonSegment(value: 'ms', label: Text('ms')),
                        ButtonSegment(value: 's', label: Text('s')),
                      ],
                      selected: {_delayUnit},
                      onSelectionChanged: (newSet) {
                        _switchDelayUnit(newSet.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Grouped structure'),
                subtitle: const Text(
                  'Nested by year or letter (e.g. /2010/)',
                  style: TextStyle(fontSize: 11),
                ),
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
              const SizedBox(height: 8),
              const Text(
                'Expected directory structure:',
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
                            '\n     └── [Show or Movie Folder]/',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              if (_urlModified) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Changing the URL or folder structure will reset scrape state and delete all indexed items from this source.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.tertiary,
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

            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            final warning = await widget.onSave(
              name,
              url,
              _selectedDepth,
              _autoScrape,
              _requestDelayMs,
            );
            if (messenger.mounted && warning != null) {
              messenger.showSnackBar(SnackBar(content: Text(warning)));
            }
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
