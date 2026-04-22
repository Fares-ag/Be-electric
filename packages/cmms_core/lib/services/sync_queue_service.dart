// Sync Queue Service - Manages pending sync operations

import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/asset.dart';
import '../models/inventory_item.dart';
import '../models/pm_task.dart';
import '../models/user.dart' as app_user;
import '../models/work_order.dart';

enum SyncOperationType {
  create,
  update,
  delete,
}

class SyncOperation {
  SyncOperation({
    required this.id,
    required this.type,
    required this.collection,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.error,
  });

  factory SyncOperation.fromMap(Map<String, dynamic> map) => SyncOperation(
        id: map['id'],
        type: SyncOperationType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => SyncOperationType.create,
        ),
        collection: map['collection'],
        data: map['data'],
        timestamp: DateTime.parse(map['timestamp']),
        retryCount: map['retryCount'] ?? 0,
        error: map['error'],
      );
  final String id;
  final SyncOperationType type;
  final String collection;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? error;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'collection': collection,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
        'error': error,
      };

  SyncOperation copyWith({
    String? id,
    SyncOperationType? type,
    String? collection,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
    String? error,
  }) =>
      SyncOperation(
        id: id ?? this.id,
        type: type ?? this.type,
        collection: collection ?? this.collection,
        data: data ?? this.data,
        timestamp: timestamp ?? this.timestamp,
        retryCount: retryCount ?? this.retryCount,
        error: error ?? this.error,
      );
}

class SyncQueueService {
  SyncQueueService._();
  static SyncQueueService? _instance;
  static SyncQueueService get instance => _instance ??= SyncQueueService._();

  static const String _queueKey = 'sync_queue';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(minutes: 2);

  final List<SyncOperation> _queue = [];
  Timer? _retryTimer;
  bool _isProcessing = false;

  /// Initialize the sync queue
  Future<void> initialize() async {
    await _loadQueue();
    _startRetryTimer();
    print(
      'ðŸ”„ Sync Queue Service: Initialized with ${_queue.length} pending operations',
    );
  }

  /// Add operation to sync queue
  Future<void> addOperation(SyncOperation operation) async {
    _queue.add(operation);
    await _saveQueue();
    print(
      'ðŸ”„ Added operation to sync queue: ${operation.type.name} ${operation.collection}',
    );
  }

  /// Add work order operation
  Future<void> addWorkOrderOperation(
    SyncOperationType type,
    WorkOrder workOrder,
  ) async {
    final operation = SyncOperation(
      id: '${type.name}_work_order_${workOrder.id}',
      type: type,
      collection: 'work_orders',
      data: workOrder.toMap(),
      timestamp: DateTime.now(),
    );
    await addOperation(operation);
  }

  /// Add PM task operation
  Future<void> addPMTaskOperation(
    SyncOperationType type,
    PMTask pmTask,
  ) async {
    final operation = SyncOperation(
      id: '${type.name}_pm_task_${pmTask.id}',
      type: type,
      collection: 'pm_tasks',
      data: pmTask.toMap(),
      timestamp: DateTime.now(),
    );
    await addOperation(operation);
  }

  /// Add asset operation
  Future<void> addAssetOperation(
    SyncOperationType type,
    Asset asset,
  ) async {
    final operation = SyncOperation(
      id: '${type.name}_asset_${asset.id}',
      type: type,
      collection: 'assets',
      data: asset.toMap(),
      timestamp: DateTime.now(),
    );
    await addOperation(operation);
  }

  /// Add user operation
  Future<void> addUserOperation(
    SyncOperationType type,
    app_user.User user,
  ) async {
    final operation = SyncOperation(
      id: '${type.name}_user_${user.id}',
      type: type,
      collection: 'users',
      data: user.toMap(),
      timestamp: DateTime.now(),
    );
    await addOperation(operation);
  }

  /// Add inventory item operation
  Future<void> addInventoryItemOperation(
    SyncOperationType type,
    InventoryItem item,
  ) async {
    final operation = SyncOperation(
      id: '${type.name}_inventory_${item.id}',
      type: type,
      collection: 'inventory_items',
      data: item.toMap(),
      timestamp: DateTime.now(),
    );
    await addOperation(operation);
  }

  /// Get pending operations
  List<SyncOperation> getPendingOperations() => List.unmodifiable(_queue);

  /// Get pending operations for a specific collection
  List<SyncOperation> getPendingOperationsForCollection(String collection) =>
      _queue.where((op) => op.collection == collection).toList();

  /// Process all pending operations
  Future<void> processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    print('ðŸ”„ Processing sync queue with ${_queue.length} operations...');

    final operationsToProcess = List<SyncOperation>.from(_queue);
    final successfulOperations = <String>[];

    for (final operation in operationsToProcess) {
      try {
        await _processOperation(operation);
        successfulOperations.add(operation.id);
        print(
          'âœ… Processed operation: ${operation.type.name} ${operation.collection}',
        );
      } catch (e) {
        print('âŒ Failed to process operation ${operation.id}: $e');

        // Increment retry count
        final updatedOperation = operation.copyWith(
          retryCount: operation.retryCount + 1,
          error: e.toString(),
        );

        // Remove old operation and add updated one
        _queue.removeWhere((op) => op.id == operation.id);

        if (updatedOperation.retryCount < _maxRetries) {
          _queue.add(updatedOperation);
          print(
            'ðŸ”„ Operation ${operation.id} will be retried (${updatedOperation.retryCount}/$_maxRetries)',
          );
        } else {
          print(
            'âŒ Operation ${operation.id} exceeded max retries, removing from queue',
          );
        }
      }
    }

    // Remove successful operations
    _queue.removeWhere((op) => successfulOperations.contains(op.id));
    await _saveQueue();

    _isProcessing = false;
    print(
      'ðŸ”„ Sync queue processing completed. ${successfulOperations.length} successful, ${_queue.length} remaining',
    );
  }

  /// Process a single operation
  Future<void> _processOperation(SyncOperation operation) async {
    try {
      switch (operation.type) {
        case SyncOperationType.create:
          await _createInFirebase(operation);
          break;
        case SyncOperationType.update:
          await _updateInFirebase(operation);
          break;
        case SyncOperationType.delete:
          await _deleteInFirebase(operation);
          break;
      }
    } catch (e) {
      print('âŒ Failed to process operation ${operation.id}: $e');
      rethrow;
    }
  }

  /// Create document in Supabase
  Future<void> _createInFirebase(SyncOperation operation) async {
    final client = Supabase.instance.client;
    await client
        .from(operation.collection)
        .insert(operation.data);
  }

  /// Update document in Supabase
  Future<void> _updateInFirebase(SyncOperation operation) async {
    final client = Supabase.instance.client;
    await client
        .from(operation.collection)
        .update(operation.data)
        .eq('id', operation.data['id']);
  }

  /// Delete document in Supabase
  Future<void> _deleteInFirebase(SyncOperation operation) async {
    final client = Supabase.instance.client;
    await client
        .from(operation.collection)
        .delete()
        .eq('id', operation.data['id']);
  }

  /// Mark operation as completed
  Future<void> markOperationCompleted(String operationId) async {
    _queue.removeWhere((op) => op.id == operationId);
    await _saveQueue();
    print('âœ… Marked operation $operationId as completed');
  }

  /// Clear all operations
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
    print('ðŸ”„ Sync queue cleared');
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStats() {
    final stats = <String, int>{};
    for (final operation in _queue) {
      final key = '${operation.type.name}_${operation.collection}';
      stats[key] = (stats[key] ?? 0) + 1;
    }

    return {
      'totalOperations': _queue.length,
      'isProcessing': _isProcessing,
      'operationBreakdown': stats,
      'oldestOperation': _queue.isNotEmpty
          ? _queue
              .map((op) => op.timestamp)
              .reduce((a, b) => a.isBefore(b) ? a : b)
              .toIso8601String()
          : null,
    };
  }

  /// Start retry timer
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryDelay, (_) async {
      if (!_isProcessing && _queue.isNotEmpty) {
        await processQueue();
      }
    });
  }

  /// Load queue from storage
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson != null) {
        final List<dynamic> queueList = json.decode(queueJson);
        _queue.clear();
        _queue.addAll(
          queueList.map(
            (item) => SyncOperation.fromMap(item as Map<String, dynamic>),
          ),
        );
      }
    } catch (e) {
      print('âŒ Failed to load sync queue: $e');
      _queue.clear();
    }
  }

  /// Save queue to storage
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = json.encode(_queue.map((op) => op.toMap()).toList());
      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      print('âŒ Failed to save sync queue: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _retryTimer?.cancel();
  }
}
