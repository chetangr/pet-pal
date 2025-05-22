import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/services/supabase_service.dart';
import 'package:petpal/core/services/local_storage_service.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/reminders/models/reminder.dart';
import 'package:uuid/uuid.dart';

/// Provider for all reminders
final remindersProvider = StateNotifierProvider<ReminderNotifier, AsyncValue<List<ReminderModel>>>(
  (ref) {
    final supabaseService = ref.watch(supabaseServiceProvider);
    final localStorageService = ref.watch(localStorageServiceProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    
    return ReminderNotifier(
      supabaseService: supabaseService,
      localStorageService: localStorageService,
      userId: userId,
    );
  },
);

/// Provider for reminders for a specific pet
final petRemindersProvider = Provider.family<AsyncValue<List<ReminderModel>>, String>((ref, petId) {
  final remindersAsync = ref.watch(remindersProvider);
  
  return remindersAsync.when(
    data: (reminders) {
      final filteredReminders = reminders
          .where((reminder) => 
              reminder.petId == petId && 
              !reminder.completed)
          .toList();
      
      return AsyncValue.data(filteredReminders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider for upcoming reminders (across all pets)
final upcomingRemindersProvider = Provider<AsyncValue<List<ReminderModel>>>((ref) {
  final remindersAsync = ref.watch(remindersProvider);
  final now = DateTime.now();
  
  return remindersAsync.when(
    data: (reminders) {
      // Get incomplete reminders
      final incompleteReminders = reminders
          .where((reminder) => !reminder.completed)
          .toList();
      
      // Sort by start time
      incompleteReminders.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      return AsyncValue.data(incompleteReminders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Notifier for managing reminders
class ReminderNotifier extends StateNotifier<AsyncValue<List<ReminderModel>>> {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  final String? _userId;
  final _uuid = const Uuid();
  
  ReminderNotifier({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
    String? userId,
  })  : _supabaseService = supabaseService,
        _localStorageService = localStorageService,
        _userId = userId,
        super(const AsyncValue.loading()) {
    // Initialize state
    if (_userId != null) {
      loadReminders();
    } else {
      state = const AsyncValue.data([]);
    }
  }
  
  /// Load reminders
  Future<void> loadReminders({
    bool forceRefresh = false,
    String? petId,
  }) async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    try {
      state = const AsyncValue.loading();
      
      // Initialize local storage
      await _localStorageService.init();
      
      // Load from local storage first
      final localReminders = await _localStorageService.getReminders(
        petId: petId,
      );
      
      // Return local data immediately
      if (localReminders.isNotEmpty && !forceRefresh) {
        state = AsyncValue.data(localReminders);
      }
      
      // Then try to fetch from Supabase
      try {
        final remoteReminders = await _supabaseService.fetch(
          'reminders',
          column: 'created_by',
          value: _userId,
          orderBy: 'start_time',
        );
        
        // Convert to models
        final reminderModels = remoteReminders
            .map((json) => ReminderModel.fromJson(json))
            .toList();
        
        // Filter by pet ID if provided
        final filteredModels = petId != null
            ? reminderModels.where((reminder) => reminder.petId == petId).toList()
            : reminderModels;
        
        // Save to local storage
        for (final reminder in filteredModels) {
          await _localStorageService.saveReminder(reminder);
        }
        
        // Update state with remote data
        state = AsyncValue.data(filteredModels);
      } catch (e) {
        // If remote fetch fails but we have local data, keep using that
        if (localReminders.isNotEmpty) {
          state = AsyncValue.data(localReminders);
        } else {
          // Otherwise, show error
          state = AsyncValue.error(e, StackTrace.current);
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Add a new reminder
  Future<String?> addReminder(ReminderModel reminder) async {
    if (_userId == null) return null;
    
    try {
      // Generate ID if not provided
      final id = reminder.id.isEmpty ? _uuid.v4() : reminder.id;
      
      // Create new reminder with current timestamp
      final newReminder = reminder.copyWith(
        id: id,
        createdBy: _userId,
        createdAt: DateTime.now(),
      );
      
      // Save to local storage
      await _localStorageService.saveReminder(newReminder);
      
      // Update state
      state = await state.whenData((reminders) => [...reminders, newReminder]);
      
      return id;
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      return null;
    }
  }
  
  /// Update an existing reminder
  Future<bool> updateReminder(ReminderModel reminder) async {
    try {
      // Save to local storage
      await _localStorageService.saveReminder(reminder);
      
      // Update state
      state = await state.whenData((reminders) {
        final index = reminders.indexWhere((r) => r.id == reminder.id);
        if (index >= 0) {
          final newList = List<ReminderModel>.from(reminders);
          newList[index] = reminder;
          return newList;
        }
        return reminders;
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      return false;
    }
  }
  
  /// Mark a reminder as completed
  Future<bool> completeReminder(String reminderId) async {
    try {
      final reminderAsync = state;
      if (reminderAsync is AsyncData<List<ReminderModel>>) {
        final reminders = reminderAsync.value;
        final reminder = reminders.firstWhere(
          (r) => r.id == reminderId,
          orElse: () => null!,
        );
        
        if (reminder != null) {
          final updatedReminder = reminder.markAsCompleted();
          return await updateReminder(updatedReminder);
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error completing reminder: $e');
      return false;
    }
  }
  
  /// Mark a reminder as not completed
  Future<bool> uncompleteReminder(String reminderId) async {
    try {
      final reminderAsync = state;
      if (reminderAsync is AsyncData<List<ReminderModel>>) {
        final reminders = reminderAsync.value;
        final reminder = reminders.firstWhere(
          (r) => r.id == reminderId,
          orElse: () => null!,
        );
        
        if (reminder != null) {
          final updatedReminder = reminder.markAsUncompleted();
          return await updateReminder(updatedReminder);
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error uncompleting reminder: $e');
      return false;
    }
  }
  
  /// Snooze a reminder
  Future<bool> snoozeReminder(String reminderId) async {
    try {
      final reminderAsync = state;
      if (reminderAsync is AsyncData<List<ReminderModel>>) {
        final reminders = reminderAsync.value;
        final reminder = reminders.firstWhere(
          (r) => r.id == reminderId,
          orElse: () => null!,
        );
        
        if (reminder != null) {
          final updatedReminder = reminder.snooze();
          return await updateReminder(updatedReminder);
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error snoozing reminder: $e');
      return false;
    }
  }
  
  /// Delete a reminder
  Future<bool> deleteReminder(String reminderId) async {
    try {
      // Delete from local storage
      await _localStorageService.deleteReminder(reminderId);
      
      // Update state
      state = await state.whenData((reminders) => 
        reminders.where((r) => r.id != reminderId).toList()
      );
      
      return true;
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      return false;
    }
  }
}