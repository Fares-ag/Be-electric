// Simple Asset Mapper - Maps external database fields to CMMS format
// Ensures proper field mapping and handles null values correctly

import '../models/asset.dart';

class SimpleAssetMapper {
  /// Map external database asset data to CMMS Asset model
  static Asset mapToCMMSAsset(Map<String, dynamic> externalData) => Asset(
        // Basic Information - Map from external database fields
        id: _safeString(externalData['id']) ??
            _safeString(externalData['assetId']) ??
            '',
        name: _safeString(externalData['name']) ??
            _safeString(externalData['title']) ??
            'Unknown Asset',
        location: _safeString(externalData['location']) ??
            _safeString(externalData['site']) ??
            'Unknown Location',
        description: _safeString(externalData['description']) ??
            _safeString(externalData['notes']),
        category: _safeString(externalData['category']) ??
            _safeString(externalData['type']) ??
            'equipment',
        status: _safeString(externalData['status']) ?? 'active',
        condition: _safeString(externalData['condition']),

        // Technical Details - Map from external database fields
        manufacturer: _safeString(externalData['manufacturer']) ??
            _safeString(externalData['vendor']),
        model: _safeString(externalData['model']) ??
            _safeString(externalData['model_number']),
        serialNumber: _safeString(externalData['serial_number']) ??
            _safeString(externalData['serial']),
        itemType: _safeString(externalData['item_type']) ??
            _safeString(externalData['category']),

        // Location & Assignment - Map from external database fields
        department: _safeString(externalData['department']) ??
            _safeString(externalData['division']),
        assignedStaff: _safeString(externalData['assigned_to']) ??
            _safeString(externalData['owner']),
        company: _safeString(externalData['company']) ??
            _safeString(externalData['department']),

        // Financial Information - Map from external database fields
        supplier: _safeString(externalData['supplier']) ??
            _safeString(externalData['vendor']),
        vendor: _safeString(externalData['vendor']) ??
            _safeString(externalData['supplier']),
        purchasePrice: _safeDouble(externalData['purchase_price']) ??
            _safeDouble(externalData['cost']),
        currentValue: _safeDouble(externalData['current_value']) ??
            _safeDouble(externalData['value']),
        warranty: _safeString(externalData['warranty']) ??
            _safeString(externalData['warranty_info']),
        warrantyExpiry: _parseDate(externalData['warranty_expiry']),
        purchaseDate: _parseDate(externalData['purchase_date']),

        // Maintenance Information - Map from external database fields
        lastMaintenanceDate: _parseDate(externalData['last_maintenance']),
        nextMaintenanceDate: _parseDate(externalData['next_maintenance']),
        maintenanceSchedule:
            _safeString(externalData['maintenance_schedule']) ??
                _safeString(externalData['schedule']),
        installationDate: _parseDate(externalData['installation_date']),
        mileage: _safeInt(externalData['mileage']) ??
            _safeInt(externalData['hours']),

        // Vehicle Information - Map from external database fields
        vehicleIdNo: _safeString(externalData['vehicle_id']) ??
            _safeString(externalData['fleet_number']),
        licPlate: _safeString(externalData['license_plate']) ??
            _safeString(externalData['plate_number']),
        vehicleModel: _safeString(externalData['vehicle_model']) ??
            _safeString(externalData['model']),
        modelDesc: _safeString(externalData['model_description']) ??
            _safeString(externalData['description']),
        modelYear: _safeInt(externalData['model_year']) ??
            _safeInt(externalData['year']),

        // System Information - Map from external database fields
        qrCode: _safeString(externalData['qr_code']) ??
            _safeString(externalData['barcode']),
        qrCodeId: _safeString(externalData['qr_id']) ??
            _safeString(externalData['tag_id']),
        // Image URLs - Try camelCase first (imageUrl), then snake_case (image_url)
        imageUrl: _safeString(externalData['imageUrl']) ??
            _safeString(externalData['image_url']) ??
            _safeString(externalData['photo']),
        imageUrls: externalData['imageUrls'] != null
            ? List<String>.from(externalData['imageUrls'])
            : (externalData['image_urls'] != null
                ? List<String>.from(externalData['image_urls'])
                : null),

        // Metadata - Map from external database fields
        notes: _safeString(externalData['notes']) ??
            _safeString(externalData['comments']),
        createdAt: _parseDate(externalData['created_at']) ?? DateTime.now(),
        updatedAt: _parseDate(externalData['last_updated']) ?? DateTime.now(),
      );

  /// Safe string conversion helper
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) {
      return value.toString(); // Convert Map to string representation
    }
    return value.toString();
  }

  /// Safe double conversion helper
  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safe int conversion helper
  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Parse date from various formats
  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) return DateTime.tryParse(dateValue);

    // Handle Firestore Timestamp
    if (dateValue.toString().contains('Timestamp')) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(
          dateValue.millisecondsSinceEpoch,
        );
      } catch (e) {
        return null;
      }
    }

    return null;
  }
}
