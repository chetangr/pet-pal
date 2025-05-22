import 'package:isar/isar.dart';

part 'pending_change.g.dart';

/// Model representing a pending change for synchronization
@collection
class PendingChange {
  Id get isarId => fastHash(id);
  
  /// Unique ID for the change
  @Index(unique: true)
  final String id;
  
  /// The table (collection) that the change affects
  final String table;
  
  /// The ID of the item being changed
  final String itemId;
  
  /// The data for the change (empty for deletions)
  final Map<String, dynamic> data;
  
  /// The type of change (create, update, delete)
  final String changeType;
  
  /// The timestamp when the change was created
  final DateTime timestamp;
  
  /// Whether the change has been synchronized
  bool synced;
  
  PendingChange({
    required this.id,
    required this.table,
    required this.itemId,
    required this.data,
    required this.changeType,
    required this.timestamp,
    this.synced = false,
  });
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