// Real-Time Supabase Service
// Provides stream-based real-time data access from Supabase

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asset.dart';
import '../models/inventory_item.dart';
import '../models/parts_request.dart';
import '../models/pm_task.dart';
import '../models/purchase_order.dart';
import '../models/user.dart' as app_user;
import '../models/work_order.dart';
import '../models/workflow_models.dart';
import 'supabase_database_service.dart';

class RealtimeSupabaseService {
  RealtimeSupabaseService._();
  static RealtimeSupabaseService? _instance;
  static RealtimeSupabaseService get instance =>
      _instance ??= RealtimeSupabaseService._();

  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseDatabaseService _dbService = SupabaseDatabaseService.instance;

  // Stream controllers for managing subscriptions
  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};

  /// Initialize the service
  Future<void> initialize() async {
    try {
      debugPrint('RealtimeSupabase: Initializing real-time listeners...');
      // Supabase handles offline persistence automatically
      debugPrint('RealtimeSupabase: Initialized successfully');
    } on Exception catch (e) {
      debugPrint('RealtimeSupabase: Initialization error: $e');
    }
  }

  /// Dispose all subscriptions
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    debugPrint('RealtimeSupabase: All subscriptions cancelled');
  }

  // ============================================================================
  // WORK ORDERS - REAL-TIME STREAMS
  // ============================================================================

  /// Get real-time stream of all work orders
  Stream<List<WorkOrder>> getWorkOrdersStream() {
    return _client
        .from('work_orders')
        .stream(primaryKey: ['id'])
        .order('createdAt')
        .map((snapshot) {
      return snapshot.map((doc) {
        try {
          final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
          final normalizedId = doc['id'] ?? '';
          data['id'] = normalizedId;
          return WorkOrder.fromMap(data);
        } on Exception catch (e) {
          debugPrint('Error parsing work order ${doc['id']}: $e');
          return null;
        }
      }).whereType<WorkOrder>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Work orders stream error: $error');
      return <WorkOrder>[];
    });
  }

  /// Get real-time stream of work orders for a specific technician
  Stream<List<WorkOrder>> getWorkOrdersByTechnicianStream(
    String technicianId,
  ) {
    return _client
        .from('work_orders')
        .stream(primaryKey: ['id'])
        .eq('assignedTechnicianIds', technicianId)
        .map((snapshot) {
      return snapshot.map((doc) {
        try {
          final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
          final normalizedId = doc['id'] ?? '';
          data['id'] = normalizedId;
          return WorkOrder.fromMap(data);
        } on Exception catch (e) {
          debugPrint('Error parsing work order ${doc['id']}: $e');
          return null;
        }
      }).whereType<WorkOrder>().toList();
    }).handleError((error) {
      debugPrint(
        'RealtimeSupabase: Technician work orders stream error: $error',
      );
      return <WorkOrder>[];
    });
  }

  /// Get real-time stream of a single work order
  Stream<WorkOrder?> getWorkOrderStream(String workOrderId) {
    return _client
        .from('work_orders')
        .stream(primaryKey: ['id'])
        .eq('id', workOrderId)
        .map((snapshot) {
      if (snapshot.isEmpty) return null;
      try {
        final doc = snapshot.first;
        final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = workOrderId;
        return WorkOrder.fromMap(data);
      } on Exception catch (e) {
        debugPrint('Error parsing work order $workOrderId: $e');
        return null;
      }
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Work order stream error: $error');
      return null;
    });
  }

  // ============================================================================
  // PM TASKS - REAL-TIME STREAMS
  // ============================================================================

  /// Get real-time stream of all PM tasks
  Stream<List<PMTask>> getPMTasksStream() {
    return _client
        .from('pm_tasks')
        .stream(primaryKey: ['id'])
        .order('nextDueDate')
        .map((snapshot) {
      return snapshot.map((doc) {
        try {
          final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
          data['id'] = doc['id'];
          return PMTask.fromMap(data);
        } on Exception catch (e) {
          debugPrint('Error parsing PM task ${doc['id']}: $e');
          return null;
        }
      }).whereType<PMTask>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: PM tasks stream error: $error');
      return <PMTask>[];
    });
  }

  /// Get real-time stream of PM tasks for a specific technician
  Stream<List<PMTask>> getPMTasksByTechnicianStream(String technicianId) {
    return _client
        .from('pm_tasks')
        .stream(primaryKey: ['id'])
        .eq('assignedTechnicianIds', technicianId)
        .map((snapshot) {
      return snapshot.map((doc) {
        try {
          final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
          data['id'] = doc['id'];
          return PMTask.fromMap(data);
        } on Exception catch (e) {
          debugPrint('Error parsing PM task ${doc['id']}: $e');
          return null;
        }
      }).whereType<PMTask>().toList();
    }).handleError((error) {
      debugPrint(
        'RealtimeSupabase: Technician PM tasks stream error: $error',
      );
      return <PMTask>[];
    });
  }

  /// Get real-time stream of a single PM task
  Stream<PMTask?> getPMTaskStream(String pmTaskId) {
    return _client
        .from('pm_tasks')
        .stream(primaryKey: ['id'])
        .eq('id', pmTaskId)
        .map((snapshot) {
      if (snapshot.isEmpty) return null;
      try {
        final doc = snapshot.first;
        final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = pmTaskId;
        return PMTask.fromMap(data);
      } on Exception catch (e) {
        debugPrint('Error parsing PM task $pmTaskId: $e');
        return null;
      }
    }).handleError((error) {
      debugPrint('RealtimeSupabase: PM task stream error: $error');
      return null;
    });
  }

  // ============================================================================
  // ASSETS - REAL-TIME STREAMS
  // ============================================================================

  /// Get real-time stream of all assets
  Stream<List<Asset>> getAssetsStream() {
    return _client
        .from('assets')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((snapshot) {
      return snapshot.map((doc) {
        try {
          final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
          data['id'] = doc['id'];
          return Asset.fromMap(data);
        } on Exception catch (e) {
          debugPrint('Error parsing asset ${doc['id']}: $e');
          return null;
        }
      }).whereType<Asset>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Assets stream error: $error');
      return <Asset>[];
    });
  }

  /// Get real-time stream of a single asset
  Stream<Asset?> getAssetStream(String assetId) {
    return _client
        .from('assets')
        .stream(primaryKey: ['id'])
        .eq('id', assetId)
        .map((snapshot) {
      if (snapshot.isEmpty) return null;
      try {
        final doc = snapshot.first;
        final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
        data['id'] = assetId;
        return Asset.fromMap(data);
      } on Exception catch (e) {
        debugPrint('Error parsing asset $assetId: $e');
        return null;
      }
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Asset stream error: $error');
      return null;
    });
  }

  // ============================================================================
  // INVENTORY - REAL-TIME STREAMS
  // ============================================================================

  /// Get real-time stream of all inventory items
  Stream<List<InventoryItem>> getInventoryItemsStream() {
    return _client
        .from('inventory_items')
        .stream(primaryKey: ['id'])
        .map((snapshot) {
      return snapshot.map((doc) {
        try {
          final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
          data['id'] = doc['id'];
          return InventoryItem.fromMap(data);
        } on Exception catch (e) {
          debugPrint('Error parsing inventory item ${doc['id']}: $e');
          return null;
        }
      }).whereType<InventoryItem>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Inventory items stream error: $error');
      return <InventoryItem>[];
    });
  }

  // ============================================================================
  // USERS - REAL-TIME STREAMS
  // ============================================================================

  /// Get real-time stream of all users
  Stream<List<app_user.User>> getUsersStream() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .map((snapshot) {
      return snapshot.map((doc) {
        try {
          final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
          data['id'] = doc['id'];
          return app_user.User.fromMap(data);
        } on Exception catch (e) {
          debugPrint('Error parsing user ${doc['id']}: $e');
          return null;
        }
      }).whereType<app_user.User>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Users stream error: $error');
      return <app_user.User>[];
    });
  }

  // ============================================================================
  // PARTS REQUESTS - REAL-TIME STREAMS
  // ============================================================================

  /// Get real-time stream of all parts requests
  Stream<List<PartsRequest>> getPartsRequestsStream() {
    return _client
        .from('parts_requests')
        .stream(primaryKey: ['id'])
        .order('createdAt')
        .map((snapshot) {
      debugPrint(
        'RealtimeSupabase: Received ${snapshot.length} parts requests',
      );
      return snapshot.map((doc) {
        try {
          final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
          data['id'] = doc['id'];
          return PartsRequest.fromMap(data);
        } on Exception catch (e) {
          debugPrint('Error parsing parts request ${doc['id']}: $e');
          return null;
        }
      }).whereType<PartsRequest>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Parts requests stream error: $error');
      return <PartsRequest>[];
    });
  }

  // ============================================================================
  // PURCHASE ORDERS - REAL-TIME STREAMS
  // ============================================================================

  /// Get real-time stream of all purchase orders
  Stream<List<PurchaseOrder>> getPurchaseOrdersStream() {
    return _client
        .from('purchase_orders')
        .stream(primaryKey: ['id'])
        .order('createdAt')
        .map((snapshot) {
      debugPrint(
        'RealtimeSupabase: Received ${snapshot.length} purchase orders',
      );
      return snapshot.map((doc) {
        try {
          final data = _dbService.convertFromSupabaseMap(Map<String, dynamic>.from(doc));
          data['id'] = doc['id'];
          return PurchaseOrder.fromMap(data);
        } on Exception catch (e) {
          debugPrint('Error parsing purchase order ${doc['id']}: $e');
          return null;
        }
      }).whereType<PurchaseOrder>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Purchase orders stream error: $error');
      return <PurchaseOrder>[];
    });
  }

  // ============================================================================
  // WORKFLOWS - REAL-TIME STREAMS
  // ============================================================================

  /// Get real-time stream of all workflows
  Stream<List<Workflow>> getWorkflowsStream() {
    return _client
        .from('workflows')
        .stream(primaryKey: ['id'])
        .order('createdAt')
        .map((snapshot) {
      debugPrint(
        'RealtimeSupabase: Received ${snapshot.length} workflows',
      );
      return snapshot.map((doc) {
        try {
          return Workflow.fromJson(doc);
        } on Exception catch (e) {
          debugPrint('Error parsing workflow ${doc['id']}: $e');
          return null;
        }
      }).whereType<Workflow>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Workflows stream error: $error');
      return <Workflow>[];
    });
  }

  /// Get real-time stream of a single workflow
  Stream<Workflow?> getWorkflowStream(String workflowId) {
    return _client
        .from('workflows')
        .stream(primaryKey: ['id'])
        .eq('id', workflowId)
        .map((snapshot) {
      if (snapshot.isEmpty) return null;
      try {
        return Workflow.fromJson(snapshot.first);
      } on Exception catch (e) {
        debugPrint('Error parsing workflow $workflowId: $e');
        return null;
      }
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Workflow stream error: $error');
      return null;
    });
  }

  /// Get real-time stream of workflows for a specific user
  Stream<List<Workflow>> getWorkflowsByUserStream(String userId) {
    return _client
        .from('workflows')
        .stream(primaryKey: ['id'])
        .eq('createdByUserId', userId)
        .order('createdAt')
        .map((snapshot) {
      debugPrint(
        'RealtimeSupabase: Received ${snapshot.length} workflows for user $userId',
      );
      return snapshot.map((doc) {
        try {
          return Workflow.fromJson(doc);
        } on Exception catch (e) {
          debugPrint('Error parsing workflow ${doc['id']}: $e');
          return null;
        }
      }).whereType<Workflow>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Workflows by user stream error: $error');
      return <Workflow>[];
    });
  }

  /// Get real-time stream of pending approvals for a specific user
  Stream<List<Workflow>> getPendingApprovalsByUserStream(String userId) {
    return _client
        .from('workflows')
        .stream(primaryKey: ['id'])
        .map((snapshot) {
      return snapshot.where((doc) {
        final record = Map<String, dynamic>.from(doc);
        return record['status'] == WorkflowStatus.pendingApproval.name &&
               (record['approvers'] as List?)?.contains(userId) == true;
      }).toList();
    })
        .map((snapshot) {
      debugPrint(
        'RealtimeSupabase: Received ${snapshot.length} pending approvals for user $userId',
      );
      return snapshot.map((doc) {
        try {
          return Workflow.fromJson(doc);
        } on Exception catch (e) {
          debugPrint('Error parsing workflow ${doc['id']}: $e');
          return null;
        }
      }).whereType<Workflow>().toList();
    }).handleError((error) {
      debugPrint('RealtimeSupabase: Pending approvals stream error: $error');
      return <Workflow>[];
    });
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if Supabase is connected
  Future<bool> isConnected() async {
    try {
      await _client.from('users').select().limit(1);
      return true;
    } on Exception {
      return false;
    }
  }

  /// Get server timestamp (returns current DateTime)
  DateTime get serverTimestamp => DateTime.now();
}
