import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/services/supabase_service.dart';
import 'package:petpal/core/services/local_storage_service.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/journal/models/journal_entry.dart';
import 'package:uuid/uuid.dart';

/// Provider for journal entries for a specific pet
final petJournalProvider = FutureProvider.family<List<JournalEntryModel>, String>((ref, petId) async {
  return ref.read(journalProvider.notifier).getJournalEntries(petId: petId);
});

/// Provider for all journal entries
final journalProvider = StateNotifierProvider<JournalNotifier, AsyncValue<List<JournalEntryModel>>>(
  (ref) {
    final supabaseService = ref.watch(supabaseServiceProvider);
    final localStorageService = ref.watch(localStorageServiceProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    
    return JournalNotifier(
      supabaseService: supabaseService,
      localStorageService: localStorageService,
      userId: userId,
    );
  },
);

/// Notifier for managing journal entries
class JournalNotifier extends StateNotifier<AsyncValue<List<JournalEntryModel>>> {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  final String? _userId;
  final _uuid = const Uuid();
  
  JournalNotifier({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
    String? userId,
  })  : _supabaseService = supabaseService,
        _localStorageService = localStorageService,
        _userId = userId,
        super(const AsyncValue.loading()) {
    // Initialize state
    if (_userId != null) {
      loadJournalEntries();
    } else {
      state = const AsyncValue.data([]);
    }
  }
  
  /// Load journal entries
  Future<void> loadJournalEntries({bool forceRefresh = false}) async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    try {
      state = const AsyncValue.loading();
      
      // Initialize local storage
      await _localStorageService.init();
      
      // Load from local storage first
      final localEntries = await _localStorageService.getJournalEntries();
      
      // Return local data immediately
      if (localEntries.isNotEmpty && !forceRefresh) {
        state = AsyncValue.data(localEntries);
      }
      
      // Then try to fetch from Supabase
      try {
        final remoteEntries = await _supabaseService.fetch(
          'journal_entries',
          column: 'created_by',
          value: _userId,
          orderBy: 'timestamp',
          ascending: false,
        );
        
        // Convert to models
        final entryModels = remoteEntries
            .map((json) => JournalEntryModel.fromJson(json))
            .toList();
        
        // Save to local storage
        for (final entry in entryModels) {
          await _localStorageService.saveJournalEntry(entry);
        }
        
        // Update state with remote data
        state = AsyncValue.data(entryModels);
      } catch (e) {
        // If remote fetch fails but we have local data, keep using that
        if (localEntries.isNotEmpty) {
          state = AsyncValue.data(localEntries);
        } else {
          // Otherwise, show error
          state = AsyncValue.error(e, StackTrace.current);
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Get journal entries for a specific pet
  Future<List<JournalEntryModel>> getJournalEntries({
    String? petId,
    DateTime? startDate,
    DateTime? endDate,
    JournalEntryType? entryType,
    int? limit,
  }) async {
    try {
      // Initialize local storage
      await _localStorageService.init();
      
      // Get entries from local storage
      return await _localStorageService.getJournalEntries(
        petId: petId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error getting journal entries: $e');
      return [];
    }
  }
  
  /// Add a new journal entry
  Future<String?> addJournalEntry(JournalEntryModel entry) async {
    if (_userId == null) return null;
    
    try {
      // Generate ID if not provided
      final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
      
      // Create new entry with current timestamp
      final newEntry = entry.copyWith(
        id: id,
        createdBy: _userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to local storage
      await _localStorageService.saveJournalEntry(newEntry);
      
      // Update state if already loaded
      if (state case AsyncData<List<JournalEntryModel>>(value: final entries)) {
        state = AsyncValue.data([newEntry, ...entries]);
      }
      
      return id;
    } catch (e) {
      debugPrint('Error adding journal entry: $e');
      return null;
    }
  }
  
  /// Update an existing journal entry
  Future<bool> updateJournalEntry(JournalEntryModel entry) async {
    try {
      // Update timestamp
      final updatedEntry = entry.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Save to local storage
      await _localStorageService.saveJournalEntry(updatedEntry);
      
      // Update state if already loaded
      if (state case AsyncData<List<JournalEntryModel>>(value: final entries)) {
        final index = entries.indexWhere((e) => e.id == entry.id);
        if (index >= 0) {
          final newList = List<JournalEntryModel>.from(entries);
          newList[index] = updatedEntry;
          state = AsyncValue.data(newList);
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating journal entry: $e');
      return false;
    }
  }
  
  /// Delete a journal entry
  Future<bool> deleteJournalEntry(String entryId) async {
    try {
      // Delete from local storage
      await _localStorageService.deleteJournalEntry(entryId);
      
      // Update state if already loaded
      if (state case AsyncData<List<JournalEntryModel>>(value: final entries)) {
        state = AsyncValue.data(
          entries.where((e) => e.id != entryId).toList(),
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error deleting journal entry: $e');
      return false;
    }
  }
  
  /// Upload a photo for a journal entry
  Future<String?> uploadEntryPhoto(String entryId, File photoFile) async {
    try {
      // Upload to storage
      final path = await _supabaseService.uploadFile(
        photoFile,
        'journal/$entryId',
      );
      
      // Get public URL
      final photoUrl = _supabaseService.getFileUrl(path);
      
      // Update entry with new photo URL if it exists
      if (state case AsyncData<List<JournalEntryModel>>(value: final entries)) {
        final entry = entries.firstWhere(
          (e) => e.id == entryId,
          orElse: () => null!,
        );
        
        if (entry != null) {
          final updatedEntry = entry.copyWith(
            photoUrls: [...entry.photoUrls, photoUrl],
            updatedAt: DateTime.now(),
          );
          
          await updateJournalEntry(updatedEntry);
        }
      }
      
      return photoUrl;
    } catch (e) {
      debugPrint('Error uploading entry photo: $e');
      return null;
    }
  }
}