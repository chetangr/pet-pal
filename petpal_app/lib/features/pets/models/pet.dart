import 'package:isar/isar.dart';

part 'pet.g.dart';

@collection
class PetModel {
  Id get isarId => fastHash(id);
  
  /// Unique ID for the pet
  @Index(unique: true)
  final String id;
  
  /// Pet's name
  final String name;
  
  /// Pet's birth date
  final DateTime? birthdate;
  
  /// Pet type (dog, cat, etc.)
  @Enumerated(EnumType.name)
  final PetType type;
  
  /// Pet breed
  final String breed;
  
  /// Pet gender
  @Enumerated(EnumType.name)
  final PetGender gender;
  
  /// Pet weight in kilograms
  final double? weight;
  
  /// URLs to pet photos
  final List<String> photoUrls;
  
  /// Primary photo URL
  final String? profilePhotoUrl;
  
  /// Microchip ID
  final String? microchipId;
  
  /// Pet notes
  final String? notes;
  
  /// Pet medications
  final List<String> medications;
  
  /// User ID of the pet owner
  final String userId;
  
  /// Household ID
  final String? householdId;
  
  /// ID of the primary vet
  final String? primaryVetId;
  
  /// When the pet record was created
  final DateTime createdAt;
  
  /// When the pet record was last updated
  final DateTime updatedAt;
  
  /// Custom fields for pet
  final Map<String, dynamic> customFields;

  PetModel({
    required this.id,
    required this.name,
    this.birthdate,
    required this.type,
    required this.breed,
    required this.gender,
    this.weight,
    required this.photoUrls,
    this.profilePhotoUrl,
    this.microchipId,
    this.notes,
    required this.medications,
    required this.userId,
    this.householdId,
    this.primaryVetId,
    required this.createdAt,
    required this.updatedAt,
    required this.customFields,
  });
  
  /// Create a copy of this pet with optional new values
  PetModel copyWith({
    String? id,
    String? name,
    DateTime? birthdate,
    PetType? type,
    String? breed,
    PetGender? gender,
    double? weight,
    List<String>? photoUrls,
    String? profilePhotoUrl,
    String? microchipId,
    String? notes,
    List<String>? medications,
    String? userId,
    String? householdId,
    String? primaryVetId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customFields,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      photoUrls: photoUrls ?? this.photoUrls,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      microchipId: microchipId ?? this.microchipId,
      notes: notes ?? this.notes,
      medications: medications ?? this.medications,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      primaryVetId: primaryVetId ?? this.primaryVetId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customFields: customFields ?? this.customFields,
    );
  }
  
  /// Convert pet to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthdate': birthdate?.toIso8601String(),
      'type': type.name,
      'breed': breed,
      'gender': gender.name,
      'weight': weight,
      'photo_urls': photoUrls,
      'profile_photo_url': profilePhotoUrl,
      'microchip_id': microchipId,
      'notes': notes,
      'medications': medications,
      'user_id': userId,
      'household_id': householdId,
      'primary_vet_id': primaryVetId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'custom_fields': customFields,
    };
  }
  
  /// Create pet from JSON
  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      name: json['name'],
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : null,
      type: _parseType(json['type']),
      breed: json['breed'] ?? '',
      gender: _parseGender(json['gender']),
      weight: json['weight'] != null
          ? double.parse(json['weight'].toString())
          : null,
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'])
          : [],
      profilePhotoUrl: json['profile_photo_url'],
      microchipId: json['microchip_id'],
      notes: json['notes'],
      medications: json['medications'] != null
          ? List<String>.from(json['medications'])
          : [],
      userId: json['user_id'],
      householdId: json['household_id'],
      primaryVetId: json['primary_vet_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      customFields: json['custom_fields'] ?? {},
    );
  }
  
  /// Get the pet's age as a string
  String getAgeString() {
    if (birthdate == null) {
      return 'Age unknown';
    }
    
    final now = DateTime.now();
    final age = now.difference(birthdate!);
    
    final years = age.inDays ~/ 365;
    final months = (age.inDays % 365) ~/ 30;
    
    if (years > 0) {
      return months > 0
          ? '$years year${years > 1 ? 's' : ''}, $months month${months > 1 ? 's' : ''}'
          : '$years year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final weeks = age.inDays ~/ 7;
      if (weeks > 0) {
        return '$weeks week${weeks > 1 ? 's' : ''}';
      } else {
        return '${age.inDays} day${age.inDays > 1 ? 's' : ''}';
      }
    }
  }
  
  /// Parse pet type from string
  static PetType _parseType(String? typeName) {
    switch (typeName?.toLowerCase()) {
      case 'dog':
        return PetType.dog;
      case 'cat':
        return PetType.cat;
      case 'bird':
        return PetType.bird;
      case 'fish':
        return PetType.fish;
      case 'reptile':
        return PetType.reptile;
      case 'small_pet':
        return PetType.smallPet;
      default:
        return PetType.other;
    }
  }
  
  /// Parse pet gender from string
  static PetGender _parseGender(String? genderName) {
    switch (genderName?.toLowerCase()) {
      case 'male':
        return PetGender.male;
      case 'female':
        return PetGender.female;
      default:
        return PetGender.unknown;
    }
  }
}

/// Pet types
enum PetType {
  dog,
  cat,
  bird,
  fish,
  reptile,
  smallPet,
  other,
}

/// Pet genders
enum PetGender {
  male,
  female,
  unknown,
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