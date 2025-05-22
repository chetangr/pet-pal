import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/services/sync_service.dart';
import 'package:petpal/core/providers/sync_provider.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Return appropriate widget based on sync status
    switch (syncStatus) {
      case SyncStatus.syncing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Syncing...',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      
      case SyncStatus.synced:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 12,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'All changes synced',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      
      case SyncStatus.offline:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 12,
              color: colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Offline mode',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      
      case SyncStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 12,
              color: colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Sync error',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      
      case SyncStatus.authError:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 12,
              color: colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Authentication error',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_done,
              size: 12,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'Ready to sync',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
    }
  }
}