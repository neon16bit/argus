import 'package:flutter/material.dart';

class PlayerCenterControls extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay10;
  final VoidCallback onForward10;

  const PlayerCenterControls({
    super.key,
    required this.isPlaying,
    required this.isBuffering,
    required this.onPlayPause,
    required this.onReplay10,
    required this.onForward10,
  });

  @override
  Widget build(BuildContext context) {
    if (isBuffering) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 44,
            icon: const Icon(Icons.replay_10_rounded, color: Colors.white70),
            onPressed: onReplay10,
          ),
          const SizedBox(width: 24),
          Material(
            color: Colors.black45,
            shape: const CircleBorder(),
            child: IconButton(
              iconSize: 64,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
              ),
              onPressed: onPlayPause,
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            iconSize: 44,
            icon: const Icon(Icons.forward_10_rounded, color: Colors.white70),
            onPressed: onForward10,
          ),
        ],
      ),
    );
  }
}

class PlayerHud extends StatelessWidget {
  final bool isHolding2x;
  final int accumulatedSeekSeconds;
  final bool isBuffering;
  final bool controlsVisible;
  final BoxConstraints constraints;
  final bool isAdjustingVolume;
  final double volume;

  const PlayerHud({
    super.key,
    required this.isHolding2x,
    required this.accumulatedSeekSeconds,
    required this.isBuffering,
    required this.controlsVisible,
    required this.constraints,
    this.isAdjustingVolume = false,
    this.volume = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isHolding2x)
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '2X',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.fast_forward_rounded,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (accumulatedSeekSeconds != 0)
          Positioned.fill(
            child: Align(
              alignment: accumulatedSeekSeconds < 0
                  ? const Alignment(-0.65, 0.0)
                  : const Alignment(0.65, 0.0),
              child: Text(
                '${accumulatedSeekSeconds > 0 ? '+' : ''}${accumulatedSeekSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (isBuffering)
          const Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),

        if (isAdjustingVolume)
          Positioned(
            right: constraints.maxWidth < 600 ? 24 : 48,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 160,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      volume <= 0
                          ? Icons.volume_off_rounded
                          : volume < 50
                          ? Icons.volume_down_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (volume / 100.0).clamp(0.0, 1.0),
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${volume.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
