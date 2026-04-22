import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/cmms_app_mode_scope.dart';
import '../../config/cmms_app_mode.dart';
import '../../models/work_order.dart';
import '../../providers/unified_data_provider.dart';
import '../../services/supabase_storage_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/requestor_home_navigation.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/requestor_more_menu.dart';

class EditRequestScreen extends StatefulWidget {
  const EditRequestScreen({
    required this.workOrder,
    super.key,
  });
  final WorkOrder workOrder;

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _problemDescriptionController = TextEditingController();
  bool _isLoading = false;
  WorkOrderPriority _selectedPriority = WorkOrderPriority.medium;
  RepairCategory _selectedCategory = RepairCategory.reactive;

  // Photo upload
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedPhoto;
  final SupabaseStorageService _storageService = SupabaseStorageService();

  @override
  void initState() {
    super.initState();
    _problemDescriptionController.text = widget.workOrder.problemDescription;
    _selectedPriority = widget.workOrder.priority;
    _selectedCategory = widget.workOrder.category ?? RepairCategory.reactive;
  }

  @override
  void dispose() {
    _problemDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (photo != null && mounted) {
        setState(() {
          _selectedPhoto = photo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (photo != null && mounted) {
        setState(() {
          _selectedPhoto = photo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photo: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    if (mounted) {
      setState(() {
        _selectedPhoto = null;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if request can still be edited
    if (widget.workOrder.status != WorkOrderStatus.open &&
        widget.workOrder.status != WorkOrderStatus.assigned) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This request can no longer be edited'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final unifiedProvider =
          Provider.of<UnifiedDataProvider>(context, listen: false);

      // Upload photo if selected
      String? photoUrl = widget.workOrder.photoPath;
      if (_selectedPhoto != null) {
        try {
          photoUrl = await _storageService.uploadFile(
            file: _selectedPhoto!,
            fileName: 'request_${widget.workOrder.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            folder: 'work_orders/request_photos',
          );
          if (photoUrl == null) {
            throw Exception('Failed to upload photo');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading photo: $e'),
                backgroundColor: AppTheme.accentRed,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

      final updatedWorkOrder = widget.workOrder.copyWith(
        problemDescription: _problemDescriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        photoPath: photoUrl,
        updatedAt: DateTime.now(),
      );

      await unifiedProvider.updateWorkOrder(updatedWorkOrder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request updated successfully!'),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
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
    final padding = ResponsiveLayout.getResponsivePadding(context);
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: CustomAppBar(
        title: 'Edit Request',
        usePageTitle: true,
        showMenu: false,
        showBackButton: true,
        onMoreTap: CmmsAppModeScope.maybeOf(context) == CmmsAppMode.requestor
            ? () {
                showRequestorMoreMenu(
                  context,
                  primaryLabel: 'Home',
                  primaryIcon: Icons.home_outlined,
                  onPrimaryNav: () => navigateToRequestorMain(context),
                );
              }
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: padding,
              child: isDesktop
                  ? _buildDesktopLayout(context)
                  : _buildMobileLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildTicketNumber(),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildProblemDescriptionField(),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPriorityField(),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildCategoryField(),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildPhotoSection(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingL),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoBanner(),
        const SizedBox(height: AppTheme.spacingL),
        _buildTicketNumber(),
        const SizedBox(height: AppTheme.spacingL),
        _buildProblemDescriptionField(),
        const SizedBox(height: AppTheme.spacingL),
        _buildPriorityField(),
        const SizedBox(height: AppTheme.spacingL),
        _buildCategoryField(),
        const SizedBox(height: AppTheme.spacingL),
        _buildPhotoSection(),
        const SizedBox(height: AppTheme.spacingL),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.accentBlue,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              'You can only edit requests that are Open or Assigned. Once work has started, editing is no longer available.',
              style: AppTheme.smallText.copyWith(
                color: AppTheme.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketNumber() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.confirmation_number,
            color: AppTheme.accentBlue,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            widget.workOrder.ticketNumber,
            style: AppTheme.heading2.copyWith(
              color: AppTheme.darkTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemDescriptionField() {
    return TextFormField(
      controller: _problemDescriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Problem Description *',
        hintText: 'Describe the issue or maintenance needed...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          borderSide: const BorderSide(
            color: AppTheme.accentBlue,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please describe the problem';
        }
        if (value.trim().length < 10) {
          return 'Please provide a more detailed description';
        }
        return null;
      },
    );
  }

  Widget _buildPriorityField() {
    return DropdownButtonFormField<WorkOrderPriority>(
      value: _selectedPriority,
      decoration: InputDecoration(
        labelText: 'Priority *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          borderSide: const BorderSide(
            color: AppTheme.accentBlue,
            width: 2,
          ),
        ),
      ),
      items: WorkOrderPriority.values
          .map(
            (priority) => DropdownMenuItem(
              value: priority,
              child: Text(priority.name.toUpperCase()),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPriority = value;
          });
        }
      },
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<RepairCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          borderSide: const BorderSide(
            color: AppTheme.accentBlue,
            width: 2,
          ),
        ),
      ),
      items: RepairCategory.values
          .map(
            (category) => DropdownMenuItem(
              value: category,
              child: Text(
                category.name
                    .replaceAll(RegExp('([A-Z])'), r' $1')
                    .trim(),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_camera,
                color: AppTheme.accentBlue,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Photo (Optional)',
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.darkTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          if (widget.workOrder.photoPath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: Text(
                'Current photo will be replaced if you upload a new one',
                style: AppTheme.smallText.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ),
          const SizedBox(height: AppTheme.spacingM),
          if (_selectedPhoto != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  child: FutureBuilder<Uint8List>(
                    future: _selectedPhoto!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _removePhoto,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _capturePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentBlue,
                      side: const BorderSide(color: AppTheme.accentBlue),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhotoFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentBlue,
                      side: const BorderSide(color: AppTheme.accentBlue),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Save Changes'),
    );
  }
}

