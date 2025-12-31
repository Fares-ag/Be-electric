import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/asset.dart';
import '../../models/user.dart';
import '../../models/work_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/unified_data_provider.dart';
import '../../screens/assets/enhanced_asset_details_screen.dart';
import '../../services/performance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/enhanced_asset_display_widget.dart';
import '../../widgets/enhanced_asset_selection_widget.dart';
import '../../widgets/mobile_qr_scanner_widget.dart';

class CreateWorkRequestScreen extends StatefulWidget {
  const CreateWorkRequestScreen({super.key, this.initialAsset});

  final Asset? initialAsset;

  @override
  State<CreateWorkRequestScreen> createState() =>
      _CreateWorkRequestScreenState();
}

class _CreateWorkRequestScreenState extends State<CreateWorkRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _problemController = TextEditingController();
  final _locationController = TextEditingController();
  final _requestorNameController = TextEditingController();

  String? _selectedAssetId;
  // Removed unused fields to satisfy linter
  Asset? _selectedAsset;
  String? _photoPath;
  final Set<String> _selectedTechnicianIds = <String>{};
  WorkOrderPriority _selectedPriority = WorkOrderPriority.medium;
  RepairCategory? _selectedCategory;
  bool _isLoading = false;

  // NEW: General maintenance fields
  bool _isGeneralMaintenance = false;
  String? _facilityType;

  @override
  void initState() {
    super.initState();
    // Prefill selection when an initial asset is provided (e.g., from QR scan)
    if (widget.initialAsset != null) {
      _selectedAsset = widget.initialAsset;
      _selectedAssetId = widget.initialAsset!.id;
    }
  }

  @override
  void dispose() {
    _problemController.dispose();
    _locationController.dispose();
    _requestorNameController.dispose();
    super.dispose();
  }

  // Facility type options
  final Map<String, String> _facilityTypes = {
    'Civil': 'Wall Paint, Wall Repairs, Ceiling, etc.',
    'MEP': 'Plumbing, Sliding Door, etc.',
    'Appliances': 'Kettle, Fridge, Microwaves, TV, etc.',
    'Electrical': 'Lights, Sockets, Wires, etc.',
    'Carpentry': 'Ceiling, Wooden Door, etc.',
    'Others': 'Plants, etc.',
  };

  String _getCategoryDisplayName(RepairCategory category) {
    switch (category) {
      case RepairCategory.mechanicalHvac:
        return 'Mechanical & HVAC Repairs';
      case RepairCategory.electrical:
        return 'Electrical Repairs';
      case RepairCategory.structural:
        return 'Structural Repairs';
      case RepairCategory.plumbing:
        return 'Plumbing and Water System Repairs';
      case RepairCategory.interior:
        return 'Interior Repairs';
      case RepairCategory.exterior:
        return 'Exterior Repairs';
      case RepairCategory.itLowVoltage:
        return 'IT & Low Voltage System Repairs';
      case RepairCategory.specializedEquipment:
        return 'Specialized Equipment Repairs';
      case RepairCategory.safetyCompliance:
        return 'Safety & Compliance Repairs';
      case RepairCategory.emergency:
        return 'Emergency or Unscheduled Repairs';
      case RepairCategory.preventive:
        return 'Preventive Maintenance';
      case RepairCategory.reactive:
        return 'Reactive Maintenance';
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Compress the image for better performance
        final compressedPath = await PerformanceService.compressImage(
          pickedFile.path,
        );

        setState(() {
          _photoPath = compressedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _selectImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Compress the image for better performance
        final compressedPath = await PerformanceService.compressImage(
          pickedFile.path,
        );

        setState(() {
          _photoPath = compressedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _selectImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate: either asset is selected OR general maintenance with location
    if (!_isGeneralMaintenance && _selectedAssetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an asset or enable general maintenance'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_isGeneralMaintenance && _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify the location for facility maintenance'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final unifiedProvider = Provider.of<UnifiedDataProvider>(
        context,
        listen: false,
      );

      // Build description with facility type if general maintenance
      var description = _problemController.text.trim();
      if (_isGeneralMaintenance && _facilityType != null) {
        description = '[$_facilityType] $description';
      }

      // If the current user is a technician, don't pass assignedTechnicianIds
      // The provider will auto-assign to them
      final isTechnician = authProvider.currentUser?.role == 'technician';
      
      await unifiedProvider.createWorkOrder(
        assetId: _selectedAssetId, // Can be null for general maintenance
        asset: _selectedAsset, // Pass the full asset object
        location: _isGeneralMaintenance
            ? _locationController.text.trim()
            : null, // Store location for general maintenance
        problemDescription: description,
        requestorId: authProvider.currentUser!.id,
        photoPath: _photoPath,
        priority: _selectedPriority,
        category: _selectedCategory,
        requestorName: _requestorNameController.text.trim().isEmpty
            ? null
            : _requestorNameController.text.trim(),
        // Technicians can't assign others - they're auto-assigned
        assignedTechnicianIds: isTechnician
            ? null
            : (_selectedTechnicianIds.isEmpty
                ? null
                : _selectedTechnicianIds.toList()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work request created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating work request: $e'),
            backgroundColor: AppTheme.errorColor,
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
        appBar: AppBar(title: const Text('New Work Request')),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Asset Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asset Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // NEW: General Maintenance Checkbox
                        CheckboxListTile(
                          title: const Text(
                            'General Facility Maintenance',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'For work not tied to a specific asset (e.g., painting walls, plumbing)',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isGeneralMaintenance,
                          onChanged: (value) {
                            setState(() {
                              _isGeneralMaintenance = value ?? false;
                              if (_isGeneralMaintenance) {
                                // Clear asset selection when switching to general maintenance
                                _selectedAsset = null;
                                _selectedAssetId = null;
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),

                        // Show facility type and location if general maintenance
                        if (_isGeneralMaintenance) ...[
                          // Facility Type Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _facilityType,
                            decoration: const InputDecoration(
                              labelText: 'Facility Type',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.construction),
                            ),
                            hint: const Text('Select facility type'),
                            items: _facilityTypes.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          entry.value,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _facilityType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Location Field
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location *',
                              hintText: 'e.g., Conference Room 3B, Main Lobby',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            validator: (value) {
                              if (_isGeneralMaintenance &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please specify the location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This work order will not be linked to a specific asset',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Show asset selection if NOT general maintenance
                        if (!_isGeneralMaintenance) ...[
                          // QR Scanner Button
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MobileQRScannerWidget(),
                                ),
                              );

                              if (result != null && mounted) {
                                setState(() {
                                  _selectedAssetId = result['assetId'];
                                });
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan QR Code'),
                          ),
                          const SizedBox(height: 8),

                          // Enhanced Asset Selection Button
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EnhancedAssetSelectionWidget(
                                    title: 'Select Asset for Work Order',
                                    onAssetSelected: _handleAssetSelection,
                                  ),
                                ),
                              );

                              if (result != null && mounted) {
                                setState(() {
                                  _selectedAsset = result;
                                  _selectedAssetId = result.id;
                                });
                              }
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('🚀 Enhanced Asset Search'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Enhanced Selected Asset Display
                          if (_selectedAsset != null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Selected Asset:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ComprehensiveAssetDisplayWidget(
                              asset: _selectedAsset!,
                              isCompact: true,
                              onViewDetails: _viewAssetDetails,
                              onSelectAsset: (asset) => _selectAsset(),
                              onEditAsset: (asset) => _selectAsset(),
                            ),
                          ],
                        ], // End of if (!_isGeneralMaintenance)
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Optional Requestor Name (for admin/technician logging on behalf of someone)
                TextFormField(
                  controller: _requestorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Requestor Name (Optional)',
                    hintText: 'Name of the person requesting the work',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Problem Description Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Problem Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _problemController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Describe the problem or issue...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please describe the problem';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Priority Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<WorkOrderPriority>(
                          initialValue: _selectedPriority,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: WorkOrderPriority.values
                              .map(
                                (priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppTheme.getPriorityColor(
                                            priority.name,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(priority.name.toUpperCase()),
                                    ],
                                  ),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Repair Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<RepairCategory>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Select repair category',
                          ),
                          items: RepairCategory.values
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child:
                                      Text(_getCategoryDisplayName(category)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTechnicianAssignmentCard(),
                const SizedBox(height: 16),

                // Photo Attachment Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attach Photo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_photoPath != null) ...[
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_photoPath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showImageSourceDialog,
                            icon: const Icon(Icons.edit),
                            label: const Text('Change Photo'),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: _showImageSourceDialog,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Attach Photo'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      );

  // Handler for Enhanced Asset Selection
  void _handleAssetSelection(Asset asset) {
    setState(() {
      _selectedAsset = asset;
      _selectedAssetId = asset.id;
    });
  }

  // View asset details
  void _viewAssetDetails(Asset asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedAssetDetailsScreen(
          asset: asset,
        ),
      ),
    );
  }

  // Select asset (reopen selection)
  void _selectAsset() {
    // This will trigger the asset selection again
    // The button press will handle this
  }

  Widget _buildTechnicianAssignmentCard() => Consumer<UnifiedDataProvider>(
        builder: (context, unifiedProvider, _) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final isTechnician = authProvider.currentUser?.role == 'technician';
          
          // Hide assignment section for technicians - they're auto-assigned
          if (isTechnician) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This work order will be automatically assigned to you',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final technicians = unifiedProvider.users
              .where((user) => user.isTechnician)
              .toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group_add, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Assign Technicians (optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedTechnicianIds.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(
                            _selectedTechnicianIds.clear,
                          ),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (technicians.isEmpty)
                    Text(
                      'No technicians available',
                      style: AppTheme.smallText.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: technicians.map((tech) {
                        final isSelected =
                            _selectedTechnicianIds.contains(tech.id);
                        final displayName = _technicianName(tech);
                        return FilterChip(
                          selected: isSelected,
                          showCheckmark: true,
                          backgroundColor:
                              isSelected ? AppTheme.accentBlue.withValues(alpha: 0.15) : null,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedTechnicianIds.add(tech.id);
                              } else {
                                _selectedTechnicianIds.remove(tech.id);
                              }
                            });
                          },
                          label: SizedBox(
                            width: 180,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppTheme.accentBlue,
                                  child: Text(
                                    tech.name.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'T',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    displayName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedTechnicianIds.isEmpty
                        ? 'No technicians selected'
                        : 'Selected: ${_selectedTechnicianIds.length}',
                    style: AppTheme.smallText.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  String _technicianName(User tech) {
    if (tech.name.trim().isNotEmpty) return tech.name;
    if (tech.email.trim().isNotEmpty) return tech.email;
    return tech.id;
  }
}
