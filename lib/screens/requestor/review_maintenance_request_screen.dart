import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../models/work_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/unified_data_provider.dart';
import '../../services/supabase_storage_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import 'submission_success_screen.dart';

class ReviewMaintenanceRequestScreen extends StatefulWidget {
  const ReviewMaintenanceRequestScreen({
    required this.asset,
    required this.name,
    required this.chargerId,
    required this.department,
    required this.contactNumber,
    required this.email,
    required this.category,
    required this.problemDescription,
    required this.selectedPhotos,
    required this.chargerType,
    super.key,
    this.chargerImagePath,
  });

  final Asset asset;
  final String name;
  final String chargerId;
  final String department;
  final String contactNumber;
  final String email;
  final String category;
  final String problemDescription;
  final List<XFile> selectedPhotos;
  final String chargerType;
  final String? chargerImagePath;

  @override
  State<ReviewMaintenanceRequestScreen> createState() =>
      _ReviewMaintenanceRequestScreenState();
}

class _ReviewMaintenanceRequestScreenState
    extends State<ReviewMaintenanceRequestScreen> {
  bool _isLoading = false;
  final SupabaseStorageService _storageService = SupabaseStorageService();

  Future<void> _submitRequest() async {
    setState(() {
      _isLoading = true;
    });

    // Show loading screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const _SubmissionLoadingScreen(),
          fullscreenDialog: true,
        ),
      );
    }

    try {
      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload photos if any
      List<String> photoUrls = [];
      for (var photo in widget.selectedPhotos) {
        try {
          final photoUrl = await _storageService.uploadFile(
            file: photo,
            fileName: 'request_${DateTime.now().millisecondsSinceEpoch}_${photoUrls.length}.jpg',
            folder: 'work_orders/request_photos',
          );
          if (photoUrl != null) {
            photoUrls.add(photoUrl);
          }
        } catch (e) {
          // Continue with other photos even if one fails
          debugPrint('Error uploading photo: $e');
        }
      }

      // Use first photo URL for the work order (or join all URLs)
      String? photoPath = photoUrls.isNotEmpty ? photoUrls.first : null;

      // Create work order using UnifiedDataProvider
      if (!mounted) return;
      final unifiedProvider =
          Provider.of<UnifiedDataProvider>(context, listen: false);

      // Build notes with user details (for admin/technician reference)
      final notes = '''
Department: ${widget.department.isNotEmpty ? widget.department : 'N/A'}
Charger: ${widget.chargerType}
Charger ID: ${widget.chargerId.isNotEmpty ? widget.chargerId.toUpperCase() : 'N/A'}
Category Issue: ${widget.category.isNotEmpty ? widget.category : 'N/A'}
''';

      // Use location instead of assetId for charger-based requests
      // since the placeholder asset doesn't exist in the database
      final isPlaceholderAsset = widget.asset.id == 'siemens' || widget.asset.id == 'kostad';
      
      await unifiedProvider.createWorkOrder(
        problemDescription: widget.problemDescription, // Just the problem description
        requestorId: user.id,
        assetId: isPlaceholderAsset ? null : widget.asset.id,
        asset: isPlaceholderAsset ? null : widget.asset,
        location: isPlaceholderAsset ? '${widget.chargerType} Charger' : null,
        priority: WorkOrderPriority.medium,
        category: RepairCategory.reactive,
        photoPath: photoPath,
        customerName: widget.name.isNotEmpty ? widget.name : null,
        customerPhone: widget.contactNumber.isNotEmpty ? widget.contactNumber : null,
        customerEmail: widget.email.isNotEmpty ? widget.email : null,
        notes: notes.trim(),
      );

      if (mounted) {
        // Pop loading screen
        Navigator.pop(context);
        
        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SubmissionSuccessScreen(),
            fullscreenDialog: true,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Pop loading screen
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Review your Details',
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Charger image
                        if (widget.chargerImagePath != null)
                          Center(
                            child: Image.asset(
                              widget.chargerImagePath!,
                              height: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.shrink();
                              },
                            ),
                          ),

                        const SizedBox(height: AppTheme.spacingXL),

                        // User and Charger Details
                        _buildDetailRow('Name', widget.name.isNotEmpty ? widget.name : 'N/A'),
                        _buildDetailRow('Charger ID', widget.chargerId.isNotEmpty ? widget.chargerId.toUpperCase() : 'N/A'),
                        _buildDetailRow('Department', widget.department.isNotEmpty ? widget.department : 'N/A'),
                        _buildDetailRow('Contact Number', widget.contactNumber.isNotEmpty ? widget.contactNumber : 'N/A'),
                        _buildDetailRow('Email', widget.email.isNotEmpty ? widget.email : 'N/A'),
                        _buildDetailRow('Category', widget.category.isNotEmpty ? widget.category : 'N/A'),

                        const SizedBox(height: AppTheme.spacingXL),

                        // Photo Attachments Section
                        Text(
                          'PHOTO',
                          style: AppTheme.smallText.copyWith(
                            color: AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              size: 16,
                              color: AppTheme.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.selectedPhotos.length} Attachments',
                              style: AppTheme.smallText.copyWith(
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        if (widget.selectedPhotos.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingM),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.selectedPhotos.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: AppTheme.spacingS),
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                    child: FutureBuilder<Uint8List>(
                                      future: widget.selectedPhotos[index].readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: AppTheme.spacingXL),

                        // Problem Description Section
                        Text(
                          'PROBLEM DESCRIPTION',
                          style: AppTheme.smallText.copyWith(
                            color: AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            widget.problemDescription,
                            style: AppTheme.bodyText.copyWith(
                              color: AppTheme.darkTextColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingXL),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // SEND REQUEST button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingM,
                  ),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('SEND REQUEST'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTheme.smallText.copyWith(
                color: AppTheme.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.darkTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading screen shown during request submission
class _SubmissionLoadingScreen extends StatelessWidget {
  const _SubmissionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002D17), // Dark green background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              strokeWidth: 3,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'Submitting Request..',
              style: AppTheme.heading2.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

