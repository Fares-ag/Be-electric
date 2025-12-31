import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/supabase_auth_service.dart';

/// Widget that loads images from Firebase Storage with authentication
/// This ensures technicians and all users can view images even when
/// Firebase Storage security rules require authentication
class AuthenticatedImage extends StatefulWidget {
  const AuthenticatedImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.errorWidget,
    this.placeholder,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final Widget? placeholder;

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageBytes = null;
    });

    try {
      // Check if it's a Firebase Storage URL
      final isFirebaseStorageUrl = widget.imageUrl.contains('firebasestorage.googleapis.com') ||
          widget.imageUrl.contains('storage.googleapis.com');

      if (isFirebaseStorageUrl) {
        // Load with authentication headers
        await _loadWithAuth();
      } else {
        // Regular URL - try loading without auth first
        await _loadWithoutAuth();
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWithAuth() async {
    try {
      final authService = SupabaseAuthService.instance;
      final token = await authService.getIdToken();

      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(widget.imageUrl),
        headers: headers,
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        // If auth fails, try without auth (in case token is in URL)
        await _loadWithoutAuth();
      }
    } catch (e) {
      debugPrint('Error loading image with auth: $e');
      // Fallback to loading without auth
      await _loadWithoutAuth();
    }
  }

  Future<void> _loadWithoutAuth() async {
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _isLoading = false;
          _hasError = false;
        });
      } else if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading image without auth: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            height: widget.height,
            width: widget.width,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    if (_hasError || _imageBytes == null) {
      return widget.errorWidget ??
          Container(
            height: widget.height,
            width: widget.width,
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(height: 8),
                  Text('Failed to load image'),
                ],
              ),
            ),
          );
    }

    return Image.memory(
      _imageBytes!,
      fit: widget.fit,
      height: widget.height,
      width: widget.width,
    );
  }
}

