import 'dart:convert';

import 'package:qauto_cmms/models/inventory_item.dart';
import 'package:qauto_cmms/models/parts_request.dart';
import 'package:qauto_cmms/services/supabase_database_service.dart';
import 'package:qauto_cmms/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PartsRequestService {
  factory PartsRequestService() => _instance;
  PartsRequestService._internal();
  static final PartsRequestService _instance = PartsRequestService._internal();

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Create a new parts request
  Future<PartsRequest> createPartsRequest({
    required String workOrderId,
    required String technicianId,
    required String inventoryItemId,
    required int quantity,
    required String reason,
    PartsRequestPriority priority = PartsRequestPriority.medium,
    String? notes,
  }) async {
    final now = DateTime.now();
    final request = PartsRequest(
      id: now.millisecondsSinceEpoch.toString(),
      workOrderId: workOrderId,
      technicianId: technicianId,
      inventoryItemId: inventoryItemId,
      quantity: quantity,
      reason: reason,
      priority: priority,
      status: PartsRequestStatus.pending,
      requestedAt: now,
      notes: notes,
      isOffline: true,
      updatedAt: now,
    );

    // Try to create in Firestore if authenticated; fallback to local
    try {
      final id =
          await SupabaseDatabaseService.instance.createPartsRequest(request);
      final cloudRequest = request.copyWith(id: id, isOffline: false);
      await _savePartsRequest(cloudRequest); // mirror to local cache
      // Notify managers/admins of new request
      await _notifyManagersOfNewRequest(cloudRequest);
      return cloudRequest;
    } catch (_) {
      // Offline or unauthenticated path
      await _savePartsRequest(request);
      await _notifyManagersOfNewRequest(request);
      return request;
    }
  }

  // Get all parts requests
  Future<List<PartsRequest>> getAllPartsRequests() async {
    // Prefer Firestore when signed in; fallback to local cache
    List<PartsRequest> requests;
    try {
      requests = await SupabaseDatabaseService.instance.getAllPartsRequests();
      // Mirror cloud state to local cache
      final requestsJson = requests.map((r) => jsonEncode(r.toMap())).toList();
      await _prefs.setStringList('parts_requests', requestsJson);
    } catch (_) {
      final requestsJson = _prefs.getStringList('parts_requests') ?? [];
      requests = requestsJson
          .map((json) => PartsRequest.fromMap(jsonDecode(json)))
          .toList();
    }

    // Load related objects
    final enrichedRequests = <PartsRequest>[];
    for (final request in requests) {
      final enrichedRequest = await _enrichPartsRequest(request);
      enrichedRequests.add(enrichedRequest);
    }

    return enrichedRequests;
  }

  // Get parts requests by work order
  Future<List<PartsRequest>> getPartsRequestsByWorkOrder(
    String workOrderId,
  ) async {
    final allRequests = await getAllPartsRequests();
    return allRequests
        .where((request) => request.workOrderId == workOrderId)
        .toList();
  }

  // Get parts requests by technician
  Future<List<PartsRequest>> getPartsRequestsByTechnician(
    String technicianId,
  ) async {
    final allRequests = await getAllPartsRequests();
    return allRequests
        .where((request) => request.technicianId == technicianId)
        .toList();
  }

  // Get pending parts requests
  Future<List<PartsRequest>> getPendingPartsRequests() async {
    final allRequests = await getAllPartsRequests();
    return allRequests
        .where((request) => request.status == PartsRequestStatus.pending)
        .toList();
  }

  // Approve a parts request
  Future<PartsRequest> approvePartsRequest({
    required String requestId,
    required String approvedBy,
    String? notes,
  }) async {
    final request = await getPartsRequestById(requestId);
    if (request == null) {
      throw Exception('Parts request not found');
    }

    // Block approval if insufficient stock
    final isAvailable = await checkPartsAvailability(
      request.inventoryItemId,
      request.quantity,
    );
    if (!isAvailable) {
      throw Exception('Insufficient stock for the requested item');
    }

    final updatedRequest = request.copyWith(
      status: PartsRequestStatus.approved,
      approvedAt: DateTime.now(),
      approvedBy: approvedBy,
      notes: notes,
      updatedAt: DateTime.now(),
    );

    // Try cloud first, then local
    try {
      await SupabaseDatabaseService.instance
          .updatePartsRequest(updatedRequest.id, updatedRequest);
    } catch (_) {}

    // Adjust inventory stock (reserve) on approval
    await _decrementInventoryQuantity(
      request.inventoryItemId,
      request.quantity,
    );

    await _savePartsRequest(updatedRequest);
    // Notify technician of approval
    await NotificationService().createNotification(
      title: 'Parts Request Approved',
      message:
          'Your parts request for item ${request.inventoryItemId} (qty ${request.quantity}) has been approved.',
      type: NotificationType.systemAlert,
      priority: NotificationPriority.high,
      userId: request.technicianId,
      relatedId: request.workOrderId,
      data: {
        'inventoryItemId': request.inventoryItemId,
        'quantity': request.quantity,
        'status': 'approved',
      },
    );
    return updatedRequest;
  }

  // Reject a parts request
  Future<PartsRequest> rejectPartsRequest({
    required String requestId,
    required String rejectedBy,
    required String rejectionReason,
  }) async {
    final request = await getPartsRequestById(requestId);
    if (request == null) {
      throw Exception('Parts request not found');
    }

    final updatedRequest = request.copyWith(
      status: PartsRequestStatus.rejected,
      approvedBy: rejectedBy,
      rejectionReason: rejectionReason,
      updatedAt: DateTime.now(),
    );

    try {
      await SupabaseDatabaseService.instance
          .updatePartsRequest(updatedRequest.id, updatedRequest);
    } catch (_) {}

    await _savePartsRequest(updatedRequest);
    // Notify technician of rejection
    await NotificationService().createNotification(
      title: 'Parts Request Rejected',
      message:
          'Your parts request for item ${request.inventoryItemId} was rejected.',
      type: NotificationType.systemAlert,
      priority: NotificationPriority.medium,
      userId: request.technicianId,
      relatedId: request.workOrderId,
      data: {
        'inventoryItemId': request.inventoryItemId,
        'quantity': request.quantity,
        'status': 'rejected',
      },
    );
    return updatedRequest;
  }

  // Fulfill a parts request
  Future<PartsRequest> fulfillPartsRequest({
    required String requestId,
    required String fulfilledBy,
  }) async {
    final request = await getPartsRequestById(requestId);
    if (request == null) {
      throw Exception('Parts request not found');
    }

    final updatedRequest = request.copyWith(
      status: PartsRequestStatus.fulfilled,
      fulfilledAt: DateTime.now(),
      approvedBy: fulfilledBy,
      updatedAt: DateTime.now(),
    );

    try {
      await SupabaseDatabaseService.instance
          .updatePartsRequest(updatedRequest.id, updatedRequest);
    } catch (_) {}

    // Ensure inventory is decremented (idempotent safe if already approved)
    await _decrementInventoryQuantity(
      request.inventoryItemId,
      request.quantity,
    );

    await _savePartsRequest(updatedRequest);
    return updatedRequest;
  }

  // Get parts request by ID
  Future<PartsRequest?> getPartsRequestById(String id) async {
    final allRequests = await getAllPartsRequests();
    try {
      return allRequests.firstWhere((request) => request.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update parts request
  Future<PartsRequest> updatePartsRequest(PartsRequest request) async {
    final updatedRequest = request.copyWith(updatedAt: DateTime.now());
    try {
      await SupabaseDatabaseService.instance
          .updatePartsRequest(updatedRequest.id, updatedRequest);
    } catch (_) {}
    await _savePartsRequest(updatedRequest);
    return updatedRequest;
  }

  // Delete parts request
  Future<void> deletePartsRequest(String id) async {
    // Try cloud delete (if you add it later), then local prune
    final allRequests = await getAllPartsRequests();
    final filteredRequests =
        allRequests.where((request) => request.id != id).toList();
    await _savePartsRequests(filteredRequests);
  }

  // Check if parts are available
  Future<bool> checkPartsAvailability(
    String inventoryItemId,
    int quantity,
  ) async {
    // Prefer cloud when available
    try {
      final item = await SupabaseDatabaseService.instance
          .getInventoryItem(inventoryItemId);
      if (item != null) {
        return item.quantity >= quantity;
      }
    } catch (_) {}

    // Fallback to Firestore directly
    final inventoryItem = await SupabaseDatabaseService.instance
        .getInventoryItem(inventoryItemId);
    if (inventoryItem == null) return false;

    return inventoryItem.quantity >= quantity;
  }

  /// Convenience: check whether an item is at/under its minimum stock
  Future<bool> isItemLowStock(String inventoryItemId) async {
    try {
      final item = await SupabaseDatabaseService.instance
          .getInventoryItem(inventoryItemId);
      if (item != null) {
        if (item.minimumStock == null) return false;
        return item.quantity <= item.minimumStock!;
      }
    } catch (_) {}

    // Fallback to Firestore directly
    final item = await SupabaseDatabaseService.instance
        .getInventoryItem(inventoryItemId);
    if (item == null || item.minimumStock == null) return false;
    return item.quantity <= item.minimumStock!;
  }

  // Get low stock alerts
  Future<List<InventoryItem>> getLowStockItems({int threshold = 10}) async {
    final allItems = await SupabaseDatabaseService.instance.getAllInventoryItems();
    return allItems.where((item) => item.quantity <= threshold).toList();
  }

  // Get parts usage statistics
  Future<Map<String, dynamic>> getPartsUsageStats() async {
    final allRequests = await getAllPartsRequests();
    final fulfilledRequests = allRequests
        .where((r) => r.status == PartsRequestStatus.fulfilled)
        .toList();

    final totalRequests = allRequests.length;
    final totalFulfilled = fulfilledRequests.length;
    final totalQuantity =
        fulfilledRequests.fold<int>(0, (sum, r) => sum + r.quantity);

    final requestsByPriority = <PartsRequestPriority, int>{};
    for (final priority in PartsRequestPriority.values) {
      requestsByPriority[priority] =
          allRequests.where((r) => r.priority == priority).length;
    }

    final requestsByStatus = <PartsRequestStatus, int>{};
    for (final status in PartsRequestStatus.values) {
      requestsByStatus[status] =
          allRequests.where((r) => r.status == status).length;
    }

    return {
      'totalRequests': totalRequests,
      'totalFulfilled': totalFulfilled,
      'fulfillmentRate':
          totalRequests > 0 ? (totalFulfilled / totalRequests) * 100 : 0.0,
      'totalQuantity': totalQuantity,
      'requestsByPriority': requestsByPriority,
      'requestsByStatus': requestsByStatus,
    };
  }

  // Private methods
  Future<void> _savePartsRequest(PartsRequest request) async {
    final allRequests = await getAllPartsRequests();
    final index = allRequests.indexWhere((r) => r.id == request.id);

    if (index != -1) {
      allRequests[index] = request;
    } else {
      allRequests.add(request);
    }

    await _savePartsRequests(allRequests);
  }

  Future<void> _savePartsRequests(List<PartsRequest> requests) async {
    final requestsJson = requests.map((r) => jsonEncode(r.toMap())).toList();
    await _prefs.setStringList('parts_requests', requestsJson);
  }

  Future<PartsRequest> _enrichPartsRequest(PartsRequest request) async {
    // Use Firestore to fetch related objects
    final workOrder = await SupabaseDatabaseService.instance
        .getWorkOrder(request.workOrderId);
    final technician = await SupabaseDatabaseService.instance
        .getUserById(request.technicianId);
    final inventoryItem = await SupabaseDatabaseService.instance
        .getInventoryItem(request.inventoryItemId);
    final approver = request.approvedBy != null
        ? await SupabaseDatabaseService.instance.getUserById(request.approvedBy!)
        : null;

    return request.copyWith(
      workOrder: workOrder,
      technician: technician,
      inventoryItem: inventoryItem,
      approver: approver,
    );
  }

  // Decrement inventory quantity in Firestore
  Future<void> _decrementInventoryQuantity(
    String inventoryItemId,
    int quantity,
  ) async {
    try {
      final item = await SupabaseDatabaseService.instance
          .getInventoryItem(inventoryItemId);
      if (item != null) {
        final newQty =
            (item.quantity - quantity).clamp(0.0, double.infinity);
        final updated = item.copyWith(
          quantity: newQty,
          updatedAt: DateTime.now(),
        );
        await SupabaseDatabaseService.instance
            .updateInventoryItem(item.id, updated);
      }
    } catch (e) {
      // Log error but don't throw - best effort inventory update
      print('Error decrementing inventory quantity: $e');
    }
  }

  Future<void> _notifyManagersOfNewRequest(PartsRequest r) async {
    try {
      final users = await SupabaseDatabaseService.instance.getAllUsers();
      final managers =
          users.where((u) => u.role == 'manager' || u.role == 'admin').toList();
      for (final m in managers) {
        await NotificationService().createNotification(
          title: 'New Parts Request',
          message:
              'Technician requested ${r.quantity} of ${r.inventoryItem?.name ?? r.inventoryItemId} for WO ${r.workOrder?.ticketNumber ?? r.workOrderId}.',
          type: NotificationType.systemAlert,
          priority: NotificationPriority.high,
          userId: m.id,
          relatedId: r.workOrderId,
          data: {
            'inventoryItemId': r.inventoryItemId,
            'quantity': r.quantity,
            'status': r.status.name,
          },
        );
      }
    } catch (_) {
      // best-effort notifications
    }
  }
}
