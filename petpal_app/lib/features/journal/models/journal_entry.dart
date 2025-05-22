import 'package:isar/isar.dart';

part 'journal_entry.g.dart';

@collection
class JournalEntryModel {
  Id get isarId => fastHash(id);
  
  /// Unique ID for the journal entry
  @Index(unique: true)
  final String id;
  
  /// Pet ID this entry is for
  @Index()
  final String petId;
  
  /// When this entry was recorded
  @Index()
  final DateTime timestamp;
  
  /// Entry type (food, activity, health, etc.)
  @Index()
  @Enumerated(EnumType.name)
  final JournalEntryType entryType;
  
  /// Food entry data
  final FoodEntryData? foodData;
  
  /// Activity entry data
  final ActivityEntryData? activityData;
  
  /// Health entry data
  final HealthEntryData? healthData;
  
  /// Mood entry data
  final MoodEntryData? moodData;
  
  /// General notes
  final String? notes;
  
  /// Photos attached to this entry
  final List<String> photoUrls;
  
  /// Tags for this entry
  final List<String> tags;
  
  /// User who created this entry
  final String createdBy;
  
  /// When the entry was created
  final DateTime createdAt;
  
  /// When the entry was last updated
  final DateTime updatedAt;

  JournalEntryModel({
    required this.id,
    required this.petId,
    required this.timestamp,
    required this.entryType,
    this.foodData,
    this.activityData,
    this.healthData,
    this.moodData,
    this.notes,
    required this.photoUrls,
    required this.tags,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Create a copy of this entry with optional new values
  JournalEntryModel copyWith({
    String? id,
    String? petId,
    DateTime? timestamp,
    JournalEntryType? entryType,
    FoodEntryData? foodData,
    ActivityEntryData? activityData,
    HealthEntryData? healthData,
    MoodEntryData? moodData,
    String? notes,
    List<String>? photoUrls,
    List<String>? tags,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      timestamp: timestamp ?? this.timestamp,
      entryType: entryType ?? this.entryType,
      foodData: foodData ?? this.foodData,
      activityData: activityData ?? this.activityData,
      healthData: healthData ?? this.healthData,
      moodData: moodData ?? this.moodData,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Convert entry to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'timestamp': timestamp.toIso8601String(),
      'entry_type': entryType.name,
      'food_data': foodData?.toJson(),
      'activity_data': activityData?.toJson(),
      'health_data': healthData?.toJson(),
      'mood_data': moodData?.toJson(),
      'notes': notes,
      'photo_urls': photoUrls,
      'tags': tags,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  /// Create entry from JSON
  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id'],
      petId: json['pet_id'],
      timestamp: DateTime.parse(json['timestamp']),
      entryType: _parseEntryType(json['entry_type']),
      foodData: json['food_data'] != null
          ? FoodEntryData.fromJson(json['food_data'])
          : null,
      activityData: json['activity_data'] != null
          ? ActivityEntryData.fromJson(json['activity_data'])
          : null,
      healthData: json['health_data'] != null
          ? HealthEntryData.fromJson(json['health_data'])
          : null,
      moodData: json['mood_data'] != null
          ? MoodEntryData.fromJson(json['mood_data'])
          : null,
      notes: json['notes'],
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'])
          : [],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  /// Get the title for this entry based on type
  String getTitle() {
    switch (entryType) {
      case JournalEntryType.food:
        return foodData?.mealType ?? 'Food';
      case JournalEntryType.activity:
        return activityData?.activityType ?? 'Activity';
      case JournalEntryType.health:
        return healthData?.symptom ?? 'Health';
      case JournalEntryType.mood:
        return 'Mood: ${moodData?.moodName ?? 'Unknown'}';
      case JournalEntryType.general:
        return 'Journal Entry';
    }
  }
  
  /// Get the summary for this entry
  String getSummary() {
    switch (entryType) {
      case JournalEntryType.food:
        if (foodData == null) return 'No details';
        return 'Food: ${foodData!.foodName}, Amount: ${foodData!.amount}';
      case JournalEntryType.activity:
        if (activityData == null) return 'No details';
        return '${activityData!.activityType}: ${activityData!.duration} mins';
      case JournalEntryType.health:
        if (healthData == null) return 'No details';
        return 'Symptom: ${healthData!.symptom}, Severity: ${healthData!.severity}';
      case JournalEntryType.mood:
        if (moodData == null) return 'No details';
        return 'Mood: ${moodData!.moodName}';
      case JournalEntryType.general:
        return notes?.substring(0, notes!.length > 50 ? 50 : notes!.length) ?? 'No details';
    }
  }
  
  /// Parse entry type from string
  static JournalEntryType _parseEntryType(String? typeName) {
    switch (typeName?.toLowerCase()) {
      case 'food':
        return JournalEntryType.food;
      case 'activity':
        return JournalEntryType.activity;
      case 'health':
        return JournalEntryType.health;
      case 'mood':
        return JournalEntryType.mood;
      default:
        return JournalEntryType.general;
    }
  }
}

/// Types of journal entries
enum JournalEntryType {
  food,
  activity,
  health,
  mood,
  general,
}

/// Data for food entries
@embedded
class FoodEntryData {
  /// Type of meal (breakfast, lunch, dinner, snack)
  late String mealType;
  
  /// Name of the food
  late String foodName;
  
  /// Amount/portion
  late String amount;
  
  /// Whether it was eaten completely
  late bool finished;
  
  /// Food brand
  String? brand;
  
  /// Barcode of the food (if scanned)
  String? barcode;
  
  FoodEntryData({
    required this.mealType,
    required this.foodName,
    required this.amount,
    required this.finished,
    this.brand,
    this.barcode,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'meal_type': mealType,
      'food_name': foodName,
      'amount': amount,
      'finished': finished,
      'brand': brand,
      'barcode': barcode,
    };
  }
  
  /// Create from JSON
  factory FoodEntryData.fromJson(Map<String, dynamic> json) {
    return FoodEntryData(
      mealType: json['meal_type'] ?? 'Meal',
      foodName: json['food_name'] ?? '',
      amount: json['amount'] ?? '',
      finished: json['finished'] ?? false,
      brand: json['brand'],
      barcode: json['barcode'],
    );
  }
}

/// Data for activity entries
@embedded
class ActivityEntryData {
  /// Type of activity (walk, play, training, etc.)
  late String activityType;
  
  /// Duration in minutes
  late int duration;
  
  /// Intensity level (low, medium, high)
  late String intensity;
  
  /// Distance in kilometers (for walks, runs)
  double? distance;
  
  /// Location of the activity
  String? location;
  
  ActivityEntryData({
    required this.activityType,
    required this.duration,
    required this.intensity,
    this.distance,
    this.location,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'activity_type': activityType,
      'duration': duration,
      'intensity': intensity,
      'distance': distance,
      'location': location,
    };
  }
  
  /// Create from JSON
  factory ActivityEntryData.fromJson(Map<String, dynamic> json) {
    return ActivityEntryData(
      activityType: json['activity_type'] ?? 'Activity',
      duration: json['duration'] ?? 0,
      intensity: json['intensity'] ?? 'Medium',
      distance: json['distance'],
      location: json['location'],
    );
  }
}

/// Data for health entries
@embedded
class HealthEntryData {
  /// Symptom or health issue
  late String symptom;
  
  /// Severity (mild, moderate, severe)
  late String severity;
  
  /// Whether medication was given
  late bool medicationGiven;
  
  /// Medication name if given
  String? medicationName;
  
  /// Medication dosage if given
  String? medicationDosage;
  
  /// Additional health notes
  String? medicalNotes;
  
  HealthEntryData({
    required this.symptom,
    required this.severity,
    required this.medicationGiven,
    this.medicationName,
    this.medicationDosage,
    this.medicalNotes,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'symptom': symptom,
      'severity': severity,
      'medication_given': medicationGiven,
      'medication_name': medicationName,
      'medication_dosage': medicationDosage,
      'medical_notes': medicalNotes,
    };
  }
  
  /// Create from JSON
  factory HealthEntryData.fromJson(Map<String, dynamic> json) {
    return HealthEntryData(
      symptom: json['symptom'] ?? '',
      severity: json['severity'] ?? 'Mild',
      medicationGiven: json['medication_given'] ?? false,
      medicationName: json['medication_name'],
      medicationDosage: json['medication_dosage'],
      medicalNotes: json['medical_notes'],
    );
  }
}

/// Data for mood entries
@embedded
class MoodEntryData {
  /// Mood name (happy, sad, energetic, etc.)
  late String moodName;
  
  /// Energy level (low, normal, high)
  late String energyLevel;
  
  /// Behavior notes
  String? behaviorNotes;
  
  MoodEntryData({
    required this.moodName,
    required this.energyLevel,
    this.behaviorNotes,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'mood_name': moodName,
      'energy_level': energyLevel,
      'behavior_notes': behaviorNotes,
    };
  }
  
  /// Create from JSON
  factory MoodEntryData.fromJson(Map<String, dynamic> json) {
    return MoodEntryData(
      moodName: json['mood_name'] ?? 'Normal',
      energyLevel: json['energy_level'] ?? 'Normal',
      behaviorNotes: json['behavior_notes'],
    );
  }
}

/// Convert string to integer hash for Isar ID
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}