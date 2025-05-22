import 'package:isar/isar.dart';

part 'weight_record.g.dart';

@collection
class WeightRecord {
  Id get isarId => fastHash(id);
  
  /// Unique ID
  @Index(unique: true)
  final String id;
  
  /// Pet ID this record is for
  @Index()
  final String petId;
  
  /// Weight in kilograms
  final double weight;
  
  /// Date of the record
  @Index()
  final DateTime date;
  
  /// Optional notes about the measurement
  final String? notes;
  
  /// User who created this record
  final String createdBy;
  
  /// When the record was created
  final DateTime createdAt;

  WeightRecord({
    required this.id,
    required this.petId,
    required this.weight,
    required this.date,
    this.notes,
    required this.createdBy,
    required this.createdAt,
  });
  
  /// Create a copy of this weight record with optional new values
  WeightRecord copyWith({
    String? id,
    String? petId,
    double? weight,
    DateTime? date,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert weight record to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'weight': weight,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Create weight record from JSON
  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'],
      petId: json['pet_id'],
      weight: json['weight'] is int 
          ? json['weight'].toDouble() 
          : json['weight'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
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