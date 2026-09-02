import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class PlayerBottomBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final bool isSeeking;
  final Duration seekPosition;
  final ValueChanged<Duration> onSeekStart;
  final ValueChanged<Duration> onSeekChanged;
  final ValueChanged<Duration> onSeekEnd;
  final double volume;
  final bool isMuted;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;
  final double playbackRate;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  const PlayerBottomBar({
    super.key,
    required this.position,
    required this.duration,
    required this.isSeeking,
    required this.seekPosition,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.volume,
    required this.isMuted,
    required this.onVolumeChanged,
    required this.onToggleMute,
    required this.playbackRate,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    final currentPos = isSeeking ? seekPosition : position;
    final totalMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 0;
    final clampedPosMs = currentPos.inMilliseconds.clamp(0, totalMs).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrubber row
          Row(
            children: [
              Text(
                _formatDuration(currentPos),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: theme.colorScheme.primary,
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: clampedPosMs,
                    min: 0,
                    max: totalMs.toDouble(),
                    onChangeStart: (_) => onSeekStart(position),
                    onChanged: (val) =>
                        onSeekChanged(Duration(milliseconds: val.toInt())),
                    onChangeEnd: (val) =>
                        onSeekEnd(Duration(milliseconds: val.toInt())),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),

          Row(
            children: [
              if (isDesktop) ...[
                IconButton(
                  icon: Icon(
                    isMuted || volume == 0
                        ? Icons.volume_off_rounded
                        : (volume < 50
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded),
                    color: Colors.white,
                  ),
                  onPressed: onToggleMute,
                ),
                SizedBox(
                  width: 150,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: theme.colorScheme.primary,
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4,
                      ),
                    ),
                    child: Slider(
                      value: volume,
                      min: 0,
                      max: 100,
                      onChanged: onVolumeChanged,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (playbackRate != 1.0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${playbackRate}x',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              if (isDesktop)
                IconButton(
                  icon: Icon(
                    isFullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: Colors.white,
                  ),
                  tooltip: isFullscreen
                      ? 'Exit Fullscreen (F)'
                      : 'Fullscreen (F)',
                  onPressed: onToggleFullscreen,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
