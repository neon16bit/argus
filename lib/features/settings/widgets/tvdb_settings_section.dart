import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/data/remote/metadata/tvdb_provider.dart';

class TvdbSettingsSection extends ConsumerWidget {
  const TvdbSettingsSection({super.key});

  String _maskKey(String key) {
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  void _showConfigureDialog(BuildContext context, WidgetRef ref) {
    showTvdbKeyDialog(context, ref);
  }

  void _showClearConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Custom Key?'),
        content: Text(
          TvdbProvider.hasDefaultKey
              ? 'Revert to using the application built-in API key.'
              : 'Remove your custom key. TheTVDB artwork will no longer load until a new key is provided.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).clearTvdbApiKey();
              Navigator.of(ctx).pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final tvdb = ref.watch(tvdbProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final isCustom = tvdb.isCustomKey;
    final isFdroid = settings.isFdroidBuild;

    String subtitle;
    Color? subtitleColor;

    if (isCustom) {
      subtitle = 'Custom (${_maskKey(settings.tvdbApiKey)})';
    } else if (isFdroid) {
      subtitle = 'Not configured (F-Droid build) • Tap to set key';
      subtitleColor = colorScheme.error;
    } else {
      subtitle = 'Using built-in key';
    }

    return ListTile(
      leading: Icon(
        Icons.movie_filter_rounded,
        color: !isCustom && isFdroid ? colorScheme.error : null,
      ),
      title: const Text('TheTVDB API Key'),
      subtitle: Text(
        subtitle,
        style: subtitleColor != null ? TextStyle(color: subtitleColor) : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCustom)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              tooltip: 'Remove custom key',
              onPressed: () => _showClearConfirm(context, ref),
            ),
        ],
      ),
      onTap: () => _showConfigureDialog(context, ref),
    );
  }
}

void showTvdbKeyDialog(BuildContext context, WidgetRef ref) {
  final settings = ref.read(settingsProvider);
  showDialog(
    context: context,
    builder: (ctx) => TvdbKeyDialog(initialKey: settings.tvdbApiKey),
  );
}

class TvdbKeyDialog extends ConsumerStatefulWidget {
  final String initialKey;

  const TvdbKeyDialog({super.key, required this.initialKey});

  @override
  ConsumerState<TvdbKeyDialog> createState() => _TvdbKeyDialogState();
}

class _TvdbKeyDialogState extends ConsumerState<TvdbKeyDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save({bool testFirst = true}) async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      await ref.read(settingsProvider.notifier).clearTvdbApiKey();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (testFirst) {
      setState(() {
        _isTesting = true;
        _errorMessage = null;
      });

      final tvdb = ref.read(tvdbProvider);
      final (success, error) = await tvdb.testConnection(testApiKey: key);

      if (!mounted) return;
      setState(() => _isTesting = false);

      if (!success) {
        setState(() => _errorMessage = error ?? 'Invalid API key');
        return;
      }
    }

    await ref.read(settingsProvider.notifier).setTvdbApiKey(key);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('TheTVDB API key saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      actionsOverflowButtonSpacing: 8,
      title: const Text('TheTVDB API Key'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'Paste key here',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('https://thetvdb.com/dashboard/account/apikey'),
              mode: LaunchMode.externalApplication,
            ),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Get an API key at thetvdb.com',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_errorMessage != null)
          TextButton(
            onPressed: () => _save(testFirst: false),
            child: const Text('Save Anyway'),
          ),
        FilledButton(
          onPressed: _isTesting ? null : () => _save(testFirst: true),
          child: _isTesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
