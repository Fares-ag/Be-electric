import '../models/parts_request.dart';

/// Build an INSERT row matching live `parts_requests` columns:
/// id, workOrderId, requestedBy, requestedParts, status, requestedAt,
/// createdAt, updatedAt, metadata (+ optional approval fields omitted on create).
Map<String, dynamic> buildPartsRequestInsertPayload({
  required PartsRequest request,
  required String requestedBy,
  String? inventoryItemName,
}) {
  final nowIso = request.requestedAt.toIso8601String();
  final updatedIso = request.updatedAt.toIso8601String();
  final partName = (inventoryItemName != null && inventoryItemName.trim().isNotEmpty)
      ? inventoryItemName.trim()
      : request.inventoryItemId;

  return {
    if (request.id.isNotEmpty) 'id': request.id,
    'workOrderId': request.workOrderId,
    'requestedBy': requestedBy,
    'requestedParts': [
      {
        'inventoryItemId': request.inventoryItemId,
        'name': partName,
        'quantity': request.quantity,
        'unit': request.inventoryItem?.unit,
        'reason': request.reason,
        'priority': request.priority.name,
        if (request.notes != null && request.notes!.trim().isNotEmpty)
          'notes': request.notes!.trim(),
      },
    ],
    'status': request.status.name,
    'requestedAt': nowIso,
    'createdAt': nowIso,
    'updatedAt': updatedIso,
    'metadata': {
      'reason': request.reason,
      'priority': request.priority.name,
      if (request.notes != null && request.notes!.trim().isNotEmpty)
        'notes': request.notes!.trim(),
      'inventoryItemId': request.inventoryItemId,
      'quantity': request.quantity,
    },
  };
}

/// Build an UPDATE row matching live `parts_requests` columns only.
/// Never send legacy app fields (`technicianId`, `inventoryItemId`, `quantity`, `isOffline`).
Map<String, dynamic> buildPartsRequestUpdatePayload({
  required PartsRequest request,
  String? inventoryItemName,
}) {
  final partName = (inventoryItemName != null && inventoryItemName.trim().isNotEmpty)
      ? inventoryItemName.trim()
      : request.inventoryItemId;

  return {
    'status': request.status.name,
    'updatedAt': request.updatedAt.toIso8601String(),
    if (request.approvedBy != null) 'approvedBy': request.approvedBy,
    if (request.approvedAt != null)
      'approvedAt': request.approvedAt!.toIso8601String(),
    if (request.fulfilledAt != null)
      'fulfilledAt': request.fulfilledAt!.toIso8601String(),
    if (request.rejectionReason != null) 'rejectionReason': request.rejectionReason,
    if (request.notes != null) 'notes': request.notes,
    'requestedParts': [
      {
        'inventoryItemId': request.inventoryItemId,
        'name': partName,
        'quantity': request.quantity,
        'unit': request.inventoryItem?.unit,
        'reason': request.reason,
        'priority': request.priority.name,
        if (request.notes != null && request.notes!.trim().isNotEmpty)
          'notes': request.notes!.trim(),
      },
    ],
    'metadata': {
      'reason': request.reason,
      'priority': request.priority.name,
      if (request.notes != null && request.notes!.trim().isNotEmpty)
        'notes': request.notes!.trim(),
      'inventoryItemId': request.inventoryItemId,
      'quantity': request.quantity,
      if (request.rejectionReason != null)
        'rejectionReason': request.rejectionReason,
    },
  };
}

/// Parse live / legacy maps into app-level fields.
({
  String technicianId,
  String inventoryItemId,
  int quantity,
  String reason,
  String priorityName,
  String? notes,
}) parsePartsRequestFields(Map<String, dynamic> data) {
  var technicianId =
      (data['requestedBy'] ?? data['technicianId'] ?? '').toString();
  var inventoryItemId = (data['inventoryItemId'] ?? '').toString();
  var quantity = data['quantity'] is int
      ? data['quantity'] as int
      : int.tryParse('${data['quantity'] ?? ''}') ?? 0;
  var reason = (data['reason'] ?? '').toString();
  var priorityName = (data['priority'] ?? PartsRequestPriority.medium.name)
      .toString();
  var notes = data['notes']?.toString();

  final parts = data['requestedParts'];
  if (parts is List && parts.isNotEmpty) {
    final first = parts.first;
    if (first is Map) {
      final map = Map<String, dynamic>.from(first);
      inventoryItemId =
          (map['inventoryItemId'] ?? inventoryItemId).toString();
      quantity = map['quantity'] is int
          ? map['quantity'] as int
          : int.tryParse('${map['quantity'] ?? ''}') ?? quantity;
      if ((map['reason'] ?? '').toString().isNotEmpty) {
        reason = map['reason'].toString();
      }
      if ((map['priority'] ?? '').toString().isNotEmpty) {
        priorityName = map['priority'].toString();
      }
      if ((map['notes'] ?? '').toString().isNotEmpty) {
        notes = map['notes'].toString();
      }
    }
  }

  final metadata = data['metadata'];
  if (metadata is Map) {
    final meta = Map<String, dynamic>.from(metadata);
    if (inventoryItemId.isEmpty && meta['inventoryItemId'] != null) {
      inventoryItemId = meta['inventoryItemId'].toString();
    }
    if (quantity == 0 && meta['quantity'] != null) {
      quantity = meta['quantity'] is int
          ? meta['quantity'] as int
          : int.tryParse('${meta['quantity']}') ?? 0;
    }
    if (reason.isEmpty && meta['reason'] != null) {
      reason = meta['reason'].toString();
    }
    if (meta['priority'] != null &&
        priorityName == PartsRequestPriority.medium.name) {
      priorityName = meta['priority'].toString();
    }
    notes ??= meta['notes']?.toString();
  }

  return (
    technicianId: technicianId,
    inventoryItemId: inventoryItemId,
    quantity: quantity,
    reason: reason,
    priorityName: priorityName,
    notes: notes,
  );
}
