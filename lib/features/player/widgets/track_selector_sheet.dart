import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class TrackSelectorSheet {
  static void showSubtitleSelector({
    required BuildContext context,
    required Player player,
    required VoidCallback onClosed,
  }) {
    final theme = Theme.of(context);
    final userTracks = player.state.tracks.subtitle
        .where((t) => t.id != 'no' && t.id != 'auto')
        .toList();
    final current = player.state.track.subtitle;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Subtitles', style: theme.textTheme.titleMedium),
                ),
                ListTile(
                  leading: Icon(
                    Icons.subtitles_off_rounded,
                    color: current.id == 'no'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text('Off', style: theme.textTheme.bodyMedium),
                  trailing: current.id == 'no'
                      ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    player.setSubtitleTrack(SubtitleTrack.no());
                    Navigator.pop(ctx);
                    onClosed();
                  },
                ),
                ...userTracks.map((track) {
                  final isSelected = track.id == current.id ||
                      (current.id == 'auto' && track == userTracks.first);
                  final label = track.title ?? track.language ?? 'Track ${track.id}';
                  return ListTile(
                    leading: Icon(
                      Icons.subtitles_rounded,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(label, style: theme.textTheme.bodyMedium),
                    subtitle: track.language != null && track.title != null
                        ? Text(track.language!, style: theme.textTheme.labelSmall)
                        : null,
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      player.setSubtitleTrack(track);
                      Navigator.pop(ctx);
                      onClosed();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showAudioSelector({
    required BuildContext context,
    required Player player,
    required VoidCallback onClosed,
  }) {
    final theme = Theme.of(context);
    final userTracks = player.state.tracks.audio
        .where((t) => t.id != 'no' && t.id != 'auto')
        .toList();
    final current = player.state.track.audio;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Audio Tracks',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                ...userTracks.map((track) {
                  final isSelected =
                      track.id == current.id ||
                      (current.id == 'auto' && track == userTracks.first);
                  final label =
                      track.title ?? track.language ?? 'Track ${track.id}';
                  return ListTile(
                    leading: Icon(
                      Icons.audiotrack_rounded,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(label, style: theme.textTheme.bodyMedium),
                    subtitle: track.channels != null
                        ? Text(
                            '${track.channels} channels',
                            style: theme.textTheme.labelSmall,
                          )
                        : null,
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      player.setAudioTrack(track);
                      Navigator.pop(ctx);
                      onClosed();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showSpeedSelector({
    required BuildContext context,
    required double currentRate,
    required ValueChanged<double> onRateSelected,
  }) {
    final theme = Theme.of(context);
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Playback Speed',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                ...speeds.map((speed) {
                  final isSelected = (currentRate - speed).abs() < 0.05;
                  return ListTile(
                    title: Text('${speed}x', style: theme.textTheme.bodyMedium),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      onRateSelected(speed);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
