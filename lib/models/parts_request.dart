import 'package:qauto_cmms/models/inventory_item.dart';
import 'package:qauto_cmms/models/user.dart';
import 'package:qauto_cmms/models/work_order.dart';

enum PartsRequestStatus {
  pending,
  approved,
  rejected,
  fulfilled,
  cancelled,
}

enum PartsRequestPriority {
  low,
  medium,
  high,
  urgent,
}

class PartsRequest {
  PartsRequest({
    required this.id,
    required this.workOrderId,
    required this.technicianId,
    required this.inventoryItemId,
    required this.quantity,
    required this.reason,
    required this.priority,
    required this.status,
    required this.requestedAt,
    required this.updatedAt,
    this.approvedAt,
    this.fulfilledAt,
    this.approvedBy,
    this.rejectionReason,
    this.notes,
    this.isOffline = false,
    this.lastSyncedAt,
    this.workOrder,
    this.technician,
    this.inventoryItem,
    this.approver,
  });

  /// Create PartsRequest from data map
  factory PartsRequest.fromMap(Map<String, dynamic> data) =>
      PartsRequest(
        id: data['id'] ?? '',
        workOrderId: data['workOrderId'] ?? '',
        technicianId: data['technicianId'] ?? '',
        inventoryItemId: data['inventoryItemId'] ?? '',
        quantity: data['quantity'] ?? 0,
        reason: data['reason'] ?? '',
        priority: PartsRequestPriority.values.firstWhere(
          (e) => e.name == data['priority'],
          orElse: () => PartsRequestPriority.medium,
        ),
        status: PartsRequestStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => PartsRequestStatus.pending,
        ),
        requestedAt: DateTime.parse(data['requestedAt']),
        approvedAt: data['approvedAt'] != null
            ? DateTime.parse(data['approvedAt'])
            : null,
        fulfilledAt: data['fulfilledAt'] != null
            ? DateTime.parse(data['fulfilledAt'])
            : null,
        approvedBy: data['approvedBy'],
        rejectionReason: data['rejectionReason'],
        notes: data['notes'],
        isOffline: data['isOffline'] ?? false,
        lastSyncedAt: data['lastSyncedAt'] != null
            ? DateTime.parse(data['lastSyncedAt'])
            : null,
        updatedAt: DateTime.parse(data['updatedAt']),
      );
  final String id;
  final String workOrderId;
  final String technicianId;
  final String inventoryItemId;
  final int quantity;
  final String reason;
  final PartsRequestPriority priority;
  final PartsRequestStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? fulfilledAt;
  final String? approvedBy;
  final String? rejectionReason;
  final String? notes;
  final bool isOffline;
  final DateTime? lastSyncedAt;
  final DateTime updatedAt;

  // Related objects
  final WorkOrder? workOrder;
  final User? technician;
  final InventoryItem? inventoryItem;
  final User? approver;

  Map<String, dynamic> toMap() => {
        'id': id,
        'workOrderId': workOrderId,
        'technicianId': technicianId,
        'inventoryItemId': inventoryItemId,
        'quantity': quantity,
        'reason': reason,
        'priority': priority.name,
        'status': status.name,
        'requestedAt': requestedAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'fulfilledAt': fulfilledAt?.toIso8601String(),
        'approvedBy': approvedBy,
        'rejectionReason': rejectionReason,
        'notes': notes,
        'isOffline': isOffline,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  PartsRequest copyWith({
    String? id,
    String? workOrderId,
    String? technicianId,
    String? inventoryItemId,
    int? quantity,
    String? reason,
    PartsRequestPriority? priority,
    PartsRequestStatus? status,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? fulfilledAt,
    String? approvedBy,
    String? rejectionReason,
    String? notes,
    bool? isOffline,
    DateTime? lastSyncedAt,
    DateTime? updatedAt,
    WorkOrder? workOrder,
    User? technician,
    InventoryItem? inventoryItem,
    User? approver,
  }) =>
      PartsRequest(
        id: id ?? this.id,
        workOrderId: workOrderId ?? this.workOrderId,
        technicianId: technicianId ?? this.technicianId,
        inventoryItemId: inventoryItemId ?? this.inventoryItemId,
        quantity: quantity ?? this.quantity,
        reason: reason ?? this.reason,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        requestedAt: requestedAt ?? this.requestedAt,
        approvedAt: approvedAt ?? this.approvedAt,
        fulfilledAt: fulfilledAt ?? this.fulfilledAt,
        approvedBy: approvedBy ?? this.approvedBy,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        notes: notes ?? this.notes,
        isOffline: isOffline ?? this.isOffline,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        workOrder: workOrder ?? this.workOrder,
        technician: technician ?? this.technician,
        inventoryItem: inventoryItem ?? this.inventoryItem,
        approver: approver ?? this.approver,
      );

  /// Convert PartsRequest to Firestore map
  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'workOrderId': workOrderId,
        'technicianId': technicianId,
        'inventoryItemId': inventoryItemId,
        'quantity': quantity,
        'reason': reason,
        'priority': priority.name,
        'status': status.name,
        'requestedAt': requestedAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'fulfilledAt': fulfilledAt?.toIso8601String(),
        'approvedBy': approvedBy,
        'rejectionReason': rejectionReason,
        'notes': notes,
        'isOffline': isOffline,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
