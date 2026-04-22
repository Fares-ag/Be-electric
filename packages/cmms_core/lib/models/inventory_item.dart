import '../utils/deterministic_id_generator.dart';

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.sku,
    this.partNumber,
    this.manufacturer,
    this.supplier,
    this.cost,
    this.minimumStock,
    this.maximumStock,
    this.location,
    this.shelf,
    this.bin,
    this.status = 'active',
    this.lastUpdated,
    this.imageUrl,
    this.warranty,
    this.notes,
  });

  /// Create InventoryItem from data map
  factory InventoryItem.fromMap(Map<String, dynamic> data) {
    final sku = data['sku'] ?? '';
    return InventoryItem(
      id: data['id'] ??
          (sku.isNotEmpty
              ? DeterministicIdGenerator.generateInventoryId(sku)
              : ''),
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      description: data['description'],
      sku: sku,
      partNumber: data['partNumber'],
      manufacturer: data['manufacturer'],
      supplier: data['supplier'],
      cost: data['cost']?.toDouble(),
      minimumStock: data['minimumStock']?.toDouble(),
      maximumStock: data['maximumStock']?.toDouble(),
      location: data['location'],
      shelf: data['shelf'],
      bin: data['bin'],
      status: data['status'] ?? 'active',
      createdAt: _parseFirestoreDate(data['createdAt']) ?? DateTime.now(),
      lastUpdated: _parseFirestoreDate(data['lastUpdated']),
      updatedAt: _parseFirestoreDate(data['updatedAt']) ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      warranty: data['warranty'],
      notes: data['notes'],
    );
  }

  /// Create a new inventory item with deterministic ID
  factory InventoryItem.create({
    required String name,
    required String category,
    required double quantity,
    required String unit,
    String? description,
    String? sku,
    String? partNumber,
    String? manufacturer,
    String? supplier,
    double? cost,
    double? minimumStock,
    double? maximumStock,
    String? location,
    String? shelf,
    String? bin,
    String status = 'active',
    String? imageUrl,
    String? warranty,
    String? notes,
  }) {
    final id = sku != null && sku.isNotEmpty
        ? DeterministicIdGenerator.generateInventoryId(sku)
        : '';

    final now = DateTime.now();
    return InventoryItem(
      id: id,
      name: name.trim(),
      category: category.trim(),
      quantity: quantity,
      unit: unit.trim(),
      description: description,
      sku: sku,
      partNumber: partNumber,
      manufacturer: manufacturer,
      supplier: supplier,
      cost: cost,
      minimumStock: minimumStock,
      maximumStock: maximumStock,
      location: location,
      shelf: shelf,
      bin: bin,
      status: status,
      imageUrl: imageUrl,
      warranty: warranty,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      lastUpdated: now,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'description': description,
        'sku': sku,
        'partNumber': partNumber,
        'manufacturer': manufacturer,
        'supplier': supplier,
        'cost': cost,
        'minimumStock': minimumStock,
        'maximumStock': maximumStock,
        'location': location,
        'shelf': shelf,
        'bin': bin,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'imageUrl': imageUrl,
        'warranty': warranty,
        'notes': notes,
      };

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    String? description,
    String? sku,
    String? partNumber,
    String? manufacturer,
    String? supplier,
    double? cost,
    double? minimumStock,
    double? maximumStock,
    String? location,
    String? shelf,
    String? bin,
    String? status,
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? updatedAt,
    String? imageUrl,
    String? warranty,
    String? notes,
  }) =>
      InventoryItem(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        description: description ?? this.description,
        sku: sku ?? this.sku,
        partNumber: partNumber ?? this.partNumber,
        manufacturer: manufacturer ?? this.manufacturer,
        supplier: supplier ?? this.supplier,
        cost: cost ?? this.cost,
        minimumStock: minimumStock ?? this.minimumStock,
        maximumStock: maximumStock ?? this.maximumStock,
        location: location ?? this.location,
        shelf: shelf ?? this.shelf,
        bin: bin ?? this.bin,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        updatedAt: updatedAt ?? this.updatedAt,
        imageUrl: imageUrl ?? this.imageUrl,
        warranty: warranty ?? this.warranty,
        notes: notes ?? this.notes,
      );

  // Getters
  bool get isLowStock => minimumStock != null && quantity <= minimumStock!;
  bool get isOutOfStock => quantity <= 0;
  bool get isOverstocked => maximumStock != null && quantity > maximumStock!;
  bool get isActive => status == 'active';
  bool get isInactive => status == 'inactive';

  /// Convert InventoryItem to Firestore map
  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'description': description,
        'sku': sku,
        'partNumber': partNumber,
        'manufacturer': manufacturer,
        'supplier': supplier,
        'cost': cost,
        'minimumStock': minimumStock,
        'maximumStock': maximumStock,
        'location': location,
        'shelf': shelf,
        'bin': bin,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'imageUrl': imageUrl,
        'warranty': warranty,
        'notes': notes,
      };

  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final String? description;
  final String? sku;
  final String? partNumber;
  final String? manufacturer;
  final String? supplier;
  final double? cost;
  final double? minimumStock;
  final double? maximumStock;
  final String? location;
  final String? shelf;
  final String? bin;
  final String status;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final DateTime updatedAt;
  final String? imageUrl;
  final String? warranty;
  final String? notes;

  double get currentStock => quantity;
  double get minStock => minimumStock ?? 0;
  double get maxStock => maximumStock ?? double.infinity;

  /// Helper method to parse DateTime from Firestore Timestamp or String
  static DateTime? _parseFirestoreDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Handle Firestore Timestamp
    try {
      return (value as dynamic).toDate();
    } catch (e) {
      return null;
    }
  }
}

enum InventoryCategory {
  spareParts,
  consumables,
  tools,
  safetyEquipment,
  cleaningSupplies,
  officeSupplies,
  electrical,
  mechanical,
  hydraulic,
  pneumatic,
  other,
}

enum InventoryStatus {
  active,
  inactive,
  discontinued,
  onOrder,
}

class InventoryTransaction {
  InventoryTransaction({
    required this.id,
    required this.itemId,
    required this.type,
    required this.quantity,
    required this.date,
    required this.createdBy,
    this.reference,
    this.notes,
    this.cost,
    this.supplier,
    this.workOrderId,
    this.pmTaskId,
  });

  factory InventoryTransaction.fromMap(Map<String, dynamic> map) =>
      InventoryTransaction(
        id: map['id'] ?? '',
        itemId: map['itemId'] ?? '',
        type: map['type'] ?? '',
        quantity: (map['quantity'] ?? 0).toDouble(),
        date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
        createdBy: map['createdBy'] ?? '',
        reference: map['reference'],
        notes: map['notes'],
        cost: map['cost']?.toDouble(),
        supplier: map['supplier'],
        workOrderId: map['workOrderId'],
        pmTaskId: map['pmTaskId'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'itemId': itemId,
        'type': type,
        'quantity': quantity,
        'date': date.toIso8601String(),
        'createdBy': createdBy,
        'reference': reference,
        'notes': notes,
        'cost': cost,
        'supplier': supplier,
        'workOrderId': workOrderId,
        'pmTaskId': pmTaskId,
      };

  final String id;
  final String itemId;
  final String type; // 'in', 'out', 'adjustment', 'transfer'
  final double quantity;
  final DateTime date;
  final String createdBy;
  final String? reference;
  final String? notes;
  final double? cost;
  final String? supplier;
  final String? workOrderId;
  final String? pmTaskId;
}
