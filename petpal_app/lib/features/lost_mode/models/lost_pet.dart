import 'package:isar/isar.dart';

part 'lost_pet.g.dart';

@collection
class LostPet {
  Id get isarId => fastHash(id);
  
  /// Unique ID
  @Index(unique: true)
  final String id;
  
  /// Pet ID that is lost
  @Index()
  final String petId;
  
  /// Current status of the lost pet
  @Enumerated(EnumType.name)
  final LostPetStatus status;
  
  /// When the pet was reported lost
  final DateTime reportedAt;
  
  /// When the pet was found (if applicable)
  final DateTime? foundAt;
  
  /// Last known location (latitude)
  final double? lastLatitude;
  
  /// Last known location (longitude)
  final double? lastLongitude;
  
  /// Last location update timestamp
  final DateTime? lastLocationUpdate;
  
  /// Additional details about the lost pet
  final String? details;
  
  /// Contact information for the pet owner
  final String contactInfo;
  
  /// Who reported the pet as lost (user ID)
  final String reportedBy;
  
  /// Alert radius in kilometers
  final double alertRadius;
  
  /// Whether to share the lost pet alert publicly
  final bool isPublic;
  
  /// Users who have been notified about this lost pet
  final List<String> notifiedUsers;
  
  /// When the record was created
  final DateTime createdAt;
  
  /// When the record was last updated
  final DateTime updatedAt;

  LostPet({
    required this.id,
    required this.petId,
    required this.status,
    required this.reportedAt,
    this.foundAt,
    this.lastLatitude,
    this.lastLongitude,
    this.lastLocationUpdate,
    this.details,
    required this.contactInfo,
    required this.reportedBy,
    required this.alertRadius,
    required this.isPublic,
    required this.notifiedUsers,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Create a copy of this lost pet with optional new values
  LostPet copyWith({
    String? id,
    String? petId,
    LostPetStatus? status,
    DateTime? reportedAt,
    DateTime? foundAt,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? lastLocationUpdate,
    String? details,
    String? contactInfo,
    String? reportedBy,
    double? alertRadius,
    bool? isPublic,
    List<String>? notifiedUsers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LostPet(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      status: status ?? this.status,
      reportedAt: reportedAt ?? this.reportedAt,
      foundAt: foundAt ?? this.foundAt,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      details: details ?? this.details,
      contactInfo: contactInfo ?? this.contactInfo,
      reportedBy: reportedBy ?? this.reportedBy,
      alertRadius: alertRadius ?? this.alertRadius,
      isPublic: isPublic ?? this.isPublic,
      notifiedUsers: notifiedUsers ?? this.notifiedUsers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Mark this pet as found
  LostPet markAsFound() {
    return copyWith(
      status: LostPetStatus.found,
      foundAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Update the location of this lost pet
  LostPet updateLocation(double latitude, double longitude) {
    return copyWith(
      lastLatitude: latitude,
      lastLongitude: longitude,
      lastLocationUpdate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Add a user to the notified users list
  LostPet addNotifiedUser(String userId) {
    if (notifiedUsers.contains(userId)) {
      return this;
    }
    
    final updatedNotifiedUsers = List<String>.from(notifiedUsers)..add(userId);
    
    return copyWith(
      notifiedUsers: updatedNotifiedUsers,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Convert lost pet to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'status': status.name,
      'reported_at': reportedAt.toIso8601String(),
      'found_at': foundAt?.toIso8601String(),
      'last_latitude': lastLatitude,
      'last_longitude': lastLongitude,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
      'details': details,
      'contact_info': contactInfo,
      'reported_by': reportedBy,
      'alert_radius': alertRadius,
      'is_public': isPublic,
      'notified_users': notifiedUsers,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  /// Create lost pet from JSON
  factory LostPet.fromJson(Map<String, dynamic> json) {
    return LostPet(
      id: json['id'],
      petId: json['pet_id'],
      status: _parseStatus(json['status']),
      reportedAt: DateTime.parse(json['reported_at']),
      foundAt: json['found_at'] != null 
          ? DateTime.parse(json['found_at']) 
          : null,
      lastLatitude: json['last_latitude'],
      lastLongitude: json['last_longitude'],
      lastLocationUpdate: json['last_location_update'] != null 
          ? DateTime.parse(json['last_location_update']) 
          : null,
      details: json['details'],
      contactInfo: json['contact_info'],
      reportedBy: json['reported_by'],
      alertRadius: json['alert_radius'] is int 
          ? json['alert_radius'].toDouble() 
          : json['alert_radius'],
      isPublic: json['is_public'],
      notifiedUsers: json['notified_users'] != null 
          ? List<String>.from(json['notified_users']) 
          : [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  /// Get duration since the pet was reported lost
  Duration getLostDuration() {
    if (status == LostPetStatus.found && foundAt != null) {
      return foundAt!.difference(reportedAt);
    }
    
    return DateTime.now().difference(reportedAt);
  }
  
  /// Check if the pet has location information
  bool get hasLocation => lastLatitude != null && lastLongitude != null;
  
  /// Parse status from string
  static LostPetStatus _parseStatus(String? statusName) {
    switch (statusName?.toLowerCase()) {
      case 'found':
        return LostPetStatus.found;
      case 'searching':
      default:
        return LostPetStatus.searching;
    }
  }
}

/// Status of a lost pet
enum LostPetStatus {
  searching,
  found,
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