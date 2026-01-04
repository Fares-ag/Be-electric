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
import '../../utils/responsive_layout.dart';
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
    final isDesktop = ResponsiveLayout.isDesktop(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(
        title: 'Review your Details',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF5F5F5),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop 
                      ? ResponsiveLayout.getResponsivePadding(context).horizontal * 2
                      : ResponsiveLayout.getResponsivePadding(context).horizontal,
                  vertical: isDesktop ? 40 : ResponsiveLayout.getResponsivePadding(context).vertical,
                ),
                child: isDesktop
                    ? _buildDesktopLayout(context)
                    : _buildMobileTabletLayout(context),
              ),
            ),
          ),

          // SEND REQUEST button
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop 
                  ? ResponsiveLayout.getResponsivePadding(context).horizontal * 2
                  : ResponsiveLayout.getResponsivePadding(context).horizontal,
              vertical: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? AppTheme.spacingXL : AppTheme.spacingL,
                  vertical: isDesktop ? 18 : AppTheme.spacingM,
                ),
                minimumSize: Size(0, isDesktop ? 56 : 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 8 : AppTheme.radiusS),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: isDesktop ? 24 : 20,
                      height: isDesktop ? 24 : 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'SEND REQUEST',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with charger image
          if (widget.chargerImagePath != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  widget.chargerImagePath!,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

          // Two-column layout for details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildDetailsCard([
                    _buildDetailRow('Name', widget.name.isNotEmpty ? widget.name : 'N/A'),
                    _buildDetailRow('Charger ID', widget.chargerId.isNotEmpty ? widget.chargerId.toUpperCase() : 'N/A'),
                    _buildDetailRow('Department', widget.department.isNotEmpty ? widget.department : 'N/A'),
                  ]),
                ),
              ),

              // Right column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildDetailsCard([
                    _buildDetailRow('Contact Number', widget.contactNumber.isNotEmpty ? widget.contactNumber : 'N/A'),
                    _buildDetailRow('Email', widget.email.isNotEmpty ? widget.email : 'N/A'),
                    _buildDetailRow('Category', widget.category.isNotEmpty ? widget.category : 'N/A'),
                  ]),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Photo section - full width
          _buildPhotoCard(),

          const SizedBox(height: 24),

          // Problem Description - full width
          _buildProblemDescriptionCard(),
        ],
      ),
    );
  }

  Widget _buildMobileTabletLayout(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Charger image
          if (widget.chargerImagePath != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  widget.chargerImagePath!,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

          // Details card
          _buildDetailsCard([
            _buildDetailRow('Name', widget.name.isNotEmpty ? widget.name : 'N/A'),
            _buildDetailRow('Charger ID', widget.chargerId.isNotEmpty ? widget.chargerId.toUpperCase() : 'N/A'),
            _buildDetailRow('Department', widget.department.isNotEmpty ? widget.department : 'N/A'),
            _buildDetailRow('Contact Number', widget.contactNumber.isNotEmpty ? widget.contactNumber : 'N/A'),
            _buildDetailRow('Email', widget.email.isNotEmpty ? widget.email : 'N/A'),
            _buildDetailRow('Category', widget.category.isNotEmpty ? widget.category : 'N/A'),
          ]),

          const SizedBox(height: 24),

          // Photo section
          _buildPhotoCard(),

          const SizedBox(height: 24),

          // Problem Description
          _buildProblemDescriptionCard(),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_library,
                size: 20,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                'PHOTO',
                style: AppTheme.smallText.copyWith(
                  color: AppTheme.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.selectedPhotos.length} Attachment${widget.selectedPhotos.length != 1 ? 's' : ''}',
                style: AppTheme.smallText.copyWith(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (widget.selectedPhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.selectedPhotos.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }

  Widget _buildProblemDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                size: 20,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                'PROBLEM DESCRIPTION',
                style: AppTheme.smallText.copyWith(
                  color: AppTheme.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              widget.problemDescription,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.darkTextColor,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: AppTheme.smallText.copyWith(
                color: AppTheme.secondaryTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.darkTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
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

