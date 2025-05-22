import 'package:isar/isar.dart';

part 'medication.g.dart';

@collection
class Medication {
  Id get isarId => fastHash(id);
  
  /// Unique ID
  @Index(unique: true)
  final String id;
  
  /// Pet ID this medication is for
  @Index()
  final String petId;
  
  /// Medication name
  final String name;
  
  /// Dosage information
  final String dosage;
  
  /// Frequency information (e.g., "Once daily", "Twice daily")
  final String frequency;
  
  /// Start date
  final DateTime startDate;
  
  /// End date (optional)
  final DateTime? endDate;
  
  /// Additional notes
  final String? notes;
  
  /// Barcode for medication
  final String? barcode;
  
  /// Whether this medication is currently active
  final bool active;
  
  /// User who created this medication
  final String createdBy;
  
  /// When the medication was created
  final DateTime createdAt;

  Medication({
    required this.id,
    required this.petId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.notes,
    this.barcode,
    required this.active,
    required this.createdBy,
    required this.createdAt,
  });
  
  /// Create a copy of this medication with optional new values
  Medication copyWith({
    String? id,
    String? petId,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    String? barcode,
    bool? active,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      barcode: barcode ?? this.barcode,
      active: active ?? this.active,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert medication to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'barcode': barcode,
      'active': active,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Create medication from JSON
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      petId: json['pet_id'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      notes: json['notes'],
      barcode: json['barcode'],
      active: json['active'] ?? true,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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