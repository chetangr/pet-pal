import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petpal/core/services/supabase_service.dart';
import 'package:petpal/core/services/local_storage_service.dart';
import 'package:petpal/config/app_config.dart';

/// Service responsible for data synchronization between local storage and Supabase
class SyncService {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription? _connectivitySubscription;
  Timer? _syncTimer;
  bool _syncInProgress = false;
  
  final _syncSubject = StreamController<SyncStatus>.broadcast();
  
  /// Stream that emits the current sync status
  Stream<SyncStatus> get syncStatusStream => _syncSubject.stream;
  
  /// Current sync status
  SyncStatus _syncStatus = SyncStatus.idle;
  SyncStatus get syncStatus => _syncStatus;
  
  SyncService({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
  })  : _supabaseService = supabaseService,
        _localStorageService = localStorageService;
  
  /// Initialize the sync service
  void init() {
    // Monitor connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Set up periodic sync
    _setupPeriodicSync();
    
    // Perform initial sync if online
    _checkConnectivityAndSync();
  }
  
  /// Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      // We're online, trigger a sync
      syncNow();
    } else {
      // We're offline, update status
      _updateSyncStatus(SyncStatus.offline);
    }
  }
  
  /// Set up periodic sync based on app config
  void _setupPeriodicSync() {
    // Cancel existing timer if any
    _syncTimer?.cancel();
    
    // Create new timer
    _syncTimer = Timer.periodic(
      Duration(minutes: AppConfig.syncIntervalMinutes),
      (_) => _checkConnectivityAndSync(),
    );
  }
  
  /// Check connectivity and sync if online
  Future<void> _checkConnectivityAndSync() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      syncNow();
    } else {
      _updateSyncStatus(SyncStatus.offline);
    }
  }
  
  /// Trigger immediate synchronization
  Future<bool> syncNow() async {
    if (_syncInProgress) {
      // Already syncing
      return false;
    }
    
    _syncInProgress = true;
    _updateSyncStatus(SyncStatus.syncing);
    
    try {
      // Ensure user is authenticated
      if (!_supabaseService.isLoggedIn) {
        _updateSyncStatus(SyncStatus.authError);
        _syncInProgress = false;
        return false;
      }
      
      // Upload pending changes
      await _uploadPendingChanges();
      
      // Download and update local data
      await _downloadRemoteChanges();
      
      _updateSyncStatus(SyncStatus.synced);
      _syncInProgress = false;
      return true;
    } catch (e) {
      _updateSyncStatus(SyncStatus.error);
      _syncInProgress = false;
      return false;
    }
  }
  
  /// Upload local changes to remote
  Future<void> _uploadPendingChanges() async {
    try {
      // Get all pending local changes
      final pendingChanges = await _localStorageService.getPendingChanges();
      
      for (final change in pendingChanges) {
        switch (change.changeType) {
          case 'create':
            await _supabaseService.create(change.table, change.data);
            break;
          case 'update':
            await _supabaseService.update(change.table, change.itemId, change.data);
            break;
          case 'delete':
            await _supabaseService.delete(change.table, change.itemId);
            break;
        }
        
        // Mark change as synchronized
        await _localStorageService.markChangeAsSynced(change.id);
      }
    } catch (e) {
      debugPrint('Error uploading changes: $e');
      rethrow;
    }
  }
  
  /// Download remote changes and update local data
  Future<void> _downloadRemoteChanges() async {
    try {
      // Get last sync timestamp
      final lastSyncTime = await _localStorageService.getLastSyncTime();
      
      // TODO: Implement delta sync using timestamp on the server
      
      // For demo purposes, fetch all data for essential tables
      await _syncTable('pets');
      await _syncTable('journal_entries');
      await _syncTable('reminders');
      await _syncTable('medications');
      await _syncTable('health_records');
      
      // Update last sync time
      await _localStorageService.updateLastSyncTime(DateTime.now());
    } catch (e) {
      debugPrint('Error downloading changes: $e');
      rethrow;
    }
  }
  
  /// Sync a specific table
  Future<void> _syncTable(String table) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;
    
    try {
      // Download all data for this user
      final remoteData = await _supabaseService.fetch(
        table,
        // Assume each table has a user_id or household_id that links to the user
        column: table == 'households' ? 'owner_id' : 'user_id',
        value: userId,
      );
      
      // Update local storage with remote data
      await _localStorageService.syncRemoteData(table, remoteData);
    } catch (e) {
      debugPrint('Error syncing table $table: $e');
      rethrow;
    }
  }
  
  /// Update sync status and notify listeners
  void _updateSyncStatus(SyncStatus status) {
    _syncStatus = status;
    _syncSubject.add(status);
  }
  
  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _syncSubject.close();
  }
}

/// Enum representing the current sync status
enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
  authError,
}