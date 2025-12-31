import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/work_order.dart';
import '../../providers/unified_data_provider.dart';
import '../../services/supabase_storage_service.dart';
import '../../utils/app_theme.dart';

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
  File? _selectedPhoto;
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
          _selectedPhoto = File(photo.path);
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
          _selectedPhoto = File(photo.path);
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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFE5E7EB),
        appBar: AppBar(
          title: const Text('Edit Request'),
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.darkTextColor,
          elevation: AppTheme.elevationS,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Container(
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
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Ticket number
                Container(
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
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Problem Description
                TextFormField(
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
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Priority Selection
                DropdownButtonFormField<WorkOrderPriority>(
                  initialValue: _selectedPriority,
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
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Category Selection
                DropdownButtonFormField<RepairCategory>(
                  initialValue: _selectedCategory,
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
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Photo Upload Section
                Container(
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
                              child: Image.file(
                                _selectedPhoto!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppTheme.spacingM,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickPhotoFromGallery,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('From Gallery'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppTheme.spacingM,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXL),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveChanges,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingM,
                    ),
                    minimumSize: const Size(0, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

