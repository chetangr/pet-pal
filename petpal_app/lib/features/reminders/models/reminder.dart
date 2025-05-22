import 'package:isar/isar.dart';

part 'reminder.g.dart';

@collection
class ReminderModel {
  Id get isarId => fastHash(id);
  
  /// Unique ID for the reminder
  @Index(unique: true)
  final String id;
  
  /// Pet ID this reminder is for (optional - can be for all pets)
  @Index()
  final String? petId;
  
  /// Title of the reminder
  final String title;
  
  /// Detailed description
  final String? description;
  
  /// Type of reminder (medication, vet, grooming, etc.)
  @Index()
  @Enumerated(EnumType.name)
  final ReminderType reminderType;
  
  /// Start time of the reminder
  @Index()
  final DateTime startTime;
  
  /// End time of the reminder (optional for one-time reminders)
  final DateTime? endTime;
  
  /// Recurrence rule (RFC 5545 format)
  final String? recurrenceRule;
  
  /// Whether the reminder is completed
  @Index()
  final bool completed;
  
  /// Completion time if completed
  final DateTime? completedAt;
  
  /// Times the reminder was snoozed
  final int snoozeCount;
  
  /// Person assigned to this reminder (optional)
  final String? assignedTo;
  
  /// User who created this reminder
  final String createdBy;
  
  /// When the reminder was created
  final DateTime createdAt;
  
  /// Additional data for the reminder (could be medication details, etc.)
  final Map<String, dynamic> data;

  ReminderModel({
    required this.id,
    this.petId,
    required this.title,
    this.description,
    required this.reminderType,
    required this.startTime,
    this.endTime,
    this.recurrenceRule,
    required this.completed,
    this.completedAt,
    required this.snoozeCount,
    this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.data,
  });
  
  /// Create a copy of this reminder with optional new values
  ReminderModel copyWith({
    String? id,
    String? petId,
    String? title,
    String? description,
    ReminderType? reminderType,
    DateTime? startTime,
    DateTime? endTime,
    String? recurrenceRule,
    bool? completed,
    DateTime? completedAt,
    int? snoozeCount,
    String? assignedTo,
    String? createdBy,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderType: reminderType ?? this.reminderType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
  
  /// Create a completed copy of this reminder
  ReminderModel markAsCompleted() {
    return copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );
  }
  
  /// Create an uncompleted copy of this reminder
  ReminderModel markAsUncompleted() {
    return copyWith(
      completed: false,
      completedAt: null,
    );
  }
  
  /// Increment snooze count for this reminder
  ReminderModel snooze() {
    return copyWith(
      snoozeCount: snoozeCount + 1,
    );
  }
  
  /// Convert reminder to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'title': title,
      'description': description,
      'reminder_type': reminderType.name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'recurrence_rule': recurrenceRule,
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
      'snooze_count': snoozeCount,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'data': data,
    };
  }
  
  /// Create reminder from JSON
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'],
      petId: json['pet_id'],
      title: json['title'],
      description: json['description'],
      reminderType: _parseReminderType(json['reminder_type']),
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      recurrenceRule: json['recurrence_rule'],
      completed: json['completed'] ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      snoozeCount: json['snooze_count'] ?? 0,
      assignedTo: json['assigned_to'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      data: json['data'] ?? {},
    );
  }
  
  /// Check if the reminder is recurring
  bool get isRecurring => recurrenceRule != null && recurrenceRule!.isNotEmpty;
  
  /// Check if the reminder is overdue
  bool isOverdue(DateTime now) {
    // If completed, it's not overdue
    if (completed) return false;
    
    // If recurring, we would need to calculate the next occurrence
    if (isRecurring) {
      // TODO: Implement proper recurrence calculation
      return false;
    }
    
    // For one-time reminders, check if start time is in the past
    return startTime.isBefore(now);
  }
  
  /// Get the icon for this reminder type
  static IconData getIcon(ReminderType type) {
    switch (type) {
      case ReminderType.medication:
        return Icons.medication;
      case ReminderType.food:
        return Icons.restaurant;
      case ReminderType.water:
        return Icons.water_drop;
      case ReminderType.walk:
        return Icons.directions_walk;
      case ReminderType.vet:
        return Icons.local_hospital;
      case ReminderType.grooming:
        return Icons.content_cut;
      case ReminderType.vaccination:
        return Icons.vaccine;
      case ReminderType.other:
        return Icons.notifications;
    }
  }
  
  /// Parse reminder type from string
  static ReminderType _parseReminderType(String? typeName) {
    switch (typeName?.toLowerCase()) {
      case 'medication':
        return ReminderType.medication;
      case 'food':
        return ReminderType.food;
      case 'water':
        return ReminderType.water;
      case 'walk':
        return ReminderType.walk;
      case 'vet':
        return ReminderType.vet;
      case 'grooming':
        return ReminderType.grooming;
      case 'vaccination':
        return ReminderType.vaccination;
      default:
        return ReminderType.other;
    }
  }
}

/// Types of reminders
enum ReminderType {
  medication,
  food,
  water,
  walk,
  vet,
  grooming,
  vaccination,
  other,
}

/// Helper class for working with recurrence rules
class RecurrenceHelper {
  static const String daily = 'FREQ=DAILY';
  static const String weekly = 'FREQ=WEEKLY';
  static const String monthly = 'FREQ=MONTHLY';
  
  /// Create a daily recurrence rule
  static String createDaily({int? interval, DateTime? until}) {
    String rule = 'FREQ=DAILY';
    
    if (interval != null && interval > 1) {
      rule += ';INTERVAL=$interval';
    }
    
    if (until != null) {
      final untilStr = until.toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0] + 'Z';
      rule += ';UNTIL=$untilStr';
    }
    
    return rule;
  }
  
  /// Create a weekly recurrence rule
  static String createWeekly({
    int? interval,
    List<int>? byDay, // 1 = Monday, 7 = Sunday
    DateTime? until,
  }) {
    String rule = 'FREQ=WEEKLY';
    
    if (interval != null && interval > 1) {
      rule += ';INTERVAL=$interval';
    }
    
    if (byDay != null && byDay.isNotEmpty) {
      final days = byDay.map((day) {
        switch (day) {
          case 1: return 'MO';
          case 2: return 'TU';
          case 3: return 'WE';
          case 4: return 'TH';
          case 5: return 'FR';
          case 6: return 'SA';
          case 7: return 'SU';
          default: return '';
        }
      }).where((day) => day.isNotEmpty).join(',');
      
      if (days.isNotEmpty) {
        rule += ';BYDAY=$days';
      }
    }
    
    if (until != null) {
      final untilStr = until.toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0] + 'Z';
      rule += ';UNTIL=$untilStr';
    }
    
    return rule;
  }
  
  /// Create a monthly recurrence rule
  static String createMonthly({
    int? interval,
    int? byMonthDay, // day of month (1-31)
    DateTime? until,
  }) {
    String rule = 'FREQ=MONTHLY';
    
    if (interval != null && interval > 1) {
      rule += ';INTERVAL=$interval';
    }
    
    if (byMonthDay != null && byMonthDay >= 1 && byMonthDay <= 31) {
      rule += ';BYMONTHDAY=$byMonthDay';
    }
    
    if (until != null) {
      final untilStr = until.toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0] + 'Z';
      rule += ';UNTIL=$untilStr';
    }
    
    return rule;
  }
  
  /// Get a human-readable description of a recurrence rule
  static String getDescription(String rule) {
    if (rule.isEmpty) return 'Once';
    
    // Parse frequency
    final freqMatch = RegExp(r'FREQ=(\w+)').firstMatch(rule);
    if (freqMatch == null) return 'Custom';
    
    final freq = freqMatch.group(1);
    
    // Parse interval
    int interval = 1;
    final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rule);
    if (intervalMatch != null) {
      interval = int.parse(intervalMatch.group(1) ?? '1');
    }
    
    // Parse until
    String untilStr = '';
    final untilMatch = RegExp(r'UNTIL=(\d+T\d+Z)').firstMatch(rule);
    if (untilMatch != null) {
      try {
        final untilDate = DateTime.parse(untilMatch.group(1)!
            .replaceAllMapped(RegExp(r'(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z'), 
            (m) => '${m[1]}-${m[2]}-${m[3]}T${m[4]}:${m[5]}:${m[6]}Z'));
        
        // Format as "until Jan 1, 2023"
        untilStr = ' until ${untilDate.month}/${untilDate.day}/${untilDate.year}';
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    switch (freq) {
      case 'DAILY':
        if (interval == 1) return 'Daily$untilStr';
        return 'Every $interval days$untilStr';
        
      case 'WEEKLY':
        // Check for specific days
        final byDayMatch = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(rule);
        if (byDayMatch != null) {
          final days = byDayMatch.group(1)!.split(',');
          if (days.length == 1) {
            final day = _getDayName(days[0]);
            if (interval == 1) return 'Weekly on $day$untilStr';
            return 'Every $interval weeks on $day$untilStr';
          } else if (days.length > 1) {
            final dayNames = days.map(_getDayName).join(', ');
            if (interval == 1) return 'Weekly on $dayNames$untilStr';
            return 'Every $interval weeks on $dayNames$untilStr';
          }
        }
        
        if (interval == 1) return 'Weekly$untilStr';
        return 'Every $interval weeks$untilStr';
        
      case 'MONTHLY':
        // Check for specific day of month
        final byMonthDayMatch = RegExp(r'BYMONTHDAY=(\d+)').firstMatch(rule);
        if (byMonthDayMatch != null) {
          final day = int.parse(byMonthDayMatch.group(1) ?? '1');
          final dayStr = _getDayWithOrdinal(day);
          
          if (interval == 1) return 'Monthly on the $dayStr$untilStr';
          return 'Every $interval months on the $dayStr$untilStr';
        }
        
        if (interval == 1) return 'Monthly$untilStr';
        return 'Every $interval months$untilStr';
        
      default:
        return 'Custom schedule';
    }
  }
  
  static String _getDayName(String shortDay) {
    switch (shortDay) {
      case 'MO': return 'Monday';
      case 'TU': return 'Tuesday';
      case 'WE': return 'Wednesday';
      case 'TH': return 'Thursday';
      case 'FR': return 'Friday';
      case 'SA': return 'Saturday';
      case 'SU': return 'Sunday';
      default: return shortDay;
    }
  }
  
  static String _getDayWithOrdinal(int day) {
    if (day >= 11 && day <= 13) {
      return '$day\u1D57\u02B0';
    }
    
    switch (day % 10) {
      case 1: return '$day\u02E2\u1D57';
      case 2: return '$day\u207F\u1D48';
      case 3: return '$day\u02B3\u1D48';
      default: return '$day\u1D57\u02B0';
    }
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