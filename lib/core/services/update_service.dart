import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/core/providers/settings_provider.dart';

const _kLastDismissedUpdateKey = 'last_dismissed_update_version';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String? changelog;
  final bool isFdroid;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    this.changelog,
    required this.isFdroid,
  });
}

class UpdateService {
  static const _githubRepo = 'neon16bit/argus';
  static const _packageName = 'me.neon16bit.argus';

  static bool isVersionNewer(String latest, String current) {
    final cleanLatest = latest.replaceFirst(RegExp(r'^[^\d]*'), '');
    final cleanCurrent = current.replaceFirst(RegExp(r'^[^\d]*'), '');

    final latestCore = cleanLatest.split(RegExp(r'[-+]')).first;
    final currentCore = cleanCurrent.split(RegExp(r'[-+]')).first;

    final lParts = latestCore
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final cParts = currentCore
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    final maxLen = lParts.length > cParts.length
        ? lParts.length
        : cParts.length;
    for (int i = 0; i < maxLen; i++) {
      final l = i < lParts.length ? lParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static Future<AppUpdateInfo?> checkForUpdate({
    required String currentVersion,
    required int currentVersionCode,
    required bool isFdroid,
  }) async {
    if (isFdroid) {
      return _checkFdroid(currentVersion, currentVersionCode);
    } else {
      return _checkGithub(currentVersion);
    }
  }

  static Future<AppUpdateInfo?> _checkGithub(String currentVersion) async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_githubRepo/releases/latest',
      );
      final res = await http
          .get(
            url,
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'Argus-App',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['draft'] == true || data['prerelease'] == true) return null;

      final latestTag = (data['tag_name'] as String? ?? '').replaceFirst(
        'v',
        '',
      );
      final releaseUrl =
          data['html_url'] as String? ??
          'https://github.com/$_githubRepo/releases';
      final changelog = data['body'] as String?;

      final hasUpdate = isVersionNewer(latestTag, currentVersion);

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: latestTag,
        releaseUrl: releaseUrl,
        changelog: changelog,
        isFdroid: false,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<AppUpdateInfo?> _checkFdroid(
    String currentVersion,
    int currentVersionCode,
  ) async {
    try {
      final url = Uri.parse(
        'https://f-droid.org/api/v1/packages/$_packageName',
      );
      final res = await http
          .get(
            url,
            headers: {'Accept': 'application/json', 'User-Agent': 'Argus-App'},
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final packages = data['packages'] as List<dynamic>?;

      if (packages == null || packages.isEmpty) return null;

      final latestPkg = packages.first as Map<String, dynamic>;
      final latestCode = latestPkg['versionCode'] as int? ?? 0;
      final latestName = (latestPkg['versionName'] as String? ?? '')
          .replaceFirst('v', '');

      final hasUpdate =
          latestCode > currentVersionCode ||
          isVersionNewer(latestName, currentVersion);

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: latestName.isNotEmpty ? latestName : '$latestCode',
        releaseUrl: 'https://f-droid.org/packages/$_packageName/',
        isFdroid: true,
      );
    } catch (_) {
      return null;
    }
  }
}

Future<void> showAppUpdateDialog(
  BuildContext context,
  WidgetRef ref,
  AppUpdateInfo update,
) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _AppUpdateDialog(update: update),
  );
}

class _AppUpdateDialog extends ConsumerWidget {
  final AppUpdateInfo update;

  const _AppUpdateDialog({required this.update});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Update Available: v${update.latestVersion}'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              'Current: v${update.currentVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (update.changelog != null &&
                  update.changelog!.trim().isNotEmpty) ...[
                Text(
                  'What\'s New',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  update.changelog!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final prefs = ref.read(sharedPreferencesProvider);
            prefs.setString(_kLastDismissedUpdateKey, update.latestVersion);
            Navigator.of(context).pop();
          },
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            launchUrl(
              Uri.parse(update.releaseUrl),
              mode: LaunchMode.externalApplication,
            );
            Navigator.of(context).pop();
          },
          child: Text(update.isFdroid ? 'Open F-Droid' : 'View Release'),
        ),
      ],
    );
  }
}

Future<void> checkAppUpdateOnLaunchIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;

    final packageInfo = ref.read(packageInfoProvider);
    final isFdroid = ref.read(settingsProvider).isFdroidBuild;
    final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;

    final update = await UpdateService.checkForUpdate(
      currentVersion: packageInfo.version,
      currentVersionCode: currentCode,
      isFdroid: isFdroid,
    );

    if (update == null || !update.hasUpdate || !context.mounted) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final lastDismissed = prefs.getString(_kLastDismissedUpdateKey);

    if (lastDismissed == update.latestVersion) return;

    if (context.mounted) {
      await showAppUpdateDialog(context, ref, update);
    }
  } catch (_) {}
}
