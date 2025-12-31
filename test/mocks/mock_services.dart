// Mock service implementations for tests

import 'dart:async';

import 'package:qauto_cmms/models/user.dart';
import 'package:qauto_cmms/models/work_order.dart';

/// Mock Firestore Service
class MockFirestoreService {
  bool _isAuthenticated = true;
  final Map<String, dynamic> _data = {};

  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
  }

  Future<void> createWorkOrder(WorkOrder workOrder) async {
    if (!_isAuthenticated) throw Exception('Not authenticated');
    _data[workOrder.id] = workOrder;
  }

  Future<void> updateWorkOrder(String id, WorkOrder workOrder) async {
    if (!_isAuthenticated) throw Exception('Not authenticated');
    _data[id] = workOrder;
  }

  Future<void> deleteWorkOrder(String id) async {
    if (!_isAuthenticated) throw Exception('Not authenticated');
    _data.remove(id);
  }

  Future<WorkOrder?> getWorkOrder(String id) async => _data[id] as WorkOrder?;

  void clear() {
    _data.clear();
  }
}

/// Mock Database Service
class MockDatabaseService {
  final Map<String, List<dynamic>> _tables = {
    'users': [],
    'work_orders': [],
    'pm_tasks': [],
    'assets': [],
    'inventory_items': [],
  };

  Future<List<User>> getAllUsers() async =>
      List<User>.from(_tables['users'] ?? []);

  Future<void> createUser(User user) async {
    _tables['users']!.add(user);
  }

  Future<void> updateUser(User user) async {
    final users = _tables['users']!;
    final index = users.indexWhere((u) => (u as User).id == user.id);
    if (index != -1) {
      users[index] = user;
    }
  }

  Future<void> deleteUser(String userId) async {
    _tables['users']!.removeWhere((u) => (u as User).id == userId);
  }

  Future<User?> getUserById(String id) async {
    final users = _tables['users']!;
    try {
      return users.firstWhere((u) => (u as User).id == id) as User;
    } catch (e) {
      return null;
    }
  }

  Future<List<WorkOrder>> getAllWorkOrders() async =>
      List<WorkOrder>.from(_tables['work_orders'] ?? []);

  Future<void> createWorkOrder(WorkOrder workOrder) async {
    _tables['work_orders']!.add(workOrder);
  }

  void clear() {
    _tables.forEach((key, value) {
      value.clear();
    });
  }
}

/// Mock Auth Service
class MockAuthService {
  User? _currentUser;
  bool _isSignedIn = false;

  bool get isSignedIn => _isSignedIn;
  User? get currentUser => _currentUser;

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate successful login
    if (email.isNotEmpty && password.isNotEmpty) {
      _currentUser = User(
        id: 'test_user_001',
        email: email,
        name: 'Test User',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      _isSignedIn = true;
      return _currentUser;
    }
    return null;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _isSignedIn = false;
  }

  Future<User?> getCurrentAppUser() async => _currentUser;
}

/// Mock Notification Service
class MockNotificationService {
  final List<Map<String, dynamic>> sentNotifications = [];

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    sentNotifications.add({
      'userId': userId,
      'title': title,
      'body': body,
      'data': data,
      'sentAt': DateTime.now(),
    });
  }

  void clear() {
    sentNotifications.clear();
  }

  int get notificationCount => sentNotifications.length;
}
