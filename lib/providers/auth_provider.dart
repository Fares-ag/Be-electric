import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/user.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check Supabase authentication first
      final supabaseAuthService = SupabaseAuthService.instance;
      if (supabaseAuthService.isSignedIn) {
        final supabaseUser = await supabaseAuthService.getCurrentAppUser();
        if (supabaseUser != null) {
          // Get user from Supabase
          final dbUser = await SupabaseDatabaseService.instance
              .getUserByEmail(supabaseUser.email);
          _currentUser = dbUser ?? supabaseUser;
          _isAuthenticated = true;
          notifyListeners();
          return;
        }
      }

      // Fallback to local storage check
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');

      if (userId != null) {
        // Load latest user from Supabase to get up-to-date role
        final storedUser =
            await SupabaseDatabaseService.instance.getUserById(userId);
        if (storedUser != null) {
          _currentUser = storedUser;
          _isAuthenticated = true;
          debugPrint(
            '🔄 Session restored - User: ${storedUser.name}, Role: ${storedUser.role}',
          );
        } else {
          debugPrint(
            '⚠️ User ID $userId not found in Firestore, clearing session',
          );
          await prefs.remove('current_user_id');
        }
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      // Set default state if there's an error
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return false;
      }

      // Try Supabase authentication first
      try {
        final supabaseAuthService = SupabaseAuthService.instance;
        final supabaseUser =
            await supabaseAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (supabaseUser != null) {
          // Get user from Supabase
          var dbUser = await SupabaseDatabaseService.instance.getUserByEmail(email);

          debugPrint('🔑 Login: Supabase UID: ${supabaseUser.id}');
          debugPrint('🔑 Login: Supabase User: ${dbUser?.name} (ID: ${dbUser?.id})');

          // If user doesn't exist in Supabase, create them (if auto-creation is enabled)
          if (dbUser == null) {
            // Check if this is the first user (bootstrap scenario)
            final allUsers = await SupabaseDatabaseService.instance.getAllUsers();
            final isFirstUser = allUsers.isEmpty;
            
            // Allow auto-creation if:
            // 1. Auto-creation is enabled, OR
            // 2. This is the first user in the system (bootstrap - allow first admin)
            if (AppConfig.autoCreateUsersOnLogin || isFirstUser) {
              if (isFirstUser) {
                debugPrint(
                  '🌱 First user detected - creating admin user for bootstrap',
                );
                // First user should be admin for initial setup
                final bootstrapUser = supabaseUser.copyWith(
                  role: 'admin',
                );
                // Create user and get the readable ID
                final readableId = await SupabaseDatabaseService.instance.createUser(bootstrapUser);
                // Reload user from Supabase to get the complete user object with readable ID
                dbUser = await SupabaseDatabaseService.instance.getUserById(readableId);
                debugPrint(
                  '✅ Created first admin user: ${dbUser?.name} (ID: ${dbUser?.id})',
                );
              } else {
                debugPrint('⚠️ User not found in Supabase, creating...');
                // Create user and get the readable ID
                final readableId = await SupabaseDatabaseService.instance.createUser(supabaseUser);
                // Reload user from Supabase to get the complete user object with readable ID
                dbUser = await SupabaseDatabaseService.instance.getUserById(readableId);
                debugPrint(
                  '✅ Created user in Supabase: ${dbUser?.name} (ID: ${dbUser?.id})',
                );
              }
            } else {
              debugPrint(
                '⚠️ User authenticated in Supabase Auth but not found in users table. '
                'Auto-creation is disabled. User must be created by an admin before they can log in.',
              );
              _isLoading = false;
              notifyListeners();
              return false; // Login failed - user doesn't exist
            }
          }

          _currentUser = dbUser;
          _isAuthenticated = true;

          debugPrint('🔑 Login: Using user ID: ${_currentUser!.id}');

          // Save user session
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user_id', _currentUser!.id);

          // Set loading to false BEFORE notifying listeners
          _isLoading = false;
          debugPrint(
            '✅ AuthProvider: Login successful - isAuthenticated=$_isAuthenticated, '
            'isLoading=$_isLoading, user=${_currentUser!.name}',
          );
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint('Supabase authentication error: $e');
        // Continue to try demo users as fallback
      }

      // Fallback to demo users for testing
      if (_isDemoUser(email, password)) {
        // FIRST: Try to load user from Supabase (they might have been updated)
        final dbUser = await SupabaseDatabaseService.instance.getUserByEmail(email);

        if (dbUser != null) {
          // User exists in Supabase - use their current role!
          _currentUser = dbUser;
          debugPrint(
            '✅ Loaded demo user from Firestore with role: ${dbUser.role}',
          );
        } else {
          // User doesn't exist - create new demo user
          _currentUser = _createDemoUser(email);
          debugPrint(
            '✅ Created new demo user with role: ${_currentUser!.role}',
          );
        }

        _isAuthenticated = true;

        // Save user session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_id', _currentUser!.id);

        // Set loading to false BEFORE notifying listeners
        _isLoading = false;
        debugPrint(
          '✅ AuthProvider: Demo user login successful - isAuthenticated=$_isAuthenticated, '
          'isLoading=$_isLoading, user=${_currentUser!.name}',
        );
        notifyListeners();
        return true;
      }

      // Try to authenticate with database (skip on web)
      if (!kIsWeb) {
        try {
          final user = await _authenticateWithDatabase(email, password);
          if (user != null) {
            _currentUser = user;
            _isAuthenticated = true;

            // Save user session
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('current_user_id', _currentUser!.id);

            // Set loading to false BEFORE notifying listeners
            _isLoading = false;
            debugPrint(
              '✅ AuthProvider: Database auth successful - isAuthenticated=$_isAuthenticated, '
              'isLoading=$_isLoading, user=${_currentUser!.name}',
            );
            notifyListeners();
            return true;
          }
        } catch (e) {
          debugPrint('Database authentication error: $e');
          // Continue to return false if database auth fails
        }
      }

      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isDemoUser(String email, String password) {
    // Use AppConfig for demo user validation (only works in demo mode)
    return AppConfig.isDemoUser(email, password);
  }

  User _createDemoUser(String email) {
    // Get demo user from AppConfig
    final demoUser = AppConfig.getDemoUserByEmail(email);

    if (demoUser == null) {
      // Fallback for unknown demo user
      return User(
        id: 'demo_${email.split('@')[0]}_001',
        email: email,
        name: 'Demo User',
        role: 'technician',
        department: 'Maintenance',
        createdAt: DateTime.now(),
      );
    }

    return User(
      id: 'demo_${email.split('@')[0]}_001',
      email: email,
      name: demoUser['name'] ?? 'Demo User',
      role: demoUser['role'] ?? 'technician',
      department: demoUser['department'] ?? 'Maintenance',
      createdAt: DateTime.now(),
    );
  }

  Future<User?> _authenticateWithDatabase(String email, String password) async {
    try {
      // Use Firestore to check created users
      final users = await SupabaseDatabaseService.instance.getAllUsers();
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // For demo purposes, accept any password for created users
      // In production, you'd verify the password hash via Firebase Auth
      return user;
    } catch (e) {
      debugPrint('Firestore authentication error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out from Supabase
      final supabaseAuthService = SupabaseAuthService.instance;
      await supabaseAuthService.signOut();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');

      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get isManager => _currentUser?.isManager ?? false;
  bool get isTechnician => _currentUser?.isTechnician ?? false;

  /// Set user directly (for updates)
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Get all users (for technician assignment)
  Future<List<User>> getAllUsers() async {
    try {
      return await SupabaseDatabaseService.instance.getAllUsers();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }
}
