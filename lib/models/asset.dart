import '../utils/deterministic_id_generator.dart';

class Asset {
  Asset({
    required this.id,
    required this.name,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.category,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.installationDate,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.status = 'active',
    this.qrCode,
    this.qrCodeId,
    this.itemType,
    this.supplier,
    this.company,
    this.companyId,
    this.department,
    this.assignedStaff,
    this.condition,
    this.imageUrl,
    this.vendor,
    this.vehicleIdNo,
    this.licPlate,
    this.modelDesc,
    this.mileage,
    this.maintenanceSchedule,
    this.purchasePrice,
    this.currentValue,
    this.warranty,
    this.warrantyExpiry,
    this.purchaseDate,
    this.vehicleModel,
    this.modelYear,
    this.imageUrls,
    this.notes,
    this.lastUpdated,
  });

  /// Create Asset from data map
  factory Asset.fromMap(Map<String, dynamic> data) {
    final name = data['name'] ?? '';
    final location = data['location'] ?? '';
    final externalId = data['externalId'];

    return Asset(
      id: data['id'] ??
          DeterministicIdGenerator.generateAssetId(
            externalId: externalId,
            name: name,
            location: location,
          ),
      name: name,
      location: location,
      description: data['description'],
      category: data['category'],
      manufacturer: data['manufacturer'],
      model: data['model'],
      serialNumber: data['serialNumber'],
      installationDate: _parseFirestoreDate(data['installationDate']),
      lastMaintenanceDate: _parseFirestoreDate(data['lastMaintenanceDate']),
      nextMaintenanceDate: _parseFirestoreDate(data['nextMaintenanceDate']),
      status: data['status'] ?? 'active',
      qrCode: data['qrCode'],
      qrCodeId: data['qrCodeId'],
      itemType: data['itemType'],
      supplier: data['supplier'],
      company: data['company'],
      companyId: data['companyId'] as String?,
      department: data['department'],
      assignedStaff: data['assignedStaff'],
      condition: data['condition'],
      imageUrl: data['imageUrl'],
      vendor: data['vendor'],
      vehicleIdNo: data['vehicleIdNo'],
      licPlate: data['licPlate'],
      modelDesc: data['modelDesc'],
      mileage: data['mileage']?.toDouble(),
      maintenanceSchedule: data['maintenanceSchedule'],
      purchasePrice: data['purchasePrice']?.toDouble(),
      warrantyExpiry: _parseFirestoreDate(data['warrantyExpiry']),
      purchaseDate: _parseFirestoreDate(data['purchaseDate']),
      notes: data['notes'],
      vehicleModel: data['vehicleModel'],
      modelYear: data['modelYear'],
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
      createdAt: _parseFirestoreDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseFirestoreDate(data['updatedAt']) ?? DateTime.now(),
      lastUpdated: _parseFirestoreDate(data['lastUpdated']),
    );
  }

  /// Create a new asset with deterministic ID
  factory Asset.create({
    required String name,
    required String location,
    String? externalId,
    String? description,
    String? category,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String status = 'active',
    String? itemType,
    String? supplier,
    String? company,
    String? department,
    String? assignedStaff,
    String? condition,
    String? imageUrl,
    List<String>? imageUrls,
    String? vendor,
    String? vehicleIdNo,
    String? licPlate,
    String? modelDesc,
    int? mileage,
    String? maintenanceSchedule,
    double? purchasePrice,
    double? currentValue,
    String? warranty,
    DateTime? warrantyExpiry,
    DateTime? purchaseDate,
    String? vehicleModel,
    int? modelYear,
    String? notes,
  }) {
    final id = DeterministicIdGenerator.generateAssetId(
      externalId: externalId,
      name: name,
      location: location,
    );

    final now = DateTime.now();
    return Asset(
      id: id,
      name: name.trim(),
      location: location.trim(),
      description: description,
      category: category,
      manufacturer: manufacturer,
      model: model,
      serialNumber: serialNumber,
      status: status,
      itemType: itemType,
      supplier: supplier,
      company: company,
      department: department,
      assignedStaff: assignedStaff,
      condition: condition,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      vendor: vendor,
      vehicleIdNo: vehicleIdNo,
      licPlate: licPlate,
      modelDesc: modelDesc,
      mileage: mileage,
      maintenanceSchedule: maintenanceSchedule,
      purchasePrice: purchasePrice,
      currentValue: currentValue,
      warranty: warranty,
      warrantyExpiry: warrantyExpiry,
      purchaseDate: purchaseDate,
      vehicleModel: vehicleModel,
      modelYear: modelYear,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      lastUpdated: now,
    );
  }

  // Factory method for JSON format
  factory Asset.fromJson(Map<String, dynamic> json) => Asset.fromMap(json);

  // Factory method for Firestore format
  factory Asset.fromFirestore(Map<String, dynamic> data) => Asset(
        id: data['id']?.toString() ?? '',
        name: data['name'] ?? 'Unknown Asset',
        location: data['location'] ?? 'Unknown Location',
        description: data['description'] ?? data['notes'],
        category: data['category'] ?? 'equipment',
        manufacturer: data['manufacturer'] ?? data['vendor'],
        model: data['model'] ?? data['modelCode'],
        serialNumber: data['serialNumber'] ?? data['serial_number'],
        installationDate: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'])
            : null,
        lastMaintenanceDate: data['lastMaintenanceDate'] != null
            ? DateTime.tryParse(data['lastMaintenanceDate'])
            : null,
        nextMaintenanceDate: data['nextMaintenanceDate'] != null
            ? DateTime.tryParse(data['nextMaintenanceDate'])
            : null,
        status: data['status'] ?? 'active',
        qrCode: data['qrCodeId'] ?? data['qr_code'],
        qrCodeId: data['qrCodeId'] ?? data['qr_code'],
        itemType: data['itemType'] ?? data['category'],
        supplier: data['supplier'],
        company: data['company'],
        department: data['department'],
        assignedStaff: data['assignedStaff'] ?? data['owner'],
        condition: data['condition'],
        imageUrl: data['imageUrl'],
        vendor: data['vendor'] ?? data['supplier'],
        vehicleIdNo: data['vehicleIdNo'] ?? data['vehicleIdNumber'],
        licPlate: data['licPlate'],
        modelDesc: data['modelDesc'],
        mileage: data['mileage']?.toInt(),
        maintenanceSchedule: data['maintenanceSchedule'],
        purchasePrice: data['purchasePrice']?.toDouble(),
        currentValue: data['currentValue']?.toDouble(),
        warranty: data['warranty'],
        warrantyExpiry: data['warrantyExpiry'] != null
            ? DateTime.tryParse(data['warrantyExpiry'])
            : null,
        purchaseDate: data['purchaseDate'] != null
            ? DateTime.tryParse(data['purchaseDate'])
            : null,
        vehicleModel: data['vehicleModel'],
        modelYear: data['modelYear']?.toInt(),
        imageUrls: data['imageUrls'] != null
            ? List<String>.from(data['imageUrls'])
            : null,
        notes: data['notes'],
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: data['lastUpdated'] != null
            ? DateTime.tryParse(data['lastUpdated']) ?? DateTime.now()
            : DateTime.now(),
      );

  // Factory method for API JSON format
  factory Asset.fromApiJson(Map<String, dynamic> json) => Asset(
        id: json['id']?.toString() ?? json['asset_id']?.toString() ?? '',
        name: json['name'] ?? json['asset_name'] ?? '',
        location: json['location'] ?? json['site_location'] ?? '',
        description: json['description'] ?? json['notes'],
        category: json['category'] ?? json['asset_type'],
        manufacturer: json['manufacturer'] ?? json['vendor'],
        model: json['model'] ?? json['model_number'],
        serialNumber: json['serial_number'] ?? json['serialNumber'],
        installationDate: json['installation_date'] != null
            ? DateTime.tryParse(json['installation_date'])
            : null,
        lastMaintenanceDate: json['last_maintenance_date'] != null
            ? DateTime.tryParse(json['last_maintenance_date'])
            : null,
        nextMaintenanceDate: json['next_maintenance_date'] != null
            ? DateTime.tryParse(json['next_maintenance_date'])
            : null,
        status: json['status'] ?? json['asset_status'] ?? 'active',
        qrCode: json['qr_code'] ?? json['barcode'] ?? json['tag_id'],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
            : DateTime.now(),
      );

  /// Helper method to parse DateTime from Supabase (ISO8601 string) or DateTime
  static DateTime? _parseFirestoreDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  final String id;
  final String name;
  final String location;
  final String? description;
  final String? category;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final DateTime? installationDate;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final String status; // 'active', 'inactive', 'maintenance'
  final String? qrCode;
  final String? qrCodeId;
  final String? itemType;
  final String? supplier;
  final String? company; // Legacy field, use companyId instead
  final String? companyId; // Foreign key to companies table
  final String? department;
  final String? assignedStaff;
  final String? condition;
  final String? imageUrl;
  final String? vendor;
  final String? vehicleIdNo;
  final String? licPlate;
  final String? modelDesc;
  final int? mileage;
  final String? maintenanceSchedule;
  final double? purchasePrice;
  final double? currentValue;
  final String? warranty;
  final DateTime? warrantyExpiry;
  final DateTime? purchaseDate;
  final String? vehicleModel;
  final int? modelYear;
  final List<String>? imageUrls;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUpdated;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'location': location,
        'description': description,
        'category': category,
        'manufacturer': manufacturer,
        'model': model,
        'serialNumber': serialNumber,
        'installationDate': installationDate?.toIso8601String(),
        'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
        'nextMaintenanceDate': nextMaintenanceDate?.toIso8601String(),
        'status': status,
        'qrCode': qrCode,
        'qrCodeId': qrCodeId,
        'itemType': itemType,
        'supplier': supplier,
        'company': company,
        'department': department,
        'assignedStaff': assignedStaff,
        'condition': condition,
        'imageUrl': imageUrl,
        'vendor': vendor,
        'vehicleIdNo': vehicleIdNo,
        'licPlate': licPlate,
        'modelDesc': modelDesc,
        'mileage': mileage,
        'maintenanceSchedule': maintenanceSchedule,
        'purchasePrice': purchasePrice,
        'currentValue': currentValue,
        'warranty': warranty,
        'warrantyExpiry': warrantyExpiry?.toIso8601String(),
        'purchaseDate': purchaseDate?.toIso8601String(),
        'vehicleModel': vehicleModel,
        'modelYear': modelYear,
        'imageUrls': imageUrls,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  // JSON serialization method
  Map<String, dynamic> toJson() => toMap();

  Asset copyWith({
    String? id,
    String? name,
    String? location,
    String? description,
    String? category,
    String? manufacturer,
    String? model,
    String? serialNumber,
    DateTime? installationDate,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    String? status,
    String? qrCode,
    String? qrCodeId,
    String? itemType,
    String? supplier,
    String? company,
    String? department,
    String? assignedStaff,
    String? condition,
    String? imageUrl,
    String? vendor,
    String? vehicleIdNo,
    String? licPlate,
    String? modelDesc,
    int? mileage,
    String? maintenanceSchedule,
    double? purchasePrice,
    double? currentValue,
    String? warranty,
    DateTime? purchaseDate,
    String? vehicleModel,
    int? modelYear,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUpdated,
  }) =>
      Asset(
        id: id ?? this.id,
        name: name ?? this.name,
        location: location ?? this.location,
        description: description ?? this.description,
        category: category ?? this.category,
        manufacturer: manufacturer ?? this.manufacturer,
        model: model ?? this.model,
        serialNumber: serialNumber ?? this.serialNumber,
        installationDate: installationDate ?? this.installationDate,
        lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
        nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
        status: status ?? this.status,
        qrCode: qrCode ?? this.qrCode,
        qrCodeId: qrCodeId ?? this.qrCodeId,
        itemType: itemType ?? this.itemType,
      supplier: supplier ?? this.supplier,
      company: company ?? this.company,
      companyId: companyId ?? this.companyId,
      department: department ?? this.department,
        assignedStaff: assignedStaff ?? this.assignedStaff,
        condition: condition ?? this.condition,
        imageUrl: imageUrl ?? this.imageUrl,
        vendor: vendor ?? this.vendor,
        vehicleIdNo: vehicleIdNo ?? this.vehicleIdNo,
        licPlate: licPlate ?? this.licPlate,
        modelDesc: modelDesc ?? this.modelDesc,
        mileage: mileage ?? this.mileage,
        maintenanceSchedule: maintenanceSchedule ?? this.maintenanceSchedule,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        currentValue: currentValue ?? this.currentValue,
        warranty: warranty ?? this.warranty,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        modelYear: modelYear ?? this.modelYear,
        imageUrls: imageUrls ?? this.imageUrls,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  String get displayName => '$name - $location';
  bool get isActive => status == 'active';
  bool get isInMaintenance => status == 'maintenance';

  /// Convert Asset to Firestore map
  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'name': name,
        'location': location,
        'description': description,
        'category': category,
        'manufacturer': manufacturer,
        'model': model,
        'serialNumber': serialNumber,
        'installationDate': installationDate?.toIso8601String(),
        'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
        'nextMaintenanceDate': nextMaintenanceDate?.toIso8601String(),
        'status': status,
        'qrCode': qrCode,
        'qrCodeId': qrCodeId,
        'itemType': itemType,
        'supplier': supplier,
        'company': company,
        'department': department,
        'assignedStaff': assignedStaff,
        'condition': condition,
        'imageUrl': imageUrl,
        'vendor': vendor,
        'vehicleIdNo': vehicleIdNo,
        'licPlate': licPlate,
        'modelDesc': modelDesc,
        'mileage': mileage,
        'maintenanceSchedule': maintenanceSchedule,
        'purchasePrice': purchasePrice,
        'warrantyExpiry': warrantyExpiry?.toIso8601String(),
        'notes': notes,
        'vehicleModel': vehicleModel,
        'modelYear': modelYear,
        'imageUrls': imageUrls,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
      };
}
