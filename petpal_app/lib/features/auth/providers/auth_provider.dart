import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petpal/core/services/supabase_service.dart';
import 'package:petpal/core/services/local_storage_service.dart';
import 'package:petpal/features/auth/models/user.dart' as app;

/// Provider for authentication state
final authStateProvider = StreamProvider<app.User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.userStream;
});

/// Provider for current user
final currentUserProvider = Provider<app.User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for checking if user is premium subscriber
final isPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.subscriptionTier == 'premium' || user?.subscriptionTier == 'pro';
});

/// Provider for checking if user is pro subscriber
final isProProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.subscriptionTier == 'pro';
});

/// Provider for SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Provider for LocalStorageService
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);
  return AuthService(
    supabaseService: supabaseService,
    localStorageService: localStorageService,
  );
});

/// Service for handling authentication
class AuthService {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  
  final _userController = StreamController<app.User?>.broadcast();
  
  /// Stream of authenticated user
  Stream<app.User?> get userStream => _userController.stream;
  
  /// Current authenticated user
  app.User? _currentUser;
  app.User? get currentUser => _currentUser;
  
  StreamSubscription? _authSubscription;
  
  AuthService({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
  })  : _supabaseService = supabaseService,
        _localStorageService = localStorageService {
    _init();
  }
  
  /// Initialize the auth service
  Future<void> _init() async {
    await _localStorageService.init();
    
    // Load user from local storage
    final storedUser = await _localStorageService.getCurrentUser();
    if (storedUser != null) {
      _currentUser = storedUser;
      _userController.add(_currentUser);
    }
    
    // Listen to auth state changes
    _authSubscription = _supabaseService.authStateChange.listen(_handleAuthChange);
  }
  
  /// Handle auth state changes
  Future<void> _handleAuthChange(AuthState state) async {
    final session = state.session;
    final event = state.event;
    
    if (event == AuthChangeEvent.signedIn && session != null) {
      // User signed in, fetch user data
      await _fetchAndUpdateUser(session.user);
    } else if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.tokenRefreshFailure) {
      // User signed out or token expired
      await _clearUser();
    } else if (event == AuthChangeEvent.userUpdated && session != null) {
      // User updated, update user data
      await _fetchAndUpdateUser(session.user);
    }
  }
  
  /// Fetch user data and update local storage
  Future<void> _fetchAndUpdateUser(User supabaseUser) async {
    try {
      // Fetch user profile from Supabase
      final userData = await _supabaseService.fetchById('users', supabaseUser.id);
      
      if (userData != null) {
        // User exists in database
        _currentUser = app.User.fromJson(userData);
      } else {
        // User not in database yet, create from auth data
        _currentUser = app.User.fromSupabaseAuth(supabaseUser.toJson());
        
        // Save to Supabase
        await _supabaseService.create('users', _currentUser!.toJson());
      }
      
      // Save to local storage
      await _localStorageService.saveCurrentUser(_currentUser!);
      
      // Notify listeners
      _userController.add(_currentUser);
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      // Still create a basic user from auth to avoid null issues
      _currentUser = app.User.fromSupabaseAuth(supabaseUser.toJson());
      _userController.add(_currentUser);
    }
  }
  
  /// Clear user data
  Future<void> _clearUser() async {
    _currentUser = null;
    await _localStorageService.clearCurrentUser();
    _userController.add(null);
  }
  
  /// Sign in with email and password
  Future<app.User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      
      return _currentUser;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }
  
  /// Sign in with Google
  Future<app.User?> signInWithGoogle() async {
    try {
      await _supabaseService.signInWithGoogle();
      
      return _currentUser;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }
  
  /// Sign in with Apple
  Future<app.User?> signInWithApple() async {
    try {
      await _supabaseService.signInWithApple();
      
      return _currentUser;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      rethrow;
    }
  }
  
  /// Sign up with email and password
  Future<app.User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await _supabaseService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      return _currentUser;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseService.resetPassword(email);
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    }
  }
  
  /// Update user profile
  Future<app.User?> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? phone,
    Map<String, dynamic>? settings,
  }) async {
    if (_currentUser == null) return null;
    
    try {
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName,
        avatarUrl: avatarUrl,
        phone: phone,
        settings: settings != null 
            ? {..._currentUser!.settings, ...settings}
            : _currentUser!.settings,
      );
      
      // Update in Supabase
      await _supabaseService.update(
        'users',
        _currentUser!.id,
        updatedUser.toJson(),
      );
      
      // Update local user
      _currentUser = updatedUser;
      
      // Save to local storage
      await _localStorageService.saveCurrentUser(_currentUser!);
      
      // Notify listeners
      _userController.add(_currentUser);
      
      return _currentUser;
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }
  
  /// Update subscription tier
  Future<app.User?> updateSubscription(String tier) async {
    if (_currentUser == null) return null;
    
    try {
      final updatedUser = _currentUser!.copyWith(
        subscriptionTier: tier,
      );
      
      // Update in Supabase
      await _supabaseService.update(
        'users',
        _currentUser!.id,
        {'subscription_tier': tier},
      );
      
      // Update local user
      _currentUser = updatedUser;
      
      // Save to local storage
      await _localStorageService.saveCurrentUser(_currentUser!);
      
      // Notify listeners
      _userController.add(_currentUser);
      
      return _currentUser;
    } catch (e) {
      debugPrint('Update subscription error: $e');
      rethrow;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _userController.close();
  }
}