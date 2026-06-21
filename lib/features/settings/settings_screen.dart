import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:argus/core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Full scrape mode'),
                  subtitle: const Text(
                    'Recursively scrape all files on source index. '
                    'Slower but indexes everything upfront.',
                  ),
                  value: settings.fullScrapeMode,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setFullScrapeMode(v),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Request delay'),
                  subtitle: Text(
                    '${settings.scrapeDelay.inMilliseconds}ms between requests '
                    '(reduces rate-limiting risk)',
                  ),
                ),
                Slider(
                  value: settings.scrapeDelay.inMilliseconds.toDouble(),
                  min: 0,
                  max: 1000,
                  divisions: 10,
                  label: '${settings.scrapeDelay.inMilliseconds}ms',
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setScrapeDelay(Duration(milliseconds: v.toInt())),
                ),
              ],
            ),
    );
  }
}
