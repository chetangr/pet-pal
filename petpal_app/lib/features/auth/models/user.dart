import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  Id get isarId => fastHash(id);
  
  /// Unique ID from Supabase Auth
  @Index(unique: true)
  final String id;
  
  /// Email address
  final String email;
  
  /// Display name
  final String displayName;
  
  /// Profile photo URL
  final String? avatarUrl;
  
  /// Phone number
  final String? phone;
  
  /// When the user was created
  final DateTime createdAt;
  
  /// Subscription tier (free, premium, pro)
  final String subscriptionTier;
  
  /// Additional user settings
  final Map<String, dynamic> settings;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.phone,
    required this.createdAt,
    required this.subscriptionTier,
    required this.settings,
  });
  
  /// Create a copy of this user with optional new values
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? phone,
    DateTime? createdAt,
    String? subscriptionTier,
    Map<String, dynamic>? settings,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      settings: settings ?? this.settings,
    );
  }
  
  /// Convert user to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'subscription_tier': subscriptionTier,
      'settings': settings,
    };
  }
  
  /// Create user from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'],
      phone: json['phone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      subscriptionTier: json['subscription_tier'] ?? 'free',
      settings: json['settings'] ?? {},
    );
  }
  
  /// Create user from Supabase Auth
  factory User.fromSupabaseAuth(Map<String, dynamic> userData) {
    return User(
      id: userData['id'],
      email: userData['email'] ?? '',
      displayName: userData['user_metadata']?['display_name'] ?? '',
      avatarUrl: userData['user_metadata']?['avatar_url'],
      phone: userData['phone'],
      createdAt: userData['created_at'] != null
          ? DateTime.parse(userData['created_at'])
          : DateTime.now(),
      subscriptionTier: 'free',
      settings: {},
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