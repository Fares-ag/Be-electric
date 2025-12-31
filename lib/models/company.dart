import '../utils/deterministic_id_generator.dart';

class Company {
  Company({
    required this.id,
    required this.name,
    required this.createdAt,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.isActive = true,
    this.updatedAt,
    this.metadata,
  });

  /// Create a new company with deterministic ID
  factory Company.create({
    required String name,
    String? contactEmail,
    String? contactPhone,
    String? address,
    bool isActive = true,
  }) {
    final id = DeterministicIdGenerator.generateCompanyId(name);
    return Company(
      id: id,
      name: name.trim(),
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      address: address,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Company.fromMap(Map<String, dynamic> data) {
    return Company(
      id: data['id'] as String,
      name: data['name'] as String,
      contactEmail: data['contactEmail'] as String?,
      contactPhone: data['contactPhone'] as String?,
      address: data['address'] as String?,
      isActive: _parseBoolFromDynamic(data['isActive']) ?? true,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Helper method to parse DateTime from Supabase (ISO8601 string) or DateTime
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Safely parse boolean from dynamic value
  static bool? _parseBoolFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  final String id;
  final String name;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'address': address,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'metadata': metadata,
      };

  Company copyWith({
    String? id,
    String? name,
    String? contactEmail,
    String? contactPhone,
    String? address,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      Company(
        id: id ?? this.id,
        name: name ?? this.name,
        contactEmail: contactEmail ?? this.contactEmail,
        contactPhone: contactPhone ?? this.contactPhone,
        address: address ?? this.address,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );
}

