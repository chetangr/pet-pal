import 'package:isar/isar.dart';

part 'household.g.dart';

@collection
class Household {
  Id get isarId => fastHash(id);
  
  /// Unique ID
  @Index(unique: true)
  final String id;
  
  /// Household name
  final String name;
  
  /// Owner ID (user who created the household)
  final String ownerId;
  
  /// When the household was created
  final DateTime createdAt;
  
  /// List of members with their roles
  final List<HouseholdMember> members;

  Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.members,
  });
  
  /// Create a copy of this household with optional new values
  Household copyWith({
    String? id,
    String? name,
    String? ownerId,
    DateTime? createdAt,
    List<HouseholdMember>? members,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
    );
  }
  
  /// Convert household to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'members': members.map((member) => member.toJson()).toList(),
    };
  }
  
  /// Create household from JSON
  factory Household.fromJson(Map<String, dynamic> json) {
    final List<dynamic> membersList = json['members'] ?? [];
    
    return Household(
      id: json['id'],
      name: json['name'],
      ownerId: json['owner_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      members: membersList
          .map((member) => HouseholdMember.fromJson(member))
          .toList(),
    );
  }
}

@embedded
class HouseholdMember {
  /// User ID
  late String userId;
  
  /// User's role in the household
  @Enumerated(EnumType.name)
  late HouseholdRole role;
  
  /// When the user joined the household
  late DateTime joinedAt;
  
  /// User's display name (for convenience)
  late String displayName;
  
  /// User's avatar URL (for convenience)
  String? avatarUrl;
  
  HouseholdMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.displayName,
    this.avatarUrl,
  });
  
  /// Convert member to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
      'display_name': displayName,
      'avatar_url': avatarUrl,
    };
  }
  
  /// Create member from JSON
  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      userId: json['user_id'],
      role: _parseRole(json['role']),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
  
  /// Parse role from string
  static HouseholdRole _parseRole(String? roleName) {
    switch (roleName) {
      case 'owner':
        return HouseholdRole.owner;
      case 'caretaker':
        return HouseholdRole.caretaker;
      case 'viewer':
        return HouseholdRole.viewer;
      case 'vet':
        return HouseholdRole.vet;
      default:
        return HouseholdRole.viewer;
    }
  }
}

/// Roles in the household
enum HouseholdRole {
  owner,
  caretaker,
  viewer,
  vet,
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