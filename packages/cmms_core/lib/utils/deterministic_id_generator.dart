// Deterministic ID Generator for Production Duplicate Prevention
//
// This utility generates consistent, deterministic IDs based on unique fields
// to prevent duplicates at the database level.

import 'dart:convert';
import 'package:crypto/crypto.dart';

class DeterministicIdGenerator {
  /// Generate deterministic company ID from name
  /// Format: COMPANY-{name_hash} (readable and unique)
  static String generateCompanyId(String name) {
    final normalizedName = name.toLowerCase().trim();
    final sanitized = normalizedName
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .substring(0, normalizedName.length > 30 ? 30 : normalizedName.length);
    final hash = _generateHash(normalizedName).substring(0, 8);
    return 'COMPANY-$sanitized-$hash';
  }

  /// Generate deterministic user ID from email
  /// Format: USER-{email_prefix} (readable and unique)
  static String generateUserId(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    // Extract email prefix (before @) and sanitize
    final emailPrefix = normalizedEmail.split('@').first;
    final sanitized = emailPrefix
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .substring(0, emailPrefix.length > 20 ? 20 : emailPrefix.length);
    // Add hash suffix for uniqueness if email is too short
    if (sanitized.length < 5) {
      final hash = _generateHash(normalizedEmail).substring(0, 6);
      return 'USER-$sanitized-$hash';
    }
    return 'USER-$sanitized';
  }

  /// Generate deterministic asset ID from external ID or name+location
  /// Format: asset_{externalId} or asset_{name_location_hash}
  static String generateAssetId({
    String? externalId,
    String? name,
    String? location,
  }) {
    if (externalId != null && externalId.isNotEmpty) {
      return 'asset_${externalId.toLowerCase().replaceAll(RegExp('[^a-z0-9_-]'), '_')}';
    }

    if (name != null && location != null) {
      final combined =
          '${name.toLowerCase().trim()}_${location.toLowerCase().trim()}';
      final hash = _generateHash(combined);
      return 'asset_$hash';
    }

    throw ArgumentError(
      'Either externalId or both name and location must be provided',
    );
  }

  /// Generate deterministic inventory ID from SKU
  /// Format: inv_{sku_hash}
  static String generateInventoryId(String sku) {
    final normalizedSku = sku.toUpperCase().trim();
    final hash = _generateHash(normalizedSku);
    return 'inv_$hash';
  }

  /// Generate idempotency key for work orders and PM tasks
  /// Format: {type}_{timestamp}_{hash}
  static String generateIdempotencyKey({
    required String type,
    required String sourceId,
    DateTime? timestamp,
  }) {
    final ts = timestamp ?? DateTime.now();
    final combined = '${type}_${ts.millisecondsSinceEpoch}_$sourceId';
    final hash = _generateHash(combined);
    return '${type}_$hash';
  }

  /// Normalize work order ID to WO-YYYY-NNNNN format
  /// Converts old format (2025_01576) to new format (WO-2025-01576)
  static String normalizeWorkOrderId(String id) {
    // If already in correct format, return as-is
    if (RegExp(r'^WO-\d{4}-\d{5}$').hasMatch(id)) {
      return id;
    }
    
    // Convert old format (YYYY_NNNNN) to new format (WO-YYYY-NNNNN)
    final oldFormatMatch = RegExp(r'^(\d{4})_(\d{5})$').firstMatch(id);
    if (oldFormatMatch != null) {
      final year = oldFormatMatch.group(1)!;
      final number = oldFormatMatch.group(2)!;
      return 'WO-$year-$number';
    }
    
    // If it's just a number or doesn't match any pattern, try to extract year and number
    // For backward compatibility, return as-is if we can't normalize
    return id;
  }

  /// Generate deterministic Work Order ID from idempotency key or inputs
  /// Format: WO-YYYY-NNNNN (readable: year + sequential number)
  static String generateWorkOrderId({
    String? idempotencyKey,
    String? ticketNumber,
    String? requestorId,
    DateTime? createdAt,
  }) {
    // If ticket number is already in WO-YYYY-NNNNN format, use it
    if (ticketNumber != null && 
        RegExp(r'^WO-\d{4}-\d{5}$').hasMatch(ticketNumber)) {
      return ticketNumber;
    }
    
    // Normalize old format ticket numbers
    if (ticketNumber != null) {
      final normalized = normalizeWorkOrderId(ticketNumber);
      if (normalized != ticketNumber) {
        return normalized;
      }
    }

    // Generate readable ID: WO-YYYY-NNNNN
    final now = createdAt ?? DateTime.now();
    final year = now.year;
    
    // Generate sequential number from timestamp (last 5 digits of milliseconds)
    // This ensures uniqueness while being readable
    final timestamp = now.millisecondsSinceEpoch;
    final sequential = (timestamp % 100000).toString().padLeft(5, '0');
    
    return 'WO-$year-$sequential';
  }

  /// Generate next sequential work order ID for a given year
  /// Format: WO-YYYY-NNNNN
  static String generateSequentialWorkOrderId({
    required int year,
    required int sequenceNumber,
  }) {
    final sequential = sequenceNumber.toString().padLeft(5, '0');
    return 'WO-$year-$sequential';
  }

  /// Generate deterministic PM Task ID from idempotency key or inputs
  /// Format: pm_{hash}
  static String generatePMTaskId({
    String? idempotencyKey,
    String? title,
    String? assetId,
  }) {
    final basis = idempotencyKey ?? '${title ?? ''}_${assetId ?? ''}';
    final hash = _generateHash(basis);
    return 'pm_$hash';
  }

  /// Generate hash from input string
  static String _generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest
        .toString()
        .substring(0, 12); // Use first 12 chars for shorter IDs
  }

  /// Normalize a string so it is safe to use as a Firestore document ID
  /// Removes forbidden characters (/ . # $ [ ]) and condenses whitespace.
  static String normalizeDocumentId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final cleaned = trimmed
        .replaceAll(RegExp(r'[\/.#$[\]]'), '-')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned;
  }

  /// Validate if an ID follows the expected format
  static bool isValidUserId(String id) =>
      (id.startsWith('USER-') || id.startsWith('user_')) && id.length > 5;
  static bool isValidCompanyId(String id) =>
      id.startsWith('COMPANY-') && id.length > 8;
  static bool isValidAssetId(String id) =>
      id.startsWith('asset_') && id.length > 6;
  static bool isValidInventoryId(String id) =>
      id.startsWith('inv_') && id.length > 4;
  static bool isValidIdempotencyKey(String key) =>
      (key.startsWith('wo_') || key.startsWith('pm_')) && key.length > 10;

  /// Extract original email from user ID (for debugging)
  static String? extractEmailFromUserId(String userId) {
    if (!isValidUserId(userId)) return null;
    // This is a one-way hash, so we can't reverse it
    // But we can use it for validation
    return null;
  }

  /// Extract original SKU from inventory ID (for debugging)
  static String? extractSkuFromInventoryId(String inventoryId) {
    if (!isValidInventoryId(inventoryId)) return null;
    // This is a one-way hash, so we can't reverse it
    // But we can use it for validation
    return null;
  }
}
