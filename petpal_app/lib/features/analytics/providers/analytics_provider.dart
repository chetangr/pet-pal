import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/services/supabase_service.dart';
import 'package:petpal/core/services/local_storage_service.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/analytics/models/weight_record.dart';
import 'package:petpal/features/journal/models/journal_entry.dart';
import 'package:petpal/features/journal/providers/journal_provider.dart';
import 'package:uuid/uuid.dart';

/// Provider for weight history for a specific pet
final weightHistoryProvider = FutureProvider.family<List<WeightRecord>, String>((ref, petId) async {
  final weightService = ref.watch(weightServiceProvider);
  
  return weightService.getWeightHistory(petId);
});

/// Provider for weight service
final weightServiceProvider = Provider<WeightService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  
  return WeightService(
    supabaseService: supabaseService,
    localStorageService: localStorageService,
    userId: userId,
  );
});

/// Service for managing weight records
class WeightService {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  final String? _userId;
  final _uuid = const Uuid();
  
  WeightService({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
    String? userId,
  })  : _supabaseService = supabaseService,
        _localStorageService = localStorageService,
        _userId = userId;
  
  /// Get weight history for a pet
  Future<List<WeightRecord>> getWeightHistory(String petId) async {
    try {
      // Initialize local storage
      await _localStorageService.init();
      
      // Try to fetch from Supabase
      try {
        final remoteRecords = await _supabaseService.fetch(
          'weight_records',
          column: 'pet_id',
          value: petId,
          orderBy: 'date',
        );
        
        // Convert to models
        final weightRecords = remoteRecords
            .map((json) => WeightRecord.fromJson(json))
            .toList();
        
        // Save to local storage for offline access
        for (final record in weightRecords) {
          // TODO: Implement local storage for weight records
        }
        
        return weightRecords;
      } catch (e) {
        // If remote fetch fails, try to get from local storage
        // TODO: Implement local storage fallback
        debugPrint('Error fetching weight records: $e');
        return [];
      }
    } catch (e) {
      debugPrint('Error in weight history: $e');
      return [];
    }
  }
  
  /// Add a new weight record
  Future<String?> addWeightRecord(WeightRecord record) async {
    if (_userId == null) return null;
    
    try {
      // Generate ID if not provided
      final id = record.id.isEmpty ? _uuid.v4() : record.id;
      
      // Create new record with current timestamp
      final newRecord = record.copyWith(
        id: id,
        createdBy: _userId,
        createdAt: DateTime.now(),
      );
      
      // Save to Supabase
      await _supabaseService.create(
        'weight_records',
        newRecord.toJson(),
      );
      
      // TODO: Save to local storage
      
      return id;
    } catch (e) {
      debugPrint('Error adding weight record: $e');
      return null;
    }
  }
  
  /// Delete a weight record
  Future<bool> deleteWeightRecord(String recordId) async {
    try {
      // Delete from Supabase
      await _supabaseService.delete('weight_records', recordId);
      
      // TODO: Delete from local storage
      
      return true;
    } catch (e) {
      debugPrint('Error deleting weight record: $e');
      return false;
    }
  }
}

/// Provider for activity analytics for a specific pet
final activityAnalyticsProvider = FutureProvider.family<ActivityAnalytics, String>((ref, petId) async {
  final journalProvider = ref.watch(petJournalProvider(petId));
  
  return journalProvider.when(
    data: (entries) {
      // Process journal entries to extract activity data
      return _processActivityData(entries);
    },
    loading: () => ActivityAnalytics.empty(),
    error: (error, stackTrace) => ActivityAnalytics.empty(),
  );
});

/// Process journal entries to extract activity data
ActivityAnalytics _processActivityData(List<JournalEntryModel> entries) {
  // Filter for activity entries
  final activityEntries = entries
      .where((e) => e.entryType == JournalEntryType.activity && e.activityData != null)
      .toList();
  
  if (activityEntries.isEmpty) {
    return ActivityAnalytics.empty();
  }
  
  // Extract data for analysis
  int totalActivities = activityEntries.length;
  int totalMinutes = 0;
  Map<String, int> activityTypes = {};
  Map<String, int> activityMinutesByType = {};
  
  for (final entry in activityEntries) {
    final activityData = entry.activityData!;
    final type = activityData.activityType;
    final duration = activityData.duration;
    
    totalMinutes += duration;
    
    // Count by type
    if (activityTypes.containsKey(type)) {
      activityTypes[type] = activityTypes[type]! + 1;
    } else {
      activityTypes[type] = 1;
    }
    
    // Sum minutes by type
    if (activityMinutesByType.containsKey(type)) {
      activityMinutesByType[type] = activityMinutesByType[type]! + duration;
    } else {
      activityMinutesByType[type] = duration;
    }
  }
  
  // Calculate averages
  double avgDuration = totalMinutes / totalActivities;
  
  return ActivityAnalytics(
    totalActivities: totalActivities,
    totalMinutes: totalMinutes,
    averageDuration: avgDuration,
    activityTypes: activityTypes,
    minutesByType: activityMinutesByType,
  );
}

/// Class to hold activity analytics data
class ActivityAnalytics {
  final int totalActivities;
  final int totalMinutes;
  final double averageDuration;
  final Map<String, int> activityTypes;
  final Map<String, int> minutesByType;
  
  ActivityAnalytics({
    required this.totalActivities,
    required this.totalMinutes,
    required this.averageDuration,
    required this.activityTypes,
    required this.minutesByType,
  });
  
  /// Create empty analytics
  factory ActivityAnalytics.empty() {
    return ActivityAnalytics(
      totalActivities: 0,
      totalMinutes: 0,
      averageDuration: 0,
      activityTypes: {},
      minutesByType: {},
    );
  }
  
  /// Get most common activity type
  String? get mostCommonActivity {
    if (activityTypes.isEmpty) return null;
    
    String? mostCommon;
    int highestCount = 0;
    
    activityTypes.forEach((type, count) {
      if (count > highestCount) {
        highestCount = count;
        mostCommon = type;
      }
    });
    
    return mostCommon;
  }
  
  /// Check if there is any activity data
  bool get hasData => totalActivities > 0;
}