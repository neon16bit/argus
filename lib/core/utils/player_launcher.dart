import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/core/providers/settings_provider.dart';
import 'package:argus/features/player/video_player_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayerLauncher {
  PlayerLauncher._();

  static Future<void> playMedia(
    BuildContext context,
    WidgetRef ref, {
    required String url,
    String? title,
    String? groupTitle,
    int? season,
    int? episode,
    int? mediaItemId,
    bool forceExternal = false,
    bool forceInApp = false,
  }) async {
    final useExternal = ref.read(settingsProvider).useExternalPlayer;
    final shouldOpenExternal = forceExternal || (useExternal && !forceInApp);

    if (shouldOpenExternal) {
      await launchExternalPlayer(
        context,
        ref,
        url: url,
        title: title,
        groupTitle: groupTitle,
        season: season,
        episode: episode,
        mediaItemId: mediaItemId,
      );
    } else {
      playInApp(
        context,
        url: url,
        title: title,
        groupTitle: groupTitle,
        season: season,
        episode: episode,
        mediaItemId: mediaItemId,
      );
    }
  }

  static void playInApp(
    BuildContext context, {
    required String url,
    String? title,
    String? groupTitle,
    int? season,
    int? episode,
    int? mediaItemId,
  }) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          url: url,
          title: title,
          groupTitle: groupTitle,
          season: season,
          episode: episode,
          mediaItemId: mediaItemId,
        ),
      ),
    );
  }

  static Future<void> launchExternalPlayer(
    BuildContext context,
    WidgetRef ref, {
    required String url,
    String? title,
    String? groupTitle,
    int? season,
    int? episode,
    int? mediaItemId,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // update last watched
    if (groupTitle != null && groupTitle.isNotEmpty) {
      final db = ref.read(databaseProvider);
      final existing = await db.getPlaybackProgress(
        groupTitle,
        season: season,
        episode: episode,
        streamUrl: url,
      );

      db.savePlaybackProgress(
        groupTitle: groupTitle,
        mediaItemId: mediaItemId ?? existing?.mediaItemId,
        season: season,
        episode: episode,
        episodeTitle: title ?? existing?.episodeTitle,
        streamUrl: url,
        positionMs: existing?.positionMs ?? 0,
        durationMs: existing?.durationMs ?? 0,
        isCompleted: existing?.isCompleted,
      );
    }

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'action_view',
          data: url,
          type: 'video/*',
        );
        await intent.launch();
      } else {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch URL';
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to open external player. Play in app or copy the link instead.',
          ),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
            },
          ),
        ),
      );
    }
  }
}
