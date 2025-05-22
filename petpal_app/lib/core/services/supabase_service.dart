import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petpal/config/app_config.dart';
import 'package:uuid/uuid.dart';

/// A service for interacting with Supabase
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // Authentication methods
  
  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.petpal.app://login-callback',
    );
  }
  
  /// Sign in with Apple
  Future<AuthResponse> signInWithApple() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'io.petpal.app://login-callback',
    );
  }
  
  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
      },
    );
    
    // Create user profile on sign up
    if (response.user != null) {
      await _client.from('users').upsert({
        'id': response.user!.id,
        'email': email,
        'display_name': displayName,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    
    return response;
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
  
  /// Update password
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(
      UserAttributes(password: password),
    );
  }
  
  /// Get current user
  User? get currentUser => _client.auth.currentUser;
  
  /// Get current user id
  String? get currentUserId => currentUser?.id;
  
  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;
  
  /// Stream of auth state changes
  Stream<AuthState> get authStateChange => _client.auth.onAuthStateChange;

  // Database methods
  
  /// Fetch data with query
  Future<List<Map<String, dynamic>>> fetch(
    String table, {
    String? column,
    dynamic value,
    int? limit,
    int? offset,
    String? orderBy,
    bool ascending = false,
  }) async {
    var query = _client.from(table).select();
    
    if (column != null && value != null) {
      query = query.eq(column, value);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 10) - 1);
    }
    
    if (orderBy != null) {
      query = ascending ? query.order(orderBy) : query.order(orderBy, ascending: false);
    }
    
    return await query;
  }
  
  /// Fetch a single item by ID
  Future<Map<String, dynamic>?> fetchById(
    String table,
    String id,
  ) async {
    final response = await _client.from(table).select().eq('id', id).maybeSingle();
    return response;
  }
  
  /// Create an item
  Future<Map<String, dynamic>> create(
    String table,
    Map<String, dynamic> data,
  ) async {
    // Generate a UUID if not provided
    if (!data.containsKey('id')) {
      data['id'] = _uuid.v4();
    }
    
    final response = await _client.from(table).insert(data).select().single();
    return response;
  }
  
  /// Update an item
  Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.from(table).update(data).eq('id', id).select().single();
    return response;
  }
  
  /// Delete an item
  Future<void> delete(
    String table,
    String id,
  ) async {
    await _client.from(table).delete().eq('id', id);
  }
  
  /// Subscribe to real-time changes
  Stream<List<Map<String, dynamic>>> subscribe(
    String table, {
    String? column,
    dynamic value,
  }) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    
    // Initial fetch
    fetch(table, column: column, value: value).then((data) {
      if (!controller.isClosed) controller.add(data);
    }).catchError((error) {
      if (!controller.isClosed) controller.addError(error);
    });
    
    // Subscribe to changes
    final subscription = _client
        .from(table)
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (!controller.isClosed) {
            if (column != null && value != null) {
              // Filter data if column and value are provided
              final filteredData = data.where((item) => item[column] == value).toList();
              controller.add(filteredData);
            } else {
              controller.add(data);
            }
          }
        });
    
    // Clean up when the stream is canceled
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };
    
    return controller.stream;
  }
  
  // Storage methods
  
  /// Upload a file
  Future<String> uploadFile(
    File file,
    String path,
  ) async {
    final fileName = '${_uuid.v4()}_${file.path.split('/').last}';
    final filePath = '$path/$fileName';
    
    await _client.storage.from('petpal').upload(
      filePath,
      file,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
      ),
    );
    
    return filePath;
  }
  
  /// Get a file URL
  String getFileUrl(String path) {
    return _client.storage.from('petpal').getPublicUrl(path);
  }
  
  /// Delete a file
  Future<void> deleteFile(String path) async {
    await _client.storage.from('petpal').remove([path]);
  }
  
  // RPC calls
  
  /// Call a stored procedure
  Future<dynamic> callRpc(
    String function,
    Map<String, dynamic> params,
  ) async {
    return await _client.rpc(function, params: params);
  }
}