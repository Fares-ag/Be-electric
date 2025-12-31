import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_auth_service.dart';

/// Service for Supabase Storage access with authentication
class SupabaseStorageService {
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();
  static final SupabaseStorageService _instance =
      SupabaseStorageService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Ensure user is authenticated before making Storage requests
  Future<bool> _ensureAuthenticated() async {
    final authService = SupabaseAuthService.instance;
    final isAuthenticated = await authService.ensureAuthenticated();
    
    if (!isAuthenticated) {
      debugPrint('❌ User not authenticated for Supabase Storage access');
      return false;
    }
    
    final supabaseUser = authService.currentSupabaseUser;
    if (supabaseUser == null) {
      debugPrint('❌ No Supabase user found');
      return false;
    }
    
    debugPrint('✅ User authenticated: ${supabaseUser.id} (${supabaseUser.email})');
    return true;
  }

  /// Upload a file to Supabase Storage
  Future<String?> uploadFile({
    required File file,
    required String fileName,
    String? folder,
  }) async {
    // Ensure user is authenticated
    final isAuthenticated = await _ensureAuthenticated();
    if (!isAuthenticated) {
      debugPrint('User not authenticated for Supabase Storage access');
      return null;
    }

    try {
      debugPrint('📤 Uploading file: $fileName');

      // Construct the storage path
      final storagePath = folder != null ? '$folder/$fileName' : fileName;
      
      debugPrint('   Storage path: $storagePath');
      debugPrint('   File size: ${await file.length()} bytes');
      
      // Upload the file
      await _client.storage.from('files').uploadBinary(
        storagePath,
        await file.readAsBytes(),
        fileOptions: const FileOptions(
          upsert: true,
        ),
      );
      
      // Get public URL
      final downloadUrl = _client.storage.from('files').getPublicUrl(storagePath);
      
      debugPrint('✅ Upload completed');
      debugPrint('✅ Download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ Upload error: $e');
      debugPrint('   Error type: ${e.runtimeType}');
      debugPrint('   Stack trace: $stackTrace');
      
      return null;
    }
  }

  /// Upload a photo for work orders
  Future<String?> uploadWorkOrderPhoto({
    required File photoFile,
    required String workOrderId,
  }) async {
    final fileName =
        'work_order_${workOrderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadFile(
      file: photoFile,
      fileName: fileName,
      folder: 'work_orders/photos',
    );
  }

  /// Upload a signature image
  Future<String?> uploadSignature({
    required File signatureFile,
    required String workOrderId,
    required String signatureType, // 'requestor' or 'technician'
  }) async {
    final fileName =
        'signature_${signatureType}_${workOrderId}_${DateTime.now().millisecondsSinceEpoch}.png';
    return uploadFile(
      file: signatureFile,
      fileName: fileName,
      folder: 'work_orders/signatures',
    );
  }

  /// Upload a completion photo
  Future<String?> uploadCompletionPhoto({
    required File photoFile,
    required String workOrderId,
    required String photoType, // 'completion', 'before', 'after'
  }) async {
    final fileName =
        'completion_${photoType}_${workOrderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadFile(
      file: photoFile,
      fileName: fileName,
      folder: 'work_orders/completion_photos',
    );
  }

  /// Upload multiple completion photos
  Future<Map<String, String?>> uploadCompletionPhotos({
    required Map<String, File>
        photos, // 'completion', 'before', 'after' -> File
    required String workOrderId,
  }) async {
    final results = <String, String?>{};

    for (final entry in photos.entries) {
      final photoType = entry.key;
      final photoFile = entry.value;

      final url = await uploadCompletionPhoto(
        photoFile: photoFile,
        workOrderId: workOrderId,
        photoType: photoType,
      );

      results[photoType] = url;
    }

    return results;
  }

  /// Upload a completion photo for PM tasks
  Future<String?> uploadPMTaskCompletionPhoto({
    required File photoFile,
    required String pmTaskId,
  }) async {
    final fileName =
        'pm_task_completion_${pmTaskId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadFile(
      file: photoFile,
      fileName: fileName,
      folder: 'pm_tasks/completion_photos',
    );
  }

  /// Download a file from Supabase Storage
  Future<File?> downloadFile({
    required String downloadUrl,
    required String localPath,
  }) async {
    // Ensure user is authenticated
    final isAuthenticated = await _ensureAuthenticated();
    if (!isAuthenticated) {
      debugPrint('User not authenticated for Supabase Storage access');
      return null;
    }

    try {
      debugPrint('Downloading file: $downloadUrl');

      // Extract path from URL
      final uri = Uri.parse(downloadUrl);
      final pathSegments = uri.pathSegments;
      final storagePath = pathSegments.skip(2).join('/'); // Skip /storage/v1/object/public/files/

      final bytes = await _client.storage.from('files').download(storagePath);

      final file = File(localPath);
      await file.writeAsBytes(bytes);
      debugPrint('File downloaded successfully: $localPath');
      return file;
    } on Exception catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  /// Delete a file from Supabase Storage
  Future<bool> deleteFile(String downloadUrl) async {
    // Ensure user is authenticated
    final isAuthenticated = await _ensureAuthenticated();
    if (!isAuthenticated) {
      debugPrint('User not authenticated for Supabase Storage access');
      return false;
    }

    try {
      debugPrint('Deleting file: $downloadUrl');

      // Extract path from URL
      final uri = Uri.parse(downloadUrl);
      final pathSegments = uri.pathSegments;
      final storagePath = pathSegments.skip(2).join('/'); // Skip /storage/v1/object/public/files/

      await _client.storage.from('files').remove([storagePath]);

      debugPrint('File deleted successfully');
      return true;
    } on Exception catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  /// Test Supabase Storage connection
  Future<bool> testConnection() async {
    // Ensure user is authenticated
    final isAuthenticated = await _ensureAuthenticated();
    if (!isAuthenticated) {
      debugPrint('User not authenticated for Supabase Storage access');
      return false;
    }

    try {
      debugPrint('Testing Supabase Storage connection...');

      // Test by listing files in the bucket
      await _client.storage.from('files').list();

      debugPrint('Supabase Storage connection successful');
      return true;
    } on Exception catch (e) {
      debugPrint('Supabase Storage connection error: $e');
      return false;
    }
  }

  /// Get Supabase Storage configuration status
  Map<String, dynamic> getConfigurationStatus() => {
        'isConfigured': true,
        'storageBucket': 'files',
      };

  /// Clear Supabase Storage configuration (placeholder)
  Future<void> clearConfiguration() async {
    debugPrint('Supabase Storage configuration cleared');
  }

  /// Load configuration (placeholder)
  Future<void> loadConfiguration() async {
    debugPrint('Supabase Storage: Loading configuration...');
  }

  /// Configure Supabase Storage (placeholder)
  Future<void> configureSupabase({
    String? projectId,
    String? bucketName,
  }) async {
    debugPrint('Supabase Storage configured');
  }
}

