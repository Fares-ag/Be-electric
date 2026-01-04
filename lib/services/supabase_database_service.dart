// Supabase Database Service
// Handles cloud database operations with Supabase Postgres

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/asset.dart';
import '../models/company.dart';
import '../models/inventory_item.dart';
import '../models/parts_request.dart';
import '../models/pm_task.dart';
import '../models/purchase_order.dart';
import '../models/user.dart' as app_user;
import '../models/work_order.dart';
import '../models/workflow_models.dart';
import '../utils/deterministic_id_generator.dart';
import '../utils/validators.dart';
import 'audit_logging_service.dart';
import 'enhanced_inventory_service.dart';
import 'enhanced_notification_service.dart';
import 'escalation_service.dart';

class SupabaseDatabaseService {
  SupabaseDatabaseService._();
  static SupabaseDatabaseService? _instance;
  static SupabaseDatabaseService get instance =>
      _instance ??= SupabaseDatabaseService._();

  /// Initialize Supabase Database Service
  Future<void> initialize() async {
    try {
      debugPrint('Supabase Database: Initializing...');
      debugPrint('Supabase Database: Initialized successfully');
    } on Exception catch (e) {
      debugPrint('Supabase Database: Initialization error: $e');
    }
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Get current user ID
  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get _isAuthenticated => _currentUserId != null;

  /// Convert data map to Supabase format (handle DateTime conversion)
  Map<String, dynamic> convertToSupabaseMap(Map<String, dynamic> dataMap) {
    final supabaseMap = <String, dynamic>{};
    
    for (final entry in dataMap.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value == null) {
        supabaseMap[key] = null;
      } else if (value is DateTime) {
        supabaseMap[key] = value.toIso8601String();
      } else if (value.toString().contains('Timestamp')) {
        // Handle legacy Timestamp format (for backward compatibility)
        try {
          final timestampStr = value.toString();
          final match = RegExp(r'Timestamp\(seconds=(\d+), nanoseconds=(\d+)\)')
              .firstMatch(timestampStr);
          if (match != null) {
            final seconds = int.parse(match.group(1)!);
            final nanoseconds = int.parse(match.group(2)!);
            final dateTime = DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds / 1000000).round(),
            );
            supabaseMap[key] = dateTime.toIso8601String();
          } else {
            supabaseMap[key] = value;
          }
        } catch (e) {
          supabaseMap[key] = value;
        }
      } else if (value is Map) {
        supabaseMap[key] = convertToSupabaseMap(Map<String, dynamic>.from(value));
      } else if (value is List) {
        supabaseMap[key] = value.map((item) {
          if (item is Map) {
            return convertToSupabaseMap(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        supabaseMap[key] = value;
      }
    }
    
    return supabaseMap;
  }

  /// Convert Supabase map to data map (handle DateTime conversion)
  Map<String, dynamic> convertFromSupabaseMap(Map<String, dynamic> supabaseMap) {
    final dataMap = <String, dynamic>{};
    
    for (final entry in supabaseMap.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value == null) {
        dataMap[key] = null;
      } else if (value is String && _isIso8601Date(value)) {
        // Convert ISO8601 string to DateTime (models will handle conversion)
        dataMap[key] = DateTime.tryParse(value) ?? value;
      } else if (value is Map) {
        dataMap[key] = convertFromSupabaseMap(Map<String, dynamic>.from(value));
      } else if (value is List) {
        dataMap[key] = value.map((item) {
          if (item is Map) {
            return convertFromSupabaseMap(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        dataMap[key] = value;
      }
    }
    
    return dataMap;
  }

  bool _isIso8601Date(String value) {
    try {
      DateTime.parse(value);
      return value.contains('T') || value.contains('-');
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // WORK ORDERS
  // ============================================================================

  /// Create work order in Supabase (deterministic ID, idempotent)
  Future<String> createWorkOrder(WorkOrder workOrder) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      validateWorkOrder(workOrder);

      final id = (workOrder.id.isNotEmpty)
          ? DeterministicIdGenerator.normalizeWorkOrderId(workOrder.id)
          : DeterministicIdGenerator.generateWorkOrderId(
              idempotencyKey: workOrder.idempotencyKey,
              ticketNumber: workOrder.ticketNumber,
              requestorId: workOrder.requestorId,
              createdAt: workOrder.createdAt,
            );

      debugPrint('Supabase: Upserting work order $id');

      final data = convertToSupabaseMap(workOrder.toMap());
      data['id'] = id;
      
      // Remove fields that don't exist in Supabase schema
      data.remove('actualDuration');
      data.remove('estimatedDuration');
      data.remove('firstResponseTime');
      data.remove('actualStartTime');
      data.remove('actualEndTime');
      data.remove('rootCause');
      data.remove('failureMode');
      data.remove('severityLevel');
      data.remove('isRepeatFailure');
      data.remove('workCategory');

      await _client.from('work_orders').upsert(data);

      debugPrint('Supabase: Work order upserted with ID: $id');
      return id;
    } on Exception catch (e) {
      debugPrint('Supabase: Error creating work order: $e');
      throw Exception('Failed to create work order: $e');
    }
  }

  /// Update work order in Supabase
  Future<void> updateWorkOrder(String workOrderId, WorkOrder workOrder) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      validateWorkOrder(workOrder);

      debugPrint('Supabase: Updating work order $workOrderId');

      final data = convertToSupabaseMap(workOrder.toMap());
      
      // Remove fields that don't exist in Supabase schema
      data.remove('actualDuration');
      data.remove('estimatedDuration');
      data.remove('firstResponseTime');
      data.remove('actualStartTime');
      data.remove('actualEndTime');
      data.remove('rootCause');
      data.remove('failureMode');
      data.remove('severityLevel');
      data.remove('isRepeatFailure');
      data.remove('workCategory');

      await _client.from('work_orders').update(data).eq('id', workOrderId);

      debugPrint('Supabase: Work order updated successfully');
    } on Exception catch (e) {
      debugPrint('Supabase: Error updating work order: $e');
      throw Exception('Failed to update work order: $e');
    }
  }

  /// Delete work order from Supabase
  Future<void> deleteWorkOrder(String workOrderId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Deleting work order $workOrderId');

      await _client.from('work_orders').delete().eq('id', workOrderId);

      debugPrint('Supabase: Work order deleted successfully');
    } on Exception catch (e) {
      debugPrint('Supabase: Error deleting work order: $e');
      throw Exception('Failed to delete work order: $e');
    }
  }

  /// Get work order by ID
  Future<WorkOrder?> getWorkOrder(String workOrderId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting work order $workOrderId');

      final response = await _client
          .from('work_orders')
          .select()
          .eq('id', workOrderId)
          .single();

      if (response != null) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(response));
        final normalizedId = DeterministicIdGenerator.normalizeWorkOrderId(workOrderId);
        data['id'] = normalizedId;
        final workOrder = WorkOrder.fromMap(data);
        if (normalizedId != workOrderId) {
          return workOrder.copyWith(
            id: normalizedId,
            ticketNumber: normalizedId,
          );
        }
        return workOrder;
      }

      return null;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting work order: $e');
      return null;
    }
  }

  /// Get all work orders
  Future<List<WorkOrder>> getAllWorkOrders() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting all work orders');

      final response = await _client
          .from('work_orders')
          .select()
          .order('createdAt', ascending: false);

      final workOrders = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        final normalizedId = DeterministicIdGenerator.normalizeWorkOrderId(doc['id'] ?? '');
        data['id'] = normalizedId;
        final workOrder = WorkOrder.fromMap(data);
        if (normalizedId != doc['id']) {
          return workOrder.copyWith(
            id: normalizedId,
            ticketNumber: normalizedId,
          );
        }
        return workOrder;
      }).toList();

      debugPrint('Supabase: Retrieved ${workOrders.length} work orders');
      return workOrders;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting work orders: $e');
      return [];
    }
  }

  /// Get work orders by technician
  Future<List<WorkOrder>> getWorkOrdersByTechnician(String technicianId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting work orders for technician $technicianId');

      final response = await _client
          .from('work_orders')
          .select()
          .contains('assignedTechnicianIds', [technicianId])
          .order('createdAt', ascending: false);

      final workOrders = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        final normalizedId = DeterministicIdGenerator.normalizeWorkOrderId(doc['id'] ?? '');
        data['id'] = normalizedId;
        final workOrder = WorkOrder.fromMap(data);
        if (normalizedId != doc['id']) {
          return workOrder.copyWith(
            id: normalizedId,
            ticketNumber: normalizedId,
          );
        }
        return workOrder;
      }).toList();

      debugPrint('Supabase: Retrieved ${workOrders.length} work orders for technician');
      return workOrders;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting work orders by technician: $e');
      return [];
    }
  }

  /// Get work orders by asset
  Future<List<WorkOrder>> getWorkOrdersByAsset(String assetId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting work orders for asset $assetId');

      final response = await _client
          .from('work_orders')
          .select()
          .eq('assetId', assetId)
          .order('createdAt', ascending: false);

      final workOrders = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        final normalizedId = DeterministicIdGenerator.normalizeWorkOrderId(doc['id'] ?? '');
        data['id'] = normalizedId;
        final workOrder = WorkOrder.fromMap(data);
        if (normalizedId != doc['id']) {
          return workOrder.copyWith(
            id: normalizedId,
            ticketNumber: normalizedId,
          );
        }
        return workOrder;
      }).toList();

      debugPrint('Supabase: Retrieved ${workOrders.length} work orders for asset');
      return workOrders;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting work orders by asset: $e');
      return [];
    }
  }

  // ============================================================================
  // ASSETS
  // ============================================================================

  /// Create asset in Supabase (deterministic ID, idempotent)
  Future<String> createAsset(Asset asset) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      validateAsset(asset);

      final id = asset.id.isNotEmpty
          ? asset.id
          : DeterministicIdGenerator.generateAssetId(
              name: asset.name,
              location: asset.location,
            );

      debugPrint('Supabase: Upserting asset $id');

      final data = convertToSupabaseMap(asset.toMap());
      data['id'] = id;

      await _client.from('assets').upsert(data);

      return id;
    } on Exception catch (e) {
      debugPrint('Supabase: Error creating asset: $e');
      throw Exception('Failed to create asset: $e');
    }
  }

  /// Update asset in Supabase
  Future<void> updateAsset(String assetId, Asset asset) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      validateAsset(asset);

      debugPrint('Supabase: Updating asset $assetId');

      final data = convertToSupabaseMap(asset.toMap());

      await _client.from('assets').update(data).eq('id', assetId);

      debugPrint('Supabase: Asset updated successfully');
    } on Exception catch (e) {
      debugPrint('Supabase: Error updating asset: $e');
      throw Exception('Failed to update asset: $e');
    }
  }

  /// Delete asset from Supabase
  Future<void> deleteAsset(String assetId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Deleting asset $assetId');

      await _client.from('assets').delete().eq('id', assetId);

      debugPrint('Supabase: Asset deleted successfully');
    } on Exception catch (e) {
      debugPrint('Supabase: Error deleting asset: $e');
      throw Exception('Failed to delete asset: $e');
    }
  }

  /// Get asset by ID
  Future<Asset?> getAsset(String assetId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting asset $assetId');

      final response = await _client
          .from('assets')
          .select()
          .eq('id', assetId)
          .single();

      if (response != null) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(response));
        data['id'] = assetId;
        return Asset.fromMap(data);
      }

      return null;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting asset: $e');
      return null;
    }
  }

  /// Get all assets
  Future<List<Asset>> getAllAssets() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting all assets');

      final response = await _client
          .from('assets')
          .select()
          .order('name', ascending: true);

      final assets = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = doc['id'];
        return Asset.fromMap(data);
      }).toList();

      debugPrint('Supabase: Retrieved ${assets.length} assets');
      return assets;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting assets: $e');
      return [];
    }
  }

  /// Get asset by QR code
  Future<Asset?> getAssetByQRCode(String qrCode) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting asset by QR code: $qrCode');

      final response = await _client
          .from('assets')
          .select()
          .eq('qrCode', qrCode)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(response));
        data['id'] = response['id'];
        final asset = Asset.fromMap(data);
        debugPrint('Supabase: Found asset: ${asset.name}');
        return asset;
      }

      debugPrint('Supabase: No asset found with QR code: $qrCode');
      return null;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting asset by QR code: $e');
      return null;
    }
  }

  // ============================================================================
  // PM TASKS
  // ============================================================================

  /// Create PM task in Supabase (deterministic ID, idempotent)
  Future<String> createPMTask(PMTask pmTask) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      validatePMTask(pmTask);

      final id = pmTask.id.isNotEmpty
          ? pmTask.id
          : DeterministicIdGenerator.generatePMTaskId(
              idempotencyKey: pmTask.idempotencyKey,
              title: pmTask.taskName,
              assetId: pmTask.assetId,
            );

      debugPrint('Supabase: Upserting PM task $id');

      final data = convertToSupabaseMap(pmTask.toMap());
      data['id'] = id;

      await _client.from('pm_tasks').upsert(data);

      return id;
    } on Exception catch (e) {
      debugPrint('Supabase: Error creating PM task: $e');
      throw Exception('Failed to create PM task: $e');
    }
  }

  /// Update PM task in Supabase
  Future<void> updatePMTask(String pmTaskId, PMTask pmTask) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      validatePMTask(pmTask);

      debugPrint('Supabase: Updating PM task $pmTaskId');

      final data = convertToSupabaseMap(pmTask.toMap());

      await _client.from('pm_tasks').update(data).eq('id', pmTaskId);

      debugPrint('Supabase: PM task updated successfully');
    } on Exception catch (e) {
      debugPrint('Supabase: Error updating PM task: $e');
      throw Exception('Failed to update PM task: $e');
    }
  }

  /// Delete PM task from Supabase
  Future<void> deletePMTask(String pmTaskId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Deleting PM task $pmTaskId');

      await _client.from('pm_tasks').delete().eq('id', pmTaskId);

      debugPrint('Supabase: PM task deleted successfully');
    } on Exception catch (e) {
      debugPrint('Supabase: Error deleting PM task: $e');
      throw Exception('Failed to delete PM task: $e');
    }
  }

  /// Get all PM tasks
  Future<List<PMTask>> getAllPMTasks() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting all PM tasks');

      final response = await _client
          .from('pm_tasks')
          .select()
          .order('createdAt', ascending: false);

      final pmTasks = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = doc['id'];
        return PMTask.fromMap(data);
      }).toList();

      debugPrint('Supabase: Retrieved ${pmTasks.length} PM tasks');
      return pmTasks;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting PM tasks: $e');
      return [];
    }
  }

  // ============================================================================
  // USERS
  // ============================================================================

  /// Create user in Supabase (deterministic ID = USER-{email_prefix})
  Future<String> createUser(app_user.User user) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      validateUser(user);
      
      final readableId = DeterministicIdGenerator.generateUserId(user.email);
      
      final userWithReadableId = user.id.isEmpty || 
          !DeterministicIdGenerator.isValidUserId(user.id)
          ? user.copyWith(id: readableId)
          : user;
      
      debugPrint('Supabase: Creating user $readableId');

      final data = convertToSupabaseMap(userWithReadableId.toMap());
      data['id'] = readableId;

      await _client.from('users').upsert(data);
      
      debugPrint('Supabase: User created/upserted: $readableId');
      return readableId;
    } on Exception catch (e) {
      debugPrint('Supabase: Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user in Supabase
  Future<void> updateUser(String userId, app_user.User user) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      validateUser(user);
      final targetUser = user.id.isNotEmpty ? user : user.copyWith(id: userId);
      
      debugPrint('Supabase: Updating user $userId');

      final data = convertToSupabaseMap(targetUser.toMap());

      await _client.from('users').update(data).eq('id', userId);
      
      debugPrint('Supabase: User updated: $userId');
    } on Exception catch (e) {
      debugPrint('Supabase: Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Deleting user $userId');

      await _client.from('users').delete().eq('id', userId);

      debugPrint('Supabase: User deleted successfully');
    } on Exception catch (e) {
      debugPrint('Supabase: Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get user by email
  /// Note: This method requires authentication, but during login the user is already
  /// authenticated via Supabase Auth, so this should work. However, RLS policies
  /// must allow users to read their own record.
  Future<app_user.User?> getUserByEmail(String email) async {
    try {
      // Check if user is authenticated in Supabase Auth
      // During login, this should be true after signInWithEmailAndPassword
      if (_currentUserId == null) {
        debugPrint('Supabase: getUserByEmail - User not authenticated in Supabase Auth');
        throw Exception('User not authenticated');
      }

      debugPrint('Supabase: Getting user by email: $email (Auth UID: $_currentUserId)');

      final response = await _client
          .from('users')
          .select()
          .eq('email', email.toLowerCase().trim())
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(response));
        data['id'] = response['id'];
        final user = app_user.User.fromMap(data);

        debugPrint('Supabase: Retrieved user: ${user.name}');
        return user;
      }

      debugPrint('Supabase: User not found with email: $email');
      return null;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting user by email: $e');
      return null;
    }
  }

  /// Get all users
  Future<List<app_user.User>> getAllUsers() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting all users');

      final response = await _client
          .from('users')
          .select()
          .order('name', ascending: true);

      final users = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = doc['id'];
        return app_user.User.fromMap(data);
      }).toList();

      debugPrint('Supabase: Retrieved ${users.length} users');
      return users;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting users: $e');
      return [];
    }
  }

  /// Get single user by ID
  Future<app_user.User?> getUserById(String userId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting user $userId');

      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(response));
        data['id'] = userId;
        return app_user.User.fromMap(data);
      }

      return null;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting user $userId: $e');
      return null;
    }
  }

  // ============================================================================
  // INVENTORY
  // ============================================================================

  /// Create inventory item in Supabase (deterministic ID = SKU hash)
  Future<String> createInventoryItem(InventoryItem item) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final id = item.id.isNotEmpty && item.id != ''
          ? item.id
          : (item.sku != null && item.sku!.isNotEmpty
              ? DeterministicIdGenerator.generateInventoryId(item.sku!)
              : DateTime.now().millisecondsSinceEpoch.toString());

      debugPrint('Supabase: Upserting inventory item $id');

      final data = convertToSupabaseMap(item.toMap());
      data['id'] = id;

      await _client.from('inventory_items').upsert(data);

      return id;
    } on Exception catch (e) {
      debugPrint('Supabase: Error creating inventory item: $e');
      throw Exception('Failed to create inventory item: $e');
    }
  }

  /// Get all inventory items
  Future<List<InventoryItem>> getAllInventoryItems() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting all inventory items');

      final response = await _client
          .from('inventory_items')
          .select()
          .order('name', ascending: true);

      final items = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = doc['id'];
        return InventoryItem.fromMap(data);
      }).toList();

      debugPrint('Supabase: Retrieved ${items.length} inventory items');
      return items;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting inventory items: $e');
      return [];
    }
  }

  /// Update inventory item
  Future<void> updateInventoryItem(String itemId, InventoryItem item) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final data = convertToSupabaseMap(item.toMap());

      await _client.from('inventory_items').update(data).eq('id', itemId);
    } on Exception catch (e) {
      debugPrint('Supabase: Error updating inventory item: $e');
      throw Exception('Failed to update inventory item: $e');
    }
  }

  /// Get inventory item by ID
  Future<InventoryItem?> getInventoryItem(String itemId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final response = await _client
          .from('inventory_items')
          .select()
          .eq('id', itemId)
          .maybeSingle();

      if (response != null) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(response));
        data['id'] = itemId;
        return InventoryItem.fromMap(data);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting inventory item: $e');
      return null;
    }
  }

  /// Backwards-compatible alias
  Future<InventoryItem?> getInventoryItemById(String itemId) =>
      getInventoryItem(itemId);

  /// Delete inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Deleting inventory item $itemId');

      await _client.from('inventory_items').delete().eq('id', itemId);

      debugPrint('Supabase: Successfully deleted inventory item $itemId');
    } on Exception catch (e) {
      debugPrint('Supabase: Error deleting inventory item $itemId: $e');
      throw Exception('Failed to delete inventory item: $e');
    }
  }

  // ============================================================================
  // PARTS REQUESTS
  // ============================================================================

  /// Create parts request in Supabase
  Future<String> createPartsRequest(PartsRequest request) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Creating parts request ${request.id}');

      final data = convertToSupabaseMap(request.toMap());
      if (request.id.isNotEmpty) {
        data['id'] = request.id;
      }

      final response = await _client.from('parts_requests').insert(data).select();

      final id = response != null && response.isNotEmpty 
          ? response[0]['id'] as String
          : DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('Supabase: Parts request created with ID: $id');
      return id;
    } on Exception catch (e) {
      debugPrint('Supabase: Error creating parts request: $e');
      throw Exception('Failed to create parts request: $e');
    }
  }

  /// Get all parts requests
  Future<List<PartsRequest>> getAllPartsRequests() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting all parts requests');

      final response = await _client
          .from('parts_requests')
          .select()
          .order('createdAt', ascending: false);

      final requests = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = doc['id'];
        return PartsRequest.fromMap(data);
      }).toList();

      debugPrint('Supabase: Retrieved ${requests.length} parts requests');
      return requests;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting parts requests: $e');
      return [];
    }
  }

  /// Update parts request
  Future<void> updatePartsRequest(
    String requestId,
    PartsRequest request,
  ) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final data = convertToSupabaseMap(request.toMap());

      await _client.from('parts_requests').update(data).eq('id', requestId);
    } on Exception catch (e) {
      debugPrint('Supabase: Error updating parts request: $e');
      throw Exception('Failed to update parts request: $e');
    }
  }

  // ============================================================================
  // PURCHASE ORDERS
  // ============================================================================

  /// Create purchase order in Supabase
  Future<String> createPurchaseOrder(PurchaseOrder order) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Creating purchase order ${order.id}');

      final data = convertToSupabaseMap(order.toMap());
      if (order.id.isNotEmpty) {
        data['id'] = order.id;
      }

      final response = await _client.from('purchase_orders').insert(data).select();

      final id = response != null && response.isNotEmpty 
          ? response[0]['id'] as String
          : DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('Supabase: Purchase order created with ID: $id');
      return id;
    } on Exception catch (e) {
      debugPrint('Supabase: Error creating purchase order: $e');
      throw Exception('Failed to create purchase order: $e');
    }
  }

  /// Get all purchase orders
  Future<List<PurchaseOrder>> getAllPurchaseOrders() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting all purchase orders');

      final response = await _client
          .from('purchase_orders')
          .select()
          .order('createdAt', ascending: false);

      final orders = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = doc['id'];
        return PurchaseOrder.fromMap(data);
      }).toList();

      debugPrint('Supabase: Retrieved ${orders.length} purchase orders');
      return orders;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting purchase orders: $e');
      return [];
    }
  }

  /// Update purchase order
  Future<void> updatePurchaseOrder(String orderId, PurchaseOrder order) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final data = convertToSupabaseMap(order.toMap());

      await _client.from('purchase_orders').update(data).eq('id', orderId);
    } on Exception catch (e) {
      debugPrint('Supabase: Error updating purchase order: $e');
      throw Exception('Failed to update purchase order: $e');
    }
  }

  // ============================================================================
  // REAL-TIME LISTENERS
  // ============================================================================

  /// Listen to work orders changes
  Stream<List<WorkOrder>> listenToWorkOrders() {
    return _client
        .from('work_orders')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map((snapshot) {
          return snapshot.map((doc) {
            final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
            final normalizedId = DeterministicIdGenerator.normalizeWorkOrderId(doc['id'] ?? '');
            data['id'] = normalizedId;
            final workOrder = WorkOrder.fromMap(data);
            if (normalizedId != doc['id']) {
              return workOrder.copyWith(
                id: normalizedId,
                ticketNumber: normalizedId,
              );
            }
            return workOrder;
          }).toList();
        });
  }

  /// Listen to assets changes
  Stream<List<Asset>> listenToAssets() {
    return _client
        .from('assets')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((snapshot) {
          return snapshot.map((doc) {
            final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
            data['id'] = doc['id'];
            return Asset.fromMap(data);
          }).toList();
        });
  }

  /// Listen to PM tasks changes
  Stream<List<PMTask>> listenToPMTasks() {
    return _client
        .from('pm_tasks')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map((snapshot) {
          return snapshot.map((doc) {
            final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
            data['id'] = doc['id'];
            return PMTask.fromMap(data);
          }).toList();
        });
  }

  // ============================================================================
  // QUERY METHODS
  // ============================================================================

  Future<List<WorkOrder>> queryWorkOrders({
    WorkOrderStatus? status,
    WorkOrderPriority? priority,
    String? assignedTechnicianId,
    String? assetId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');
      
      var queryBuilder = _client.from('work_orders').select();
      
      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status.name);
      }
      if (priority != null) {
        queryBuilder = queryBuilder.eq('priority', priority.name);
      }
      if (assignedTechnicianId != null) {
        queryBuilder = queryBuilder.contains('assignedTechnicianIds', [assignedTechnicianId]);
      }
      if (assetId != null) {
        queryBuilder = queryBuilder.eq('assetId', assetId);
      }
      if (startDate != null) {
        queryBuilder = queryBuilder.gte('createdAt', startDate.toIso8601String());
      }
      if (endDate != null) {
        queryBuilder = queryBuilder.lte('createdAt', endDate.toIso8601String());
      }
      
      final response = await queryBuilder.order('createdAt', ascending: false);
      
      return (response as List).map((d) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(d));
        final normalizedId = DeterministicIdGenerator.normalizeWorkOrderId(d['id'] ?? '');
        data['id'] = normalizedId;
        final workOrder = WorkOrder.fromMap(data);
        if (normalizedId != d['id']) {
          return workOrder.copyWith(
            id: normalizedId,
            ticketNumber: normalizedId,
          );
        }
        return workOrder;
      }).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: queryWorkOrders error: $e');
      return [];
    }
  }

  Future<List<PMTask>> queryPMTasks({
    PMTaskStatus? status,
    String? assignedTechnicianId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueStart,
    DateTime? nextDueEnd,
  }) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');
      
      var queryBuilder = _client.from('pm_tasks').select();
      
      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status.name);
      }
      if (assignedTechnicianId != null) {
        queryBuilder = queryBuilder.contains('assignedTechnicianIds', [assignedTechnicianId]);
      }
      if (startDate != null) {
        queryBuilder = queryBuilder.gte('createdAt', startDate.toIso8601String());
      }
      if (endDate != null) {
        queryBuilder = queryBuilder.lte('createdAt', endDate.toIso8601String());
      }
      if (nextDueStart != null) {
        queryBuilder = queryBuilder.gte('nextDueDate', nextDueStart.toIso8601String());
      }
      if (nextDueEnd != null) {
        queryBuilder = queryBuilder.lte('nextDueDate', nextDueEnd.toIso8601String());
      }
      
      final response = await queryBuilder.order('createdAt', ascending: false);
      
      return (response as List).map((d) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(d));
        data['id'] = d['id'];
        return PMTask.fromMap(data);
      }).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: queryPMTasks error: $e');
      return [];
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check Supabase connection
  Future<bool> checkConnection() async {
    try {
      await _client.from('users').select().limit(1);
      return true;
    } on Exception catch (e) {
      debugPrint('Supabase: Connection check failed: $e');
      return false;
    }
  }

  /// Test connection (alias for checkConnection)
  Future<bool> testConnection() async => checkConnection();

  /// Load configuration (placeholder)
  Future<void> loadConfiguration() async {
    debugPrint('Supabase: Loading configuration...');
  }

  /// Get configuration status
  Map<String, dynamic> getConfigurationStatus() => {
        'connected': true,
        'initialized': true,
      };

  /// Configure Supabase (placeholder)
  Future<void> configureSupabase({
    required String projectId,
    required String databaseId,
    required String apiKey,
    String? serviceAccountKey,
  }) async {
    debugPrint('Supabase: Configuring Supabase...');
    debugPrint('Project ID: $projectId');
    debugPrint('Database ID: $databaseId');
    debugPrint('API Key: $apiKey');
  }

  /// Clear configuration (placeholder)
  Future<void> clearConfiguration() async {
    debugPrint('Supabase: Clearing configuration...');
  }

  /// Search assets
  Future<List<Asset>> searchAssets(String query) async {
    try {
      final response = await _client
          .from('assets')
          .select()
          .ilike('name', '%$query%');

      return (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = doc['id'];
        return Asset.fromMap(data);
      }).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error searching assets: $e');
      return [];
    }
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Clearing all data');

      final collections = [
        'work_orders',
        'assets',
        'pm_tasks',
        'users',
        'inventory_items',
        'parts_requests',
        'purchase_orders',
      ];

      for (final collection in collections) {
        await _client.from(collection).delete().neq('id', '');
      }

      debugPrint('Supabase: All data cleared');
    } on Exception catch (e) {
      debugPrint('Supabase: Error clearing data: $e');
      throw Exception('Failed to clear data: $e');
    }
  }

  // ============================================================================
  // AUDIT LOGGING
  // ============================================================================

  /// Save audit event to Supabase
  Future<void> saveAuditEvent(AuditEvent event) async {
    try {
      final data = convertToSupabaseMap(event.toMap());
      await _client.from('audit_events').insert(data);
      debugPrint('Supabase: Audit event saved: ${event.id}');
    } on Exception catch (e) {
      debugPrint('Supabase: Error saving audit event: $e');
      throw Exception('Failed to save audit event: $e');
    }
  }

  /// Get audit events from Supabase
  Future<List<AuditEvent>> getAuditEvents({int? limit}) async {
    try {
      var query = _client
          .from('audit_events')
          .select()
          .order('timestamp', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        return AuditEvent.fromMap(data);
      }).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting audit events: $e');
      throw Exception('Failed to get audit events: $e');
    }
  }

  /// Get audit events by user
  Future<List<AuditEvent>> getAuditEventsByUser(String userId) async {
    try {
      final response = await _client
          .from('audit_events')
          .select()
          .eq('userId', userId)
          .order('timestamp', ascending: false);

      return (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        return AuditEvent.fromMap(data);
      }).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting audit events by user: $e');
      throw Exception('Failed to get audit events by user: $e');
    }
  }

  /// Get audit events by type
  Future<List<AuditEvent>> getAuditEventsByType(String eventType) async {
    try {
      final response = await _client
          .from('audit_events')
          .select()
          .eq('type', eventType)
          .order('timestamp', ascending: false);

      return (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        return AuditEvent.fromMap(data);
      }).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting audit events by type: $e');
      throw Exception('Failed to get audit events by type: $e');
    }
  }

  // ============================================================================
  // ESCALATION EVENTS
  // ============================================================================

  /// Save escalation event to Supabase
  Future<void> saveEscalationEvent(EscalationEvent event) async {
    try {
      final data = {
        'id': event.id,
        'ruleId': event.ruleId,
        'type': event.type.toString().split('.').last,
        'itemId': event.itemId,
        'itemType': event.itemType,
        'currentLevel': event.currentLevel.toString().split('.').last,
        'createdAt': event.createdAt.toIso8601String(),
        'resolvedAt': event.resolvedAt?.toIso8601String(),
        'resolvedBy': event.resolvedBy,
        'notes': event.notes,
        'data': event.data,
      };
      await _client.from('escalation_events').insert(data);
      debugPrint('Supabase: Escalation event saved: ${event.id}');
    } on Exception catch (e) {
      debugPrint('Supabase: Error saving escalation event: $e');
      throw Exception('Failed to save escalation event: $e');
    }
  }

  /// Get escalation events from Supabase
  Future<List<EscalationEvent>> getEscalationEvents({int? limit}) async {
    try {
      var query = _client
          .from('escalation_events')
          .select()
          .order('createdAt', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List).map((doc) {
        final data = Map<String, dynamic>.from(doc);
        return EscalationEvent(
          id: data['id'],
          ruleId: data['ruleId'],
          type: EscalationType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
            orElse: () => EscalationType.workOrderOverdue,
          ),
          itemId: data['itemId'],
          itemType: data['itemType'],
          currentLevel: EscalationLevel.values.firstWhere(
            (e) => e.toString().split('.').last == data['currentLevel'],
            orElse: () => EscalationLevel.none,
          ),
          createdAt: DateTime.parse(data['createdAt']),
          resolvedAt: data['resolvedAt'] != null
              ? DateTime.parse(data['resolvedAt'])
              : null,
          resolvedBy: data['resolvedBy'],
          notes: data['notes'],
          data: Map<String, dynamic>.from(data['data'] ?? {}),
        );
      }).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting escalation events: $e');
      throw Exception('Failed to get escalation events: $e');
    }
  }

  // ============================================================================
  // NOTIFICATIONS
  // ============================================================================

  /// Save notification to Supabase
  Future<void> saveNotification(EnhancedNotification notification) async {
    try {
      final data = {
        'id': notification.id,
        'title': notification.title,
        'message': notification.message,
        'type': notification.type.toString().split('.').last,
        'priority': notification.priority.toString().split('.').last,
        'channel': notification.channel.toString().split('.').last,
        'userId': notification.userId,
        'relatedId': notification.relatedId,
        'relatedType': notification.relatedType,
        'createdAt': notification.createdAt.toIso8601String(),
        'isRead': notification.isRead,
        'readAt': notification.readAt?.toIso8601String(),
        'data': notification.data,
        'expiresAt': notification.expiresAt?.toIso8601String(),
        'actions': notification.actions,
      };
      await _client.from('notifications').insert(data);
      debugPrint('Supabase: Notification saved: ${notification.id}');
    } on Exception catch (e) {
      debugPrint('Supabase: Error saving notification: $e');
      throw Exception('Failed to save notification: $e');
    }
  }

  /// Get notifications from Supabase
  Future<List<EnhancedNotification>> getNotifications({
    int? limit,
    String? userId,
  }) async {
    try {
      var queryBuilder = _client.from('notifications').select();

      if (userId != null) {
        queryBuilder = queryBuilder.eq('userId', userId);
      }

      final orderedQuery = queryBuilder.order('createdAt', ascending: false);

      final response = limit != null 
          ? await orderedQuery.limit(limit)
          : await orderedQuery;
      return (response as List).map((doc) {
        final data = Map<String, dynamic>.from(doc);
        return EnhancedNotification(
          id: data['id'],
          title: data['title'],
          message: data['message'],
          type: NotificationType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
            orElse: () => NotificationType.systemAlert,
          ),
          priority: NotificationPriority.values.firstWhere(
            (e) => e.toString().split('.').last == data['priority'],
            orElse: () => NotificationPriority.medium,
          ),
          channel: NotificationChannel.values.firstWhere(
            (e) => e.toString().split('.').last == data['channel'],
            orElse: () => NotificationChannel.inApp,
          ),
          userId: data['userId'],
          relatedId: data['relatedId'],
          relatedType: data['relatedType'],
          createdAt: DateTime.parse(data['createdAt']),
          isRead: data['isRead'] ?? false,
          readAt: data['readAt'] != null ? DateTime.parse(data['readAt']) : null,
          data: data['data'] != null
              ? Map<String, dynamic>.from(data['data'])
              : null,
          expiresAt: data['expiresAt'] != null
              ? DateTime.parse(data['expiresAt'])
              : null,
          actions: data['actions'] != null ? List<String>.from(data['actions']) : [],
        );
      }).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting notifications: $e');
      throw Exception('Failed to get notifications: $e');
    }
  }

  // ============================================================================
  // WORKFLOWS
  // ============================================================================

  /// Create workflow in Supabase
  Future<String> createWorkflow(Workflow workflow) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Creating workflow ${workflow.id}');

      await _client.from('workflows').insert(workflow.toJson());

      debugPrint('Supabase: Workflow created with ID: ${workflow.id}');
      return workflow.id;
    } on Exception catch (e) {
      debugPrint('Supabase: Error creating workflow: $e');
      throw Exception('Failed to create workflow: $e');
    }
  }

  /// Update workflow in Supabase
  Future<void> updateWorkflow(String workflowId, Workflow workflow) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Updating workflow $workflowId');

      await _client.from('workflows').update(workflow.toJson()).eq('id', workflowId);

      debugPrint('Supabase: Workflow updated successfully');
    } on Exception catch (e) {
      debugPrint('Supabase: Error updating workflow: $e');
      throw Exception('Failed to update workflow: $e');
    }
  }

  /// Delete workflow from Supabase
  Future<void> deleteWorkflow(String workflowId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Deleting workflow $workflowId');

      await _client.from('workflows').delete().eq('id', workflowId);

      debugPrint('Supabase: Workflow deleted successfully');
    } on Exception catch (e) {
      debugPrint('Supabase: Error deleting workflow: $e');
      throw Exception('Failed to delete workflow: $e');
    }
  }

  /// Get workflow by ID from Supabase
  Future<Workflow?> getWorkflowById(String workflowId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final response = await _client
          .from('workflows')
          .select()
          .eq('id', workflowId)
          .maybeSingle();

      if (response != null) {
        return Workflow.fromJson(response);
      }

      return null;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting workflow: $e');
      return null;
    }
  }

  /// Get all workflows from Supabase
  Future<List<Workflow>> getAllWorkflows() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final response = await _client
          .from('workflows')
          .select()
          .order('createdAt', ascending: false);

      return (response as List).map((doc) => Workflow.fromJson(doc)).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting workflows: $e');
      return [];
    }
  }

  /// Get workflows by status
  Future<List<Workflow>> getWorkflowsByStatus(WorkflowStatus status) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final response = await _client
          .from('workflows')
          .select()
          .eq('status', status.name)
          .order('createdAt', ascending: false);

      return (response as List).map((doc) => Workflow.fromJson(doc)).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting workflows by status: $e');
      return [];
    }
  }

  /// Get workflows for a specific user
  Future<List<Workflow>> getWorkflowsForUser(String userId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      // Get workflows created by user
      final createdByResponse = await _client
          .from('workflows')
          .select()
          .eq('createdByUserId', userId)
          .order('createdAt', ascending: false);

      // Get workflows assigned to user
      final assignedToResponse = await _client
          .from('workflows')
          .select()
          .eq('assignedToUserId', userId)
          .order('createdAt', ascending: false);

      final workflows = <Workflow>[];
      final workflowIds = <String>{};

      // Add created workflows
      for (final doc in createdByResponse as List) {
        if (!workflowIds.contains(doc['id'])) {
          workflows.add(Workflow.fromJson(doc));
          workflowIds.add(doc['id']);
        }
      }

      // Add assigned workflows
      for (final doc in assignedToResponse as List) {
        if (!workflowIds.contains(doc['id'])) {
          workflows.add(Workflow.fromJson(doc));
          workflowIds.add(doc['id']);
        }
      }

      return workflows;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting workflows for user: $e');
      return [];
    }
  }

  /// Get pending approvals for a user
  Future<List<Workflow>> getPendingApprovalsForUser(String userId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final response = await _client
          .from('workflows')
          .select()
          .eq('status', WorkflowStatus.pendingApproval.name)
          .contains('approvers', [userId])
          .order('createdAt', ascending: false);

      return (response as List).map((doc) => Workflow.fromJson(doc)).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting pending approvals: $e');
      return [];
    }
  }

  // ============================================================================
  // VENDORS
  // ============================================================================

  /// Save vendor to Supabase
  Future<void> saveVendor(Vendor vendor) async {
    try {
      final data = {
        'id': vendor.id,
        'name': vendor.name,
        'contactEmail': vendor.contactEmail,
        'contactPhone': vendor.contactPhone,
        'address': vendor.address,
        'website': vendor.website,
        'rating': vendor.rating,
        'isActive': vendor.isActive,
        'notes': vendor.notes,
      };
      await _client.from('vendors').upsert(data);
      debugPrint('Supabase: Vendor saved: ${vendor.id}');
    } on Exception catch (e) {
      debugPrint('Supabase: Error saving vendor: $e');
      throw Exception('Failed to save vendor: $e');
    }
  }

  /// Get vendors from Supabase
  Future<List<Vendor>> getVendors() async {
    try {
      final response = await _client.from('vendors').select();

      return (response as List).map((doc) {
        final data = Map<String, dynamic>.from(doc);
        return Vendor(
          id: data['id'],
          name: data['name'],
          contactEmail: data['contactEmail'],
          contactPhone: data['contactPhone'],
          address: data['address'],
          website: data['website'],
          rating: data['rating']?.toDouble(),
          isActive: data['isActive'] ?? true,
          notes: data['notes'],
        );
      }).toList();
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting vendors: $e');
      throw Exception('Failed to get vendors: $e');
    }
  }

  // ============================================================================
  // COMPANIES
  // ============================================================================

  /// Get all companies
  Future<List<Company>> getAllCompanies() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Getting all companies');

      final response = await _client
          .from('companies')
          .select()
          .order('name', ascending: true);

      final companies = (response as List).map((doc) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = doc['id'];
        return Company.fromMap(data);
      }).toList();

      debugPrint('Supabase: Retrieved ${companies.length} companies');
      return companies;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting companies: $e');
      return [];
    }
  }

  /// Create company in Supabase
  Future<String> createCompany(Company company) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final readableId = DeterministicIdGenerator.generateCompanyId(company.name);
      
      final companyWithId = company.id.isEmpty || 
          !DeterministicIdGenerator.isValidCompanyId(company.id)
          ? company.copyWith(id: readableId)
          : company;
      
      debugPrint('Supabase: Creating company $readableId');

      final data = convertToSupabaseMap(companyWithId.toMap());
      data['id'] = readableId;

      await _client.from('companies').upsert(data);
      
      debugPrint('Supabase: Company created/upserted: $readableId');
      return readableId;
    } on Exception catch (e) {
      debugPrint('Supabase: Error creating company: $e');
      throw Exception('Failed to create company: $e');
    }
  }

  /// Update company in Supabase
  Future<void> updateCompany(String companyId, Company company) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Updating company $companyId');

      final data = convertToSupabaseMap(company.toMap());
      data['updatedAt'] = DateTime.now().toIso8601String();

      await _client.from('companies').update(data).eq('id', companyId);
      
      debugPrint('Supabase: Company updated: $companyId');
    } on Exception catch (e) {
      debugPrint('Supabase: Error updating company: $e');
      throw Exception('Failed to update company: $e');
    }
  }

  /// Delete company in Supabase
  Future<void> deleteCompany(String companyId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      debugPrint('Supabase: Deleting company $companyId');

      await _client.from('companies').delete().eq('id', companyId);
      
      debugPrint('Supabase: Company deleted: $companyId');
    } on Exception catch (e) {
      debugPrint('Supabase: Error deleting company: $e');
      throw Exception('Failed to delete company: $e');
    }
  }

  /// Get company by ID
  Future<Company?> getCompanyById(String companyId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final response = await _client
          .from('companies')
          .select()
          .eq('id', companyId)
          .maybeSingle();

      if (response != null) {
        final data = convertFromSupabaseMap(Map<String, dynamic>.from(response));
        data['id'] = companyId;
        return Company.fromMap(data);
      }

      return null;
    } on Exception catch (e) {
      debugPrint('Supabase: Error getting company $companyId: $e');
      return null;
    }
  }
}

