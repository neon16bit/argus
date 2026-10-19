import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:argus/core/providers/providers.dart';

class SimklSyncSection extends ConsumerWidget {
  const SimklSyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simklAuth = ref.watch(simklAuthProvider);
    final simklService = ref.read(simklAuthProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!simklAuth.isAuthenticated) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sync_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect Simkl Account',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track watched episodes & movies to your Simkl profile',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (simklAuth.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  simklAuth.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: simklAuth.isConnecting
                      ? null
                      : () async {
                          final success = await simklService.login();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Connected to Simkl as ${ref.read(simklAuthProvider).user?.name ?? "User"}',
                                ),
                              ),
                            );
                          }
                        },
                  icon: simklAuth.isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded, size: 18),
                  label: Text(
                    simklAuth.isConnecting
                        ? 'Waiting for browser approval...'
                        : 'Sign in with Simkl',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = simklAuth.user;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                  backgroundImage: user?.avatarUrl != null
                      ? CachedNetworkImageProvider(user!.avatarUrl!)
                      : null,
                  onBackgroundImageError: user?.avatarUrl != null
                      ? (_, _) {}
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          (user != null && user.name.isNotEmpty)
                              ? user.name[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Simkl User',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.greenAccent.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Connected to Simkl',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Disconnect',
                  icon: const Icon(Icons.logout_rounded),
                  color: colorScheme.error,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Disconnect Simkl?'),
                        content: const Text(
                          'Argus will stop syncing your watch progress with Simkl.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Disconnect'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await simklService.logout();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Sync watch progress'),
          subtitle: const Text(
            'Automatically mark episodes as watched on Simkl when finished or marked',
          ),
          value: simklAuth.autoSync,
          onChanged: (v) => simklService.setAutoSync(v),
        ),
        ListTile(
          leading: const Icon(Icons.sync_rounded),
          title: const Text('Sync watch history now'),
          subtitle: const Text(
            'Push all locally watched episodes to your Simkl account',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Syncing watch history to Simkl...'),
                duration: Duration(seconds: 2),
              ),
            );
            final count = await ref
                .read(simklSyncServiceProvider)
                .syncAllWatchedHistory();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    count > 0
                        ? 'Successfully synced $count items to Simkl!'
                        : 'Simkl is up to date (no new items to sync).',
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
