import 'package:flutter/material.dart';

class PlayerTopBar extends StatelessWidget {
  final String? title;
  final VoidCallback onBack;
  final VoidCallback onAudio;
  final VoidCallback onSubtitles;
  final VoidCallback onSpeed;
  final VoidCallback onOpenExternal;

  const PlayerTopBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onAudio,
    required this.onSubtitles,
    required this.onSpeed,
    required this.onOpenExternal,
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
          IconButton(
            icon: const Icon(Icons.speed_rounded, color: Colors.white),
            tooltip: 'Playback Speed',
            onPressed: onSpeed,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
            tooltip: 'Open in External Player',
            onPressed: onOpenExternal,
          ),
        ],
      ),
    );
  }
}
