import 'package:flutter/material.dart';

class PlayerTopBar extends StatelessWidget {
  final String? title;
  final VoidCallback onBack;
  final VoidCallback onAudio;
  final VoidCallback onSubtitles;
  final VoidCallback onSpeed;
  final VoidCallback onOpenExternal;
  final VoidCallback? onSolveChallenge;
  final VoidCallback? onMenuOpened;
  final VoidCallback? onMenuClosed;

  const PlayerTopBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onAudio,
    required this.onSubtitles,
    required this.onSpeed,
    required this.onOpenExternal,
    this.onSolveChallenge,
    this.onMenuOpened,
    this.onMenuClosed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.audiotrack_rounded, color: Colors.white),
            tooltip: 'Audio Tracks',
            onPressed: onAudio,
          ),
          IconButton(
            icon: const Icon(Icons.subtitles_rounded, color: Colors.white),
            tooltip: 'Subtitles',
            onPressed: onSubtitles,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            tooltip: 'More options',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            onOpened: onMenuOpened,
            onCanceled: onMenuClosed,
            onSelected: (value) {
              onMenuClosed?.call();
              switch (value) {
                case 'speed':
                  onSpeed();
                  break;
                case 'webview':
                  onSolveChallenge?.call();
                  break;
                case 'external':
                  onOpenExternal();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'speed',
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Playback Speed'),
                  ],
                ),
              ),
              if (onSolveChallenge != null)
                const PopupMenuItem<String>(
                  value: 'webview',
                  child: Row(
                    children: [
                      Icon(Icons.language_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Open in WebView'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'external',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Open in External Player'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
