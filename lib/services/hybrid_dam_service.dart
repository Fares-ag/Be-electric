// Hybrid DAM Service - Automatically tries the best connection method
// First attempts direct Firestore, then falls back to optimized API
// This solves permission issues by using the best available method

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import '../models/asset.dart';
import 'simple_asset_mapper.dart';

class HybridDamService {
  factory HybridDamService() => _instance;
  HybridDamService._internal();
  static final HybridDamService _instance = HybridDamService._internal();

  SupabaseClient? _supabase;
  bool _isInitialized = false;
  String _connectionMethod = 'none';
  List<Asset> _cachedAssets = [];
  DateTime? _lastCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Current connection method being used
  String get connectionMethod => _connectionMethod;

  /// Initialize the hybrid service
  Future<void> initialize() async {
    try {
      // Initialize Supabase client
      _supabase = Supabase.instance.client;

      // Try direct Supabase first
      if (await _tryDirectSupabase()) {
        _connectionMethod = 'direct_supabase';
        return;
      }

      // Fallback to API
      if (await _tryApiConnection()) {
        _connectionMethod = 'api_fallback';
        debugPrint('Hybrid DAM: API fallback connection established');
        return;
      }

      throw Exception('No connection methods available');
    } on Exception catch (e) {
      debugPrint('Hybrid DAM: Initialization failed: $e');
      rethrow;
    }
  }

  /// Try direct Supabase connection
  Future<bool> _tryDirectSupabase() async {
    try {
      if (_supabase == null) return false;
      // Test connection by trying to read a document
      await _supabase!.from('assets').select().limit(1);
      return true;
    } on Exception catch (e) {
      debugPrint('Hybrid DAM: Direct Supabase failed: $e');
      return false;
    }
  }

  /// Try API connection
  Future<bool> _tryApiConnection() async {
    try {
      debugPrint('Hybrid DAM: Attempting API connection...');

      const url =
          '${ApiConfig.assetManagementBaseUrl}${ApiConfig.damGetAssetsEndpoint}';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Key': ApiConfig.damApiKey,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Hybrid DAM: API connection successful');
        return true;
      } else {
        debugPrint('Hybrid DAM: API connection failed: ${response.statusCode}');
        return false;
      }
    } on Exception catch (e) {
      debugPrint('Hybrid DAM: API connection error: $e');
      return false;
    }
  }

  /// Get all assets using the best available method
  Future<List<Asset>> getAllAssets({int? limit}) async {
    try {
      if (!_isInitialized) {
        await initialize();
        _isInitialized = true;
      }

      // Check cache first
      if (_cachedAssets.isNotEmpty && _lastCacheTime != null) {
        final cacheAge = DateTime.now().difference(_lastCacheTime!);
        if (cacheAge < _cacheExpiry) {
          // Removed verbose caching logging
          return limit != null
              ? _cachedAssets.take(limit).toList()
              : _cachedAssets;
        }
      }

      var assets = <Asset>[];

      if (_connectionMethod == 'direct_supabase') {
        assets = await _getAssetsFromSupabase(limit: limit);
      } else if (_connectionMethod == 'api_fallback') {
        assets = await _getAssetsFromApi(limit: limit);
      } else {
        throw Exception('No connection method available');
      }

      // Cache the results
      _cachedAssets = assets;
      _lastCacheTime = DateTime.now();

      // Removed verbose retrieval logging
      // Removed verbose sample asset details logging

      return assets;
    } on Exception catch (e) {
      debugPrint('Hybrid DAM: Error getting assets: $e');
      return [];
    }
  }

  /// Get assets from direct Supabase with full details
  Future<List<Asset>> _getAssetsFromSupabase({int? limit}) async {
    try {
      debugPrint('Hybrid DAM: Fetching from direct Supabase with full details...');

      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      var queryBuilder = _supabase!.from('assets').select();
      if (limit != null) {
        queryBuilder = queryBuilder.limit(limit) as dynamic;
      }

      final response = await queryBuilder;
      final records = response as List;

      final assets = records.map((record) {
        final data = Map<String, dynamic>.from(record);
        return _convertFirestoreAssetToCMMSAsset(data);
      }).toList();

      return assets;
    } on Exception catch (e) {
      debugPrint('Hybrid DAM: Direct Supabase error: $e');
      return [];
    }
  }

  /// Get assets from API
  Future<List<Asset>> _getAssetsFromApi({int? limit}) async {
    try {
      debugPrint('Hybrid DAM: Fetching from API...');

      const url =
          '${ApiConfig.assetManagementBaseUrl}${ApiConfig.damGetAssetsEndpoint}';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Key': ApiConfig.damApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> assetsData;

        if (data is List) {
          assetsData = data;
        } else if (data['assets'] != null) {
          assetsData = data['assets'] as List;
        } else if (data['data'] != null) {
          assetsData = data['data'] as List;
        } else {
          assetsData = [data];
        }

        var assets = assetsData
            .map(
              (data) =>
                  _convertApiAssetToCMMSAsset(data as Map<String, dynamic>),
            )
            .toList();

        if (limit != null) {
          assets = assets.take(limit).toList();
        }

        debugPrint('Hybrid DAM: API returned ${assets.length} assets');
        return assets;
      } else {
        debugPrint('Hybrid DAM: API error: ${response.statusCode}');
        return [];
      }
    } on Exception catch (e) {
      debugPrint('Hybrid DAM: API error: $e');
      return [];
    }
  }

  /// Convert Firestore asset to CMMS asset format
  Asset _convertFirestoreAssetToCMMSAsset(
    Map<String, dynamic> firestoreAsset,
  ) =>
      SimpleAssetMapper.mapToCMMSAsset(firestoreAsset);

  /// Convert API asset to CMMS asset format using SimpleAssetMapper
  Asset _convertApiAssetToCMMSAsset(Map<String, dynamic> apiAsset) =>
      SimpleAssetMapper.mapToCMMSAsset(apiAsset);

  /// Search assets using the current connection method
  Future<List<Asset>> searchAssets(String query) async {
    try {
      final allAssets = await getAllAssets();
      return allAssets
          .where(
            (asset) =>
                asset.name.toLowerCase().contains(query.toLowerCase()) ||
                asset.location.toLowerCase().contains(query.toLowerCase()) ||
                (asset.category?.toLowerCase().contains(query.toLowerCase()) ??
                    false) ||
                (asset.serialNumber
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('Hybrid DAM: Search error: $e');
      return [];
    }
  }

  /// Get asset by ID using the current connection method with full details
  Future<Asset?> getAssetById(String id) async {
    try {
      debugPrint('Hybrid DAM: Getting asset by ID: $id');

      if (_connectionMethod == 'direct_supabase') {
        // Direct Supabase lookup for faster single asset retrieval
        if (_supabase == null) {
          throw Exception('Supabase client not initialized');
        }
        final response = await _supabase!
            .from('assets')
            .select()
            .eq('id', id)
            .maybeSingle();
        
        if (response != null) {
          final data = Map<String, dynamic>.from(response);
          debugPrint('Found asset document with ${data.keys.length} fields');
          final asset = _convertFirestoreAssetToCMMSAsset(data);
          debugPrint('Asset details: ${asset.name} (${asset.location})');
          return asset;
        }
      }

      // Fallback to full asset list search
      final allAssets = await getAllAssets();
      final asset = allAssets.firstWhere(
        (asset) => asset.id == id,
        orElse: () => throw Exception('Asset not found'),
      );
      debugPrint('Found asset: ${asset.name} (${asset.location})');
      return asset;
    } on Exception catch (e) {
      debugPrint('Hybrid DAM: Get asset by ID error: $e');
      return null;
    }
  }

  /// Get asset by QR code using the current connection method with full details
  Future<Asset?> getAssetByQRCode(String qrCode) async {
    try {
      debugPrint('Hybrid DAM: Getting asset by QR code: $qrCode');

      if (_connectionMethod == 'direct_supabase') {
        debugPrint('Searching in Supabase table "assets" for: $qrCode');

        if (_supabase == null) {
          throw Exception('Supabase client not initialized');
        }

        // First try: Search by QR code fields
        debugPrint('Trying qrCode field...');
        final qrResponse = await _supabase!
            .from('assets')
            .select()
            .eq('qrCode', qrCode)
            .limit(1)
            .maybeSingle();

        if (qrResponse != null) {
          final data = Map<String, dynamic>.from(qrResponse);
          debugPrint('Found asset by QR code with ${data.keys.length} fields');
          final asset = _convertFirestoreAssetToCMMSAsset(data);
          debugPrint('Asset details: ${asset.name} (${asset.location})');
          return asset;
        }

        // Second try: Search by alternative QR code field
        debugPrint('Trying qr_code field...');
        final altQrResponse = await _supabase!
            .from('assets')
            .select()
            .eq('qr_code', qrCode)
            .limit(1)
            .maybeSingle();

        if (altQrResponse != null) {
          final data = Map<String, dynamic>.from(altQrResponse);
          debugPrint('Found asset by alternative QR code field with ${data.keys.length} fields');
          final asset = _convertFirestoreAssetToCMMSAsset(data);
          debugPrint('Asset details: ${asset.name} (${asset.location})');
          return asset;
        }

        // Third try: Search by ID field
        debugPrint('Trying id field...');
        final idResponse = await _supabase!
            .from('assets')
            .select()
            .eq('id', qrCode)
            .limit(1)
            .maybeSingle();

        if (idResponse != null) {
          final data = Map<String, dynamic>.from(idResponse);
          debugPrint('Found asset by ID with ${data.keys.length} fields');
          final asset = _convertFirestoreAssetToCMMSAsset(data);
          debugPrint('Asset details: ${asset.name} (${asset.location})');
          return asset;
        }

        debugPrint('No asset found in Supabase with any of the search methods');
      }

      // Fallback to full asset list search
      debugPrint('Falling back to full asset list search...');
      final allAssets = await getAllAssets();
      final asset = allAssets.firstWhere(
        (asset) =>
            asset.qrCode == qrCode ||
            asset.qrCodeId == qrCode ||
            asset.id == qrCode,
        orElse: () => throw Exception('Asset not found'),
      );
      debugPrint('Found asset by QR code: ${asset.name} (${asset.location})');
      return asset;
    } on Exception catch (e) {
      debugPrint('Hybrid DAM: Get asset by QR code error: $e');
      return null;
    }
  }

  /// Get connection status and performance info
  Map<String, dynamic> getConnectionInfo() => {
        'connectionMethod': _connectionMethod,
        'isInitialized': _isInitialized,
        'cachedAssetsCount': _cachedAssets.length,
        'lastCacheTime': _lastCacheTime?.toIso8601String(),
        'cacheAge': _lastCacheTime != null
            ? DateTime.now().difference(_lastCacheTime!).inSeconds
            : null,
      };

  /// Clear cache
  void clearCache() {
    _cachedAssets.clear();
    _lastCacheTime = null;
    debugPrint('Hybrid DAM: Cache cleared');
  }
}
