import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:argus/features/shell/app_shell.dart';

final imageCacheSizeProvider = FutureProvider.autoDispose<int>((ref) async {
  int totalBytes = 0;
  final checkedPaths = <String>{};
  final candidateDirs = <Directory>[];

  try {
    final tempDir = await getTemporaryDirectory();
    candidateDirs.add(Directory(p.join(tempDir.path, 'libCachedImageData')));
  } catch (_) {}

  try {
    final appCache = await getApplicationCacheDirectory();
    candidateDirs.add(Directory(p.join(appCache.path, 'libCachedImageData')));
  } catch (_) {}

  try {
    final appSupport = await getApplicationSupportDirectory();
    candidateDirs.add(Directory(p.join(appSupport.path, 'libCachedImageData')));
  } catch (_) {}

  for (final dir in candidateDirs) {
    if (checkedPaths.add(dir.path) && await dir.exists()) {
      try {
        await for (final file in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (file is File) {
            totalBytes += await file.length();
          }
        }
      } catch (_) {}
    }
  }

  final memoryBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
  return totalBytes > 0 ? totalBytes : memoryBytes;
});

class StorageCacheSection extends ConsumerWidget {
  const StorageCacheSection({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor().clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(size >= 100 || i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  Future<void> _purgeImageCache(BuildContext context, WidgetRef ref) async {
    ref.invalidate(imageCacheSizeProvider);
    final cacheSize = await ref.read(imageCacheSizeProvider.future);
    if (!context.mounted) return;

    final sizeNotice = cacheSize > 0 ? ' (${_formatBytes(cacheSize)})' : '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purge image cache?'),
        content: Text(
          'This will delete all$sizeNotice cached posters, backdrops, fanart, and avatars from disk and memory. Images will be re-downloaded when viewed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await DefaultCacheManager().emptyCache();

        ref.invalidate(imageCacheSizeProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image cache purged successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to purge cache: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheSizeAsync = ref.watch(imageCacheSizeProvider);
    final cacheSizeStr = cacheSizeAsync.when(
      data: (bytes) => _formatBytes(bytes),
      loading: () => 'Calculating...',
      error: (_, _) => 'Unknown',
    );

    ref.listen(navigationIndexProvider, (prev, next) {
      if (next == 3) {
        ref.invalidate(imageCacheSizeProvider);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Storage & Cache',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services_rounded),
          title: const Text('Purge image cache'),
          subtitle: Text(
            cacheSizeAsync.isLoading
                ? 'Calculating cache size...'
                : 'Current size: $cacheSizeStr • Tap to free up space',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cacheSizeAsync.isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                Text(
                  cacheSizeStr,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Recalculate cache size',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref.invalidate(imageCacheSizeProvider),
                ),
              ],
            ],
          ),
          onTap: () => _purgeImageCache(context, ref),
        ),
      ],
    );
  }
}
