import 'dart:async';
import 'package:flutter/material.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/data/scrapers/directory_scraper.dart';
import 'package:argus/core/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScrapeProgressSheet extends ConsumerStatefulWidget {
  final SourceActions sourceActions;
  final Source source;
  final void Function(int count) onDone;
  final void Function(String error) onError;

  final int maxDepth;

  const ScrapeProgressSheet({
    super.key,
    required this.sourceActions,
    required this.source,
    required this.onDone,
    required this.onError,
    this.maxDepth = kFlatScrapeDepth,
  });

  @override
  ConsumerState<ScrapeProgressSheet> createState() =>
      _ScrapeProgressSheetState();
}

class _ScrapeProgressSheetState extends ConsumerState<ScrapeProgressSheet> {
  ScrapeProgress? _progress;
  bool _isDone = false;
  StreamSubscription<ScrapeProgress>? _subscription;

  @override
  void initState() {
    super.initState();
    _startScraping();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startScraping() {
    final fullScrape =
        ref.read(settingsProvider).value?.fullScrapeMode ?? false;
    _subscription = widget.sourceActions
        .scrapeSourceWithProgress(
          widget.source,
          fullScrape: fullScrape,
          maxDepth: widget.maxDepth,
        )
        .listen(
          (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);

            if (progress.isDone) {
              setState(() => _isDone = true);
              widget.onDone(progress.filesFound);
            }
          },
          onError: (e) {
            if (mounted) {
              setState(() => _isDone = true);
              widget.onError(e.toString());
            }
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (!_isDone)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (_isDone)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isDone ? 'Scraping complete' : 'Scraping...',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats
          if (p != null)
            Row(
              children: [
                _StatChip(Icons.language, '${p.urlsVisited} pages'),
                const SizedBox(width: 8),
                _StatChip(Icons.queue, '${p.urlsQueued} queued'),
                const SizedBox(width: 8),
                _StatChip(Icons.movie, '${p.filesFound} files'),
              ],
            ),
          const SizedBox(height: 16),

          // Current URL
          if (p?.currentUrl != null && !_isDone)
            Text(
              p!.currentUrl!,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
