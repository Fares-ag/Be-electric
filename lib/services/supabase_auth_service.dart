// Supabase Authentication Service
// Handles user authentication with Supabase Auth

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;

class SupabaseAuthService {
  SupabaseAuthService._();
  static SupabaseAuthService? _instance;
  static SupabaseAuthService get instance =>
      _instance ??= SupabaseAuthService._();

  /// Initialize Supabase Auth Service
  Future<void> initialize() async {
    try {
      print('🔐 Supabase Auth: Initializing...');
      // Supabase is initialized in main.dart
      print('🔐 Supabase Auth: Initialized successfully');
    } catch (e) {
      print('❌ Supabase Auth: Initialization error: $e');
    }
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Get current Supabase user
  User? get currentSupabaseUser => _client.auth.currentUser;

  /// Get current user (for compatibility)
  User? get currentUser => _client.auth.currentUser;

  /// Get user email
  String? get userEmail => _client.auth.currentUser?.email;

  /// Get current app user from Supabase user
  Future<app_user.User?> getCurrentAppUser() async {
    final supabaseUser = currentSupabaseUser;
    if (supabaseUser == null) return null;

    // Get user metadata from Supabase
    final userMetadata = supabaseUser.userMetadata;
    final appMetadata = supabaseUser.appMetadata;

    return app_user.User(
      id: supabaseUser.id,
      name: userMetadata?['name'] ?? 
            userMetadata?['full_name'] ?? 
            (supabaseUser.email?.split('@').first ?? 'Unknown User'),
      email: supabaseUser.email ?? '',
      role: userMetadata?['role'] ?? appMetadata?['role'] ?? _getUserRoleFromEmail(supabaseUser.email ?? ''),
      department: userMetadata?['department'] ?? appMetadata?['department'] ?? _getUserDepartmentFromEmail(supabaseUser.email ?? ''),
      createdAt: DateTime.parse(supabaseUser.createdAt),
      lastLoginAt: supabaseUser.lastSignInAt != null 
          ? DateTime.parse(supabaseUser.lastSignInAt!) 
          : null,
    );
  }

  /// Sign in with email and password
  Future<app_user.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Supabase Auth: Signing in with email: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('🔐 Supabase Auth: Sign in successful');
        return await getCurrentAppUser();
      }

      return null;
    } catch (e) {
      print('❌ Supabase Auth: Sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign up with email and password
  Future<app_user.User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    required String department,
    String? phoneNumber,
  }) async {
    try {
      print('🔐 Supabase Auth: Creating account for: $email');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
          'department': department,
          if (phoneNumber != null) 'phone': phoneNumber,
        },
      );

      if (response.user != null) {
        print('🔐 Supabase Auth: Account created successfully');
        return await getCurrentAppUser();
      }

      return null;
    } catch (e) {
      print('❌ Supabase Auth: Sign up error: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      print('🔐 Supabase Auth: Signing out');
      await _client.auth.signOut();
      print('🔐 Supabase Auth: Sign out successful');
    } catch (e) {
      print('❌ Supabase Auth: Sign out error: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      print('🔐 Supabase Auth: Sending password reset to: $email');
      await _client.auth.resetPasswordForEmail(email);
      print('🔐 Supabase Auth: Password reset email sent');
    } catch (e) {
      print('❌ Supabase Auth: Password reset error: $e');
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
  }) async {
    try {
      final user = currentSupabaseUser;
      if (user == null) throw Exception('No user signed in');

      final updates = <String, dynamic>{};
      if (name != null) {
        updates['name'] = name;
      }
      if (phoneNumber != null) {
        updates['phone'] = phoneNumber;
      }

      if (updates.isNotEmpty) {
        await _client.auth.updateUser(
          UserAttributes(data: updates),
        );
      }

      print('🔐 Supabase Auth: Profile updated successfully');
    } catch (e) {
      print('❌ Supabase Auth: Profile update error: $e');
      throw Exception('Profile update failed: $e');
    }
  }

  /// Get user role from email
  String _getUserRoleFromEmail(String email) {
    final emailLower = email.toLowerCase();
    if (emailLower.contains('admin')) return 'admin';
    if (emailLower.contains('manager')) return 'manager';
    if (emailLower.contains('technician')) return 'technician';
    return 'requestor';
  }

  /// Get user department from email
  String _getUserDepartmentFromEmail(String email) {
    final emailLower = email.toLowerCase();
    if (emailLower.contains('admin')) return 'Administration';
    if (emailLower.contains('manager')) return 'Management';
    return 'Maintenance';
  }

  /// Check if user is signed in
  bool get isSignedIn => currentSupabaseUser != null;

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Get user ID token (access token)
  Future<String?> getIdToken() async {
    try {
      final session = _client.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      print('❌ Supabase Auth: Error getting ID token: $e');
      return null;
    }
  }

  /// Refresh user token
  Future<void> refreshToken() async {
    try {
      await _client.auth.refreshSession();
      print('🔐 Supabase Auth: Token refreshed');
    } catch (e) {
      print('❌ Supabase Auth: Error refreshing token: $e');
    }
  }

  /// Sign in anonymously (not supported in Supabase, returns null)
  Future<app_user.User?> signInAnonymously() async {
    try {
      print('🔐 Supabase Auth: Anonymous sign in not supported in Supabase');
      // Supabase doesn't support anonymous auth by default
      // You would need to create a guest user or use a different approach
      return null;
    } catch (e) {
      print('❌ Supabase Auth: Anonymous sign in error: $e');
      throw Exception('Anonymous sign in not supported');
    }
  }

  /// Ensure user is authenticated
  Future<bool> ensureAuthenticated() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Supabase Auth: Authentication check failed: $e');
      return false;
    }
  }
}

