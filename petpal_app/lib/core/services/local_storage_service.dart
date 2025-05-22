import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:petpal/features/auth/models/user.dart';
import 'package:petpal/features/pets/models/pet.dart';
import 'package:petpal/features/journal/models/journal_entry.dart';
import 'package:petpal/features/reminders/models/reminder.dart';
import 'package:petpal/features/pets/models/medication.dart';
import 'package:petpal/features/pets/models/health_record.dart';
import 'package:petpal/core/models/pending_change.dart';

/// Service for interacting with local storage
class LocalStorageService {
  static const String _lastSyncKey = 'last_sync_timestamp';
  
  late Isar _isar;
  late SharedPreferences _prefs;
  final _uuid = const Uuid();
  
  bool _isInitialized = false;
  
  /// Initialize the local storage
  Future<void> init() async {
    if (_isInitialized) return;
    
    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [
        UserSchema,
        PetSchema,
        JournalEntrySchema,
        ReminderSchema,
        MedicationSchema,
        HealthRecordSchema,
        PendingChangeSchema,
      ],
      directory: dir.path,
    );
    
    _prefs = await SharedPreferences.getInstance();
    
    _isInitialized = true;
  }
  
  // User methods
  
  /// Save current user to local storage
  Future<void> saveCurrentUser(User user) async {
    await _isar.writeTxn(() async {
      await _isar.users.put(user);
    });
  }
  
  /// Get current user from local storage
  Future<User?> getCurrentUser() async {
    return await _isar.users.where().findFirst();
  }
  
  /// Clear current user from local storage
  Future<void> clearCurrentUser() async {
    await _isar.writeTxn(() async {
      await _isar.users.clear();
    });
  }
  
  // Pet methods
  
  /// Save pet to local storage
  Future<String> savePet(Pet pet) async {
    final id = pet.id.isEmpty ? _uuid.v4() : pet.id;
    final petToSave = pet.copyWith(id: id);
    
    await _isar.writeTxn(() async {
      await _isar.pets.put(petToSave);
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'pets',
      id,
      petToSave.toJson(),
      pet.id.isEmpty ? 'create' : 'update',
    );
    
    return id;
  }
  
  /// Get pets from local storage
  Future<List<Pet>> getPets() async {
    return await _isar.pets.where().findAll();
  }
  
  /// Get pet by ID
  Future<Pet?> getPetById(String id) async {
    return await _isar.pets
        .filter()
        .idEqualTo(id)
        .findFirst();
  }
  
  /// Delete pet from local storage
  Future<void> deletePet(String id) async {
    await _isar.writeTxn(() async {
      await _isar.pets
          .filter()
          .idEqualTo(id)
          .deleteFirst();
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'pets',
      id,
      {},
      'delete',
    );
  }
  
  // Journal methods
  
  /// Save journal entry to local storage
  Future<String> saveJournalEntry(JournalEntry entry) async {
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
    final entryToSave = entry.copyWith(id: id);
    
    await _isar.writeTxn(() async {
      await _isar.journalEntrys.put(entryToSave);
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'journal_entries',
      id,
      entryToSave.toJson(),
      entry.id.isEmpty ? 'create' : 'update',
    );
    
    return id;
  }
  
  /// Get journal entries from local storage
  Future<List<JournalEntry>> getJournalEntries({
    String? petId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = _isar.journalEntrys.filter();
    
    if (petId != null) {
      query.petIdEqualTo(petId);
    }
    
    if (startDate != null) {
      query.timestampGreaterThan(startDate);
    }
    
    if (endDate != null) {
      query.timestampLessThan(endDate);
    }
    
    return await query.findAll();
  }
  
  /// Get journal entry by ID
  Future<JournalEntry?> getJournalEntryById(String id) async {
    return await _isar.journalEntrys
        .filter()
        .idEqualTo(id)
        .findFirst();
  }
  
  /// Delete journal entry from local storage
  Future<void> deleteJournalEntry(String id) async {
    await _isar.writeTxn(() async {
      await _isar.journalEntrys
          .filter()
          .idEqualTo(id)
          .deleteFirst();
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'journal_entries',
      id,
      {},
      'delete',
    );
  }
  
  // Reminder methods
  
  /// Save reminder to local storage
  Future<String> saveReminder(Reminder reminder) async {
    final id = reminder.id.isEmpty ? _uuid.v4() : reminder.id;
    final reminderToSave = reminder.copyWith(id: id);
    
    await _isar.writeTxn(() async {
      await _isar.reminders.put(reminderToSave);
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'reminders',
      id,
      reminderToSave.toJson(),
      reminder.id.isEmpty ? 'create' : 'update',
    );
    
    return id;
  }
  
  /// Get reminders from local storage
  Future<List<Reminder>> getReminders({
    String? petId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeCompleted = false,
  }) async {
    final query = _isar.reminders.filter();
    
    if (petId != null) {
      query.petIdEqualTo(petId);
    }
    
    if (startDate != null) {
      query.startTimeGreaterThan(startDate);
    }
    
    if (endDate != null) {
      query.startTimeLessThan(endDate);
    }
    
    if (!includeCompleted) {
      query.completedEqualTo(false);
    }
    
    return await query.findAll();
  }
  
  /// Get reminder by ID
  Future<Reminder?> getReminderById(String id) async {
    return await _isar.reminders
        .filter()
        .idEqualTo(id)
        .findFirst();
  }
  
  /// Delete reminder from local storage
  Future<void> deleteReminder(String id) async {
    await _isar.writeTxn(() async {
      await _isar.reminders
          .filter()
          .idEqualTo(id)
          .deleteFirst();
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'reminders',
      id,
      {},
      'delete',
    );
  }
  
  // Medication methods
  
  /// Save medication to local storage
  Future<String> saveMedication(Medication medication) async {
    final id = medication.id.isEmpty ? _uuid.v4() : medication.id;
    final medicationToSave = medication.copyWith(id: id);
    
    await _isar.writeTxn(() async {
      await _isar.medications.put(medicationToSave);
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'medications',
      id,
      medicationToSave.toJson(),
      medication.id.isEmpty ? 'create' : 'update',
    );
    
    return id;
  }
  
  /// Get medications from local storage
  Future<List<Medication>> getMedications({
    String? petId,
    bool includeInactive = false,
  }) async {
    final query = _isar.medications.filter();
    
    if (petId != null) {
      query.petIdEqualTo(petId);
    }
    
    if (!includeInactive) {
      query.activeEqualTo(true);
    }
    
    return await query.findAll();
  }
  
  /// Get medication by ID
  Future<Medication?> getMedicationById(String id) async {
    return await _isar.medications
        .filter()
        .idEqualTo(id)
        .findFirst();
  }
  
  /// Delete medication from local storage
  Future<void> deleteMedication(String id) async {
    await _isar.writeTxn(() async {
      await _isar.medications
          .filter()
          .idEqualTo(id)
          .deleteFirst();
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'medications',
      id,
      {},
      'delete',
    );
  }
  
  // Health record methods
  
  /// Save health record to local storage
  Future<String> saveHealthRecord(HealthRecord record) async {
    final id = record.id.isEmpty ? _uuid.v4() : record.id;
    final recordToSave = record.copyWith(id: id);
    
    await _isar.writeTxn(() async {
      await _isar.healthRecords.put(recordToSave);
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'health_records',
      id,
      recordToSave.toJson(),
      record.id.isEmpty ? 'create' : 'update',
    );
    
    return id;
  }
  
  /// Get health records from local storage
  Future<List<HealthRecord>> getHealthRecords({
    String? petId,
    String? recordType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = _isar.healthRecords.filter();
    
    if (petId != null) {
      query.petIdEqualTo(petId);
    }
    
    if (recordType != null) {
      query.recordTypeEqualTo(recordType);
    }
    
    if (startDate != null) {
      query.dateGreaterThan(startDate);
    }
    
    if (endDate != null) {
      query.dateLessThan(endDate);
    }
    
    return await query.findAll();
  }
  
  /// Get health record by ID
  Future<HealthRecord?> getHealthRecordById(String id) async {
    return await _isar.healthRecords
        .filter()
        .idEqualTo(id)
        .findFirst();
  }
  
  /// Delete health record from local storage
  Future<void> deleteHealthRecord(String id) async {
    await _isar.writeTxn(() async {
      await _isar.healthRecords
          .filter()
          .idEqualTo(id)
          .deleteFirst();
    });
    
    // Create pending change for sync
    await _createPendingChange(
      'health_records',
      id,
      {},
      'delete',
    );
  }
  
  // Sync methods
  
  /// Create a pending change for synchronization
  Future<void> _createPendingChange(
    String table,
    String itemId,
    Map<String, dynamic> data,
    String changeType,
  ) async {
    final change = PendingChange(
      id: _uuid.v4(),
      table: table,
      itemId: itemId,
      data: data,
      changeType: changeType,
      timestamp: DateTime.now(),
      synced: false,
    );
    
    await _isar.writeTxn(() async {
      await _isar.pendingChanges.put(change);
    });
  }
  
  /// Get all pending changes for synchronization
  Future<List<PendingChange>> getPendingChanges() async {
    return await _isar.pendingChanges
        .filter()
        .syncedEqualTo(false)
        .findAll();
  }
  
  /// Mark a change as synchronized
  Future<void> markChangeAsSynced(String changeId) async {
    await _isar.writeTxn(() async {
      final change = await _isar.pendingChanges
          .filter()
          .idEqualTo(changeId)
          .findFirst();
      
      if (change != null) {
        change.synced = true;
        await _isar.pendingChanges.put(change);
      }
    });
  }
  
  /// Sync remote data with local storage
  Future<void> syncRemoteData(
    String table,
    List<Map<String, dynamic>> remoteData,
  ) async {
    switch (table) {
      case 'pets':
        await _syncPets(remoteData);
        break;
      case 'journal_entries':
        await _syncJournalEntries(remoteData);
        break;
      case 'reminders':
        await _syncReminders(remoteData);
        break;
      case 'medications':
        await _syncMedications(remoteData);
        break;
      case 'health_records':
        await _syncHealthRecords(remoteData);
        break;
    }
  }
  
  /// Sync pets from remote data
  Future<void> _syncPets(List<Map<String, dynamic>> remoteData) async {
    await _isar.writeTxn(() async {
      for (final petData in remoteData) {
        final pet = Pet.fromJson(petData);
        await _isar.pets.put(pet);
      }
    });
  }
  
  /// Sync journal entries from remote data
  Future<void> _syncJournalEntries(List<Map<String, dynamic>> remoteData) async {
    await _isar.writeTxn(() async {
      for (final entryData in remoteData) {
        final entry = JournalEntry.fromJson(entryData);
        await _isar.journalEntrys.put(entry);
      }
    });
  }
  
  /// Sync reminders from remote data
  Future<void> _syncReminders(List<Map<String, dynamic>> remoteData) async {
    await _isar.writeTxn(() async {
      for (final reminderData in remoteData) {
        final reminder = Reminder.fromJson(reminderData);
        await _isar.reminders.put(reminder);
      }
    });
  }
  
  /// Sync medications from remote data
  Future<void> _syncMedications(List<Map<String, dynamic>> remoteData) async {
    await _isar.writeTxn(() async {
      for (final medicationData in remoteData) {
        final medication = Medication.fromJson(medicationData);
        await _isar.medications.put(medication);
      }
    });
  }
  
  /// Sync health records from remote data
  Future<void> _syncHealthRecords(List<Map<String, dynamic>> remoteData) async {
    await _isar.writeTxn(() async {
      for (final recordData in remoteData) {
        final record = HealthRecord.fromJson(recordData);
        await _isar.healthRecords.put(record);
      }
    });
  }
  
  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = _prefs.getInt(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }
  
  /// Update last sync timestamp
  Future<void> updateLastSyncTime(DateTime timestamp) async {
    await _prefs.setInt(_lastSyncKey, timestamp.millisecondsSinceEpoch);
  }
  
  /// Clear all local data
  Future<void> clearAllData() async {
    await _isar.writeTxn(() async {
      await _isar.users.clear();
      await _isar.pets.clear();
      await _isar.journalEntrys.clear();
      await _isar.reminders.clear();
      await _isar.medications.clear();
      await _isar.healthRecords.clear();
      await _isar.pendingChanges.clear();
    });
    
    await _prefs.clear();
  }
  
  /// Dispose resources
  void dispose() {
    _isar.close();
  }
}