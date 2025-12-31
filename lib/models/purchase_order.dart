import 'package:qauto_cmms/models/inventory_item.dart';
import 'package:qauto_cmms/models/user.dart';

enum PurchaseOrderStatus {
  draft,
  pending,
  approved,
  ordered,
  received,
  cancelled,
}

enum PurchaseOrderPriority {
  low,
  medium,
  high,
  urgent,
}

class PurchaseOrderItem {
  PurchaseOrderItem({
    required this.inventoryItemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    this.inventoryItem,
  });

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) =>
      PurchaseOrderItem(
        inventoryItemId: map['inventoryItemId'] ?? '',
        quantity: map['quantity'] ?? 0,
        unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
        totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
        notes: map['notes'],
      );
  final String inventoryItemId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final InventoryItem? inventoryItem;

  Map<String, dynamic> toMap() => {
        'inventoryItemId': inventoryItemId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'notes': notes,
      };
}

class PurchaseOrder {
  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.title,
    required this.description,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.vendor,
    this.vendorContact,
    this.vendorEmail,
    this.vendorPhone,
    this.approvedAt,
    this.orderedAt,
    this.receivedAt,
    this.createdBy,
    this.approvedBy,
    this.notes,
    this.rejectionReason,
    this.isOffline = false,
    this.lastSyncedAt,
    this.creator,
    this.approver,
  });

  /// Create PurchaseOrder from data map
  factory PurchaseOrder.fromMap(Map<String, dynamic> data) =>
      PurchaseOrder(
        id: data['id'] ?? '',
        poNumber: data['poNumber'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        items: (data['items'] as List<dynamic>?)
                ?.map((item) => PurchaseOrderItem.fromMap(item))
                .toList() ??
            [],
        totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
        status: PurchaseOrderStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => PurchaseOrderStatus.draft,
        ),
        priority: PurchaseOrderPriority.values.firstWhere(
          (e) => e.name == data['priority'],
          orElse: () => PurchaseOrderPriority.medium,
        ),
        vendor: data['vendor'],
        vendorContact: data['vendorContact'],
        vendorEmail: data['vendorEmail'],
        vendorPhone: data['vendorPhone'],
        createdAt: DateTime.parse(data['createdAt']),
        approvedAt: data['approvedAt'] != null
            ? DateTime.parse(data['approvedAt'])
            : null,
        orderedAt: data['orderedAt'] != null
            ? DateTime.parse(data['orderedAt'])
            : null,
        receivedAt: data['receivedAt'] != null
            ? DateTime.parse(data['receivedAt'])
            : null,
        createdBy: data['createdBy'],
        approvedBy: data['approvedBy'],
        notes: data['notes'],
        rejectionReason: data['rejectionReason'],
        isOffline: data['isOffline'] ?? false,
        lastSyncedAt: data['lastSyncedAt'] != null
            ? DateTime.parse(data['lastSyncedAt'])
            : null,
        updatedAt: DateTime.parse(data['updatedAt']),
      );
  final String id;
  final String poNumber;
  final String title;
  final String description;
  final List<PurchaseOrderItem> items;
  final double totalAmount;
  final PurchaseOrderStatus status;
  final PurchaseOrderPriority priority;
  final String? vendor;
  final String? vendorContact;
  final String? vendorEmail;
  final String? vendorPhone;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? orderedAt;
  final DateTime? receivedAt;
  final String? createdBy;
  final String? approvedBy;
  final String? notes;
  final String? rejectionReason;
  final bool isOffline;
  final DateTime? lastSyncedAt;
  final DateTime updatedAt;

  // Related objects
  final User? creator;
  final User? approver;

  Map<String, dynamic> toMap() => {
        'id': id,
        'poNumber': poNumber,
        'title': title,
        'description': description,
        'items': items.map((item) => item.toMap()).toList(),
        'totalAmount': totalAmount,
        'status': status.name,
        'priority': priority.name,
        'vendor': vendor,
        'vendorContact': vendorContact,
        'vendorEmail': vendorEmail,
        'vendorPhone': vendorPhone,
        'createdAt': createdAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'orderedAt': orderedAt?.toIso8601String(),
        'receivedAt': receivedAt?.toIso8601String(),
        'createdBy': createdBy,
        'approvedBy': approvedBy,
        'notes': notes,
        'rejectionReason': rejectionReason,
        'isOffline': isOffline,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  PurchaseOrder copyWith({
    String? id,
    String? poNumber,
    String? title,
    String? description,
    List<PurchaseOrderItem>? items,
    double? totalAmount,
    PurchaseOrderStatus? status,
    PurchaseOrderPriority? priority,
    String? vendor,
    String? vendorContact,
    String? vendorEmail,
    String? vendorPhone,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? orderedAt,
    DateTime? receivedAt,
    String? createdBy,
    String? approvedBy,
    String? notes,
    String? rejectionReason,
    bool? isOffline,
    DateTime? lastSyncedAt,
    DateTime? updatedAt,
    User? creator,
    User? approver,
  }) =>
      PurchaseOrder(
        id: id ?? this.id,
        poNumber: poNumber ?? this.poNumber,
        title: title ?? this.title,
        description: description ?? this.description,
        items: items ?? this.items,
        totalAmount: totalAmount ?? this.totalAmount,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        vendor: vendor ?? this.vendor,
        vendorContact: vendorContact ?? this.vendorContact,
        vendorEmail: vendorEmail ?? this.vendorEmail,
        vendorPhone: vendorPhone ?? this.vendorPhone,
        createdAt: createdAt ?? this.createdAt,
        approvedAt: approvedAt ?? this.approvedAt,
        orderedAt: orderedAt ?? this.orderedAt,
        receivedAt: receivedAt ?? this.receivedAt,
        createdBy: createdBy ?? this.createdBy,
        approvedBy: approvedBy ?? this.approvedBy,
        notes: notes ?? this.notes,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        isOffline: isOffline ?? this.isOffline,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        creator: creator ?? this.creator,
        approver: approver ?? this.approver,
      );

  /// Convert PurchaseOrder to Firestore map
  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'poNumber': poNumber,
        'title': title,
        'description': description,
        'items': items.map((item) => item.toMap()).toList(),
        'totalAmount': totalAmount,
        'status': status.name,
        'priority': priority.name,
        'vendor': vendor,
        'vendorContact': vendorContact,
        'vendorEmail': vendorEmail,
        'vendorPhone': vendorPhone,
        'createdAt': createdAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'orderedAt': orderedAt?.toIso8601String(),
        'receivedAt': receivedAt?.toIso8601String(),
        'createdBy': createdBy,
        'approvedBy': approvedBy,
        'notes': notes,
        'rejectionReason': rejectionReason,
        'isOffline': isOffline,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
