import 'package:isar/isar.dart';

part 'health_record.g.dart';

@collection
class HealthRecord {
  Id get isarId => fastHash(id);
  
  /// Unique ID
  @Index(unique: true)
  final String id;
  
  /// Pet ID this record is for
  @Index()
  final String petId;
  
  /// Record type (e.g., "vaccination", "checkup", "surgery")
  @Index()
  final String recordType;
  
  /// Date of the record
  @Index()
  final DateTime date;
  
  /// Provider (e.g., vet name, clinic)
  final String? provider;
  
  /// Notes about the record
  final String? notes;
  
  /// Document URLs (e.g., reports, images)
  final List<String> documentUrls;
  
  /// User who created this record
  final String createdBy;
  
  /// When the record was created
  final DateTime createdAt;

  HealthRecord({
    required this.id,
    required this.petId,
    required this.recordType,
    required this.date,
    this.provider,
    this.notes,
    required this.documentUrls,
    required this.createdBy,
    required this.createdAt,
  });
  
  /// Create a copy of this health record with optional new values
  HealthRecord copyWith({
    String? id,
    String? petId,
    String? recordType,
    DateTime? date,
    String? provider,
    String? notes,
    List<String>? documentUrls,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      recordType: recordType ?? this.recordType,
      date: date ?? this.date,
      provider: provider ?? this.provider,
      notes: notes ?? this.notes,
      documentUrls: documentUrls ?? this.documentUrls,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert health record to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'record_type': recordType,
      'date': date.toIso8601String(),
      'provider': provider,
      'notes': notes,
      'document_urls': documentUrls,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Create health record from JSON
  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'],
      petId: json['pet_id'],
      recordType: json['record_type'],
      date: DateTime.parse(json['date']),
      provider: json['provider'],
      notes: json['notes'],
      documentUrls: json['document_urls'] != null
          ? List<String>.from(json['document_urls'])
          : [],
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