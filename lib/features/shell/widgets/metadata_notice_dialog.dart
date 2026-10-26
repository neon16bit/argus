import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/features/settings/widgets/tvdb_settings_section.dart';

const _kMetadataNoticeSeenKey = 'has_seen_metadata_notice';

void showMetadataNoticeDialogIfNeeded(BuildContext context, WidgetRef ref) {
  final isFdroid = ref.read(settingsProvider).isFdroidBuild;
  if (!isFdroid) return;

  final tvdb = ref.read(tvdbProvider);
  if (tvdb.isConfigured) return;

  final prefs = ref.read(sharedPreferencesProvider);
  final hasSeen = prefs.getBool(_kMetadataNoticeSeenKey) ?? false;
  if (hasSeen) return;

  prefs.setBool(_kMetadataNoticeSeenKey, true);

  showDialog(context: context, builder: (ctx) => const _MetadataNoticeDialog());
}

class _MetadataNoticeDialog extends ConsumerWidget {
  const _MetadataNoticeDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      actionsOverflowButtonSpacing: 8,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Metadata in Argus')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Argus indexes open directories and streams media. To display posters, backdrops, and episode details, it pulls information from Simkl, Anilist and TheTVDB.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TheTVDB API Key (F-Droid Build)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'F-Droid builds do not bundle proprietary API keys. You can add your free TheTVDB key for poster artwork and episode guides.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse('https://thetvdb.com/dashboard/account/apikey'),
                      mode: LaunchMode.externalApplication,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can also link your Simkl account anytime in Settings to fetch metadata and sync your watch history and tracking.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Alternatively, you can download the release from GitHub, which includes all necessary API keys.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe Later'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            showTvdbKeyDialog(context, ref);
          },
          icon: const Icon(Icons.key_rounded, size: 16),
          label: const Text('Set Up Key'),
        ),
      ],
    );
  }
}
