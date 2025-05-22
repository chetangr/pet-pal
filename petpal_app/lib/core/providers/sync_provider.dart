import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/services/sync_service.dart';
import 'package:petpal/core/services/supabase_service.dart';
import 'package:petpal/core/services/local_storage_service.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);
  
  return SyncService(
    supabaseService: supabaseService,
    localStorageService: localStorageService,
  );
});

/// Provider for the current sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  
  // Initialize sync service on first access
  ref.onDispose(() {
    syncService.dispose();
  });
  
  // Get sync status stream
  return syncService.syncStatusStream;
});

/// Provider for triggering synchronization
final syncProvider = Provider<Future<bool> Function()>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  
  return () => syncService.syncNow();
});