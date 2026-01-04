import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/custom_app_bar.dart';
import 'review_maintenance_request_screen.dart';

class CreateMaintenanceRequestScreen extends StatefulWidget {
  const CreateMaintenanceRequestScreen({
    required this.asset,
    required this.qrCode,
    this.chargerType,
    super.key,
  });
  final Asset asset;
  final String qrCode;
  final String? chargerType; // 'Siemens' or 'Kostad'

  @override
  State<CreateMaintenanceRequestScreen> createState() =>
      _CreateMaintenanceRequestScreenState();
}

class _CreateMaintenanceRequestScreenState
    extends State<CreateMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _problemDescriptionController = TextEditingController();
  final _priorityController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isLoading = false;
  String? _selectedCharger;
  String? _selectedCategoryIssue;

  // Photo upload
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedPhotos = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill charger if provided
    if (widget.chargerType != null) {
      _selectedCharger = widget.chargerType;
    }
    // Pre-fill user info - use WidgetsBinding to access context safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user =
            Provider.of<AuthProvider>(context, listen: false).currentUser;
        if (user != null) {
          setState(() {
            _nameController.text = user.name;
            _emailController.text = user.email;
            if (user.department != null) {
              _departmentController.text = user.department!;
            }
            if (user.workEmail != null) {
              _emailController.text = user.workEmail!;
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _problemDescriptionController.dispose();
    _priorityController.dispose();
    _categoryController.dispose();
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
          _selectedPhotos.add(photo);
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
          _selectedPhotos.add(photo);
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

  Future<void> _removePhoto(int index) async {
    if (mounted) {
      setState(() {
        _selectedPhotos.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine charger image based on charger type
    final chargerImagePath = widget.chargerType == 'Siemens'
        ? 'assets/images/SiemensCharger.png'
        : widget.chargerType == 'Kostad'
            ? 'assets/images/KostadCharger.png'
            : null;

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Your Details',
        showMenu: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: isDesktop
              ? _buildDesktopLayout(context, chargerImagePath)
              : _buildMobileTabletLayout(context, chargerImagePath),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, String? chargerImagePath) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.getResponsivePadding(context).horizontal,
        vertical: ResponsiveLayout.getResponsivePadding(context).vertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with charger image
          if (chargerImagePath != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Image.asset(
                  chargerImagePath,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

          const SizedBox(height: 40),

          // Two-column layout for desktop
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFormField(
                        label: 'NAME',
                        controller: _nameController,
                        hintText: 'Enter name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildFormField(
                        label: 'DEPARTMENT',
                        controller: _departmentController,
                        hintText: 'Enter department',
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildFormField(
                        label: 'CONTACT NUMBER',
                        controller: _contactNumberController,
                        hintText: 'Enter number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildDropdownField<String>(
                        label: 'CHARGER',
                        value: _selectedCharger,
                        hintText: 'Select your charger',
                        items: const ['Siemens', 'Kostad'],
                        onChanged: (value) {
                          setState(() {
                            _selectedCharger = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a charger';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Right column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFormField(
                        label: 'EMAIL',
                        controller: _emailController,
                        hintText: 'Enter your work email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildDropdownField<String>(
                        label: 'CATEGORY ISSUE',
                        value: _selectedCategoryIssue,
                        hintText: 'Select type of issue',
                        items: const [
                          'Electrical',
                          'Mechanical',
                          'Software',
                          'Hardware',
                          'Other',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryIssue = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildPhotoSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXL),

          // Full-width problem description
          _buildFormField(
            label: 'PROBLEM DESCRIPTION',
            controller: _problemDescriptionController,
            hintText: 'Enter a detailed description of the issue...',
            maxLines: 5,
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

          const SizedBox(height: AppTheme.spacingXXL),

          // Action button - full width on desktop
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF424242),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXL,
                  vertical: AppTheme.spacingL,
                ),
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 32),
        ],
      ),
    );
  }

  Widget _buildMobileTabletLayout(
      BuildContext context, String? chargerImagePath) {
    return ResponsiveContainer(
      maxWidth: ResponsiveLayout.getFormMaxWidth(context),
      padding: ResponsiveLayout.getResponsivePadding(context),
      centerContent: ResponsiveLayout.isTablet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Charger image at top (centered)
          if (chargerImagePath != null)
            Center(
              child: Image.asset(
                chargerImagePath,
                height: ResponsiveLayout.getResponsiveSpacing(
                  context,
                  mobile: 120,
                  tablet: 140,
                  desktop: 160,
                ),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),

          SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
              context,
              mobile: AppTheme.spacingXL,
              tablet: AppTheme.spacingXXL,
              desktop: AppTheme.spacingXXL * 1.5,
            ),
          ),

          // NAME field
          _buildFormField(
            label: 'NAME',
            controller: _nameController,
            hintText: 'Enter name',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.spacingL),

          // CHARGER dropdown
          _buildDropdownField<String>(
            label: 'CHARGER',
            value: _selectedCharger,
            hintText: 'Select your charger',
            items: const ['Siemens', 'Kostad'],
            onChanged: (value) {
              setState(() {
                _selectedCharger = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a charger';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.spacingL),

          // DEPARTMENT field
          _buildFormField(
            label: 'DEPARTMENT',
            controller: _departmentController,
            hintText: 'Enter department',
          ),

          const SizedBox(height: AppTheme.spacingL),

          // CONTACT NUMBER field
          _buildFormField(
            label: 'CONTACT NUMBER',
            controller: _contactNumberController,
            hintText: 'Enter number',
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: AppTheme.spacingL),

          // EMAIL field
          _buildFormField(
            label: 'EMAIL',
            controller: _emailController,
            hintText: 'Enter your work email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.spacingL),

          // CATEGORY ISSUE dropdown
          _buildDropdownField<String>(
            label: 'CATEGORY ISSUE',
            value: _selectedCategoryIssue,
            hintText: 'Select type of issue',
            items: const [
              'Electrical',
              'Mechanical',
              'Software',
              'Hardware',
              'Other',
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategoryIssue = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.spacingL),

          // PHOTO section
          _buildPhotoSection(),

          const SizedBox(height: AppTheme.spacingL),

          // PROBLEM DESCRIPTION field
          _buildFormField(
            label: 'PROBLEM DESCRIPTION',
            controller: _problemDescriptionController,
            hintText: 'Enter a description...',
            maxLines: 4,
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

          const SizedBox(height: AppTheme.spacingXL),

          // NEXT button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF424242), // Dark grey
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
                : const Text('NEXT'),
          ),

          // Add bottom padding to prevent overflow when keyboard is open
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.smallText.copyWith(
            color: AppTheme.secondaryTextColor,
            fontWeight: FontWeight.w600,
            fontSize: isDesktop ? 13 : 12,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isDesktop ? 10 : AppTheme.spacingS),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            color: Colors.black,
            fontSize: isDesktop ? 15 : 14,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Suisse Int\'l',
              fontSize: isDesktop ? 15 : 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(isDesktop ? 8 : AppTheme.radiusS),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(isDesktop ? 8 : AppTheme.radiusS),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: isDesktop ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(isDesktop ? 8 : AppTheme.radiusS),
              borderSide: BorderSide(
                color: const Color(0xFF424242),
                width: isDesktop ? 2.5 : 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(isDesktop ? 8 : AppTheme.radiusS),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 16,
              vertical: isDesktop ? 16 : 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required String hintText,
    required List<T> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.smallText.copyWith(
            color: AppTheme.secondaryTextColor,
            fontWeight: FontWeight.w600,
            fontSize: isDesktop ? 13 : 12,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isDesktop ? 10 : AppTheme.spacingS),
        DropdownButtonFormField<T>(
          initialValue: value,
          style: TextStyle(
            color: Colors.black,
            fontSize: isDesktop ? 15 : 14,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Suisse Int\'l',
              fontSize: isDesktop ? 15 : 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(isDesktop ? 8 : AppTheme.radiusS),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(isDesktop ? 8 : AppTheme.radiusS),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: isDesktop ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(isDesktop ? 8 : AppTheme.radiusS),
              borderSide: BorderSide(
                color: const Color(0xFF424242),
                width: isDesktop ? 2.5 : 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(isDesktop ? 8 : AppTheme.radiusS),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 16,
              vertical: isDesktop ? 16 : 12,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                style: TextStyle(fontSize: isDesktop ? 15 : 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHOTO',
          style: AppTheme.smallText.copyWith(
            color: AppTheme.secondaryTextColor,
            fontWeight: FontWeight.w600,
            fontSize: isDesktop ? 13 : 12,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isDesktop ? 10 : AppTheme.spacingS),
        if (_selectedPhotos.isNotEmpty) ...[
          SizedBox(
            height: isDesktop ? 120 : 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              itemBuilder: (context, index) {
                final photoSize = isDesktop ? 120.0 : 100.0;
                return Container(
                  margin: EdgeInsets.only(
                    right: isDesktop ? 16 : AppTheme.spacingS,
                  ),
                  width: photoSize,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          isDesktop ? 8 : AppTheme.radiusS,
                        ),
                        child: FutureBuilder<Uint8List>(
                          future: _selectedPhotos[index].readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                height: photoSize,
                                width: photoSize,
                                fit: BoxFit.cover,
                              );
                            }
                            return SizedBox(
                              height: photoSize,
                              width: photoSize,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: EdgeInsets.all(isDesktop ? 6 : 4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: isDesktop ? 18 : 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: isDesktop ? 16 : AppTheme.spacingM),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _capturePhoto,
                icon: Icon(Icons.camera_alt, size: isDesktop ? 20 : 18),
                label: Text(
                  'Take Photo',
                  style: TextStyle(fontSize: isDesktop ? 14 : 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 16 : AppTheme.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isDesktop ? 8 : AppTheme.radiusS,
                    ),
                    side: BorderSide(
                      color: Colors.grey[300]!,
                      width: isDesktop ? 1.5 : 1,
                    ),
                  ),
                  elevation: isDesktop ? 1 : 0,
                ),
              ),
            ),
            SizedBox(width: isDesktop ? 12 : AppTheme.spacingS),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickPhotoFromGallery,
                icon: Icon(Icons.photo_library, size: isDesktop ? 20 : 18),
                label: Text(
                  'From Gallery',
                  style: TextStyle(fontSize: isDesktop ? 14 : 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 16 : AppTheme.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isDesktop ? 8 : AppTheme.radiusS,
                    ),
                    side: BorderSide(
                      color: Colors.grey[300]!,
                      width: isDesktop ? 1.5 : 1,
                    ),
                  ),
                  elevation: isDesktop ? 1 : 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Determine charger image path
    final chargerImagePath = widget.chargerType == 'Siemens'
        ? 'images/SiemensCharger.png'
        : widget.chargerType == 'Kostad'
            ? 'images/KostadCharger.png'
            : null;

    // Get charger ID from asset - format it better
    final chargerId = widget.asset.id.isNotEmpty
        ? widget.asset.id
        : (_selectedCharger ?? 'UNKNOWN').toUpperCase();

    // Navigate to review screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewMaintenanceRequestScreen(
            asset: widget.asset,
            name: _nameController.text.trim(),
            chargerId: chargerId,
            department: _departmentController.text.trim(),
            contactNumber: _contactNumberController.text.trim(),
            email: _emailController.text.trim(),
            category: _selectedCategoryIssue ?? '',
            problemDescription: _problemDescriptionController.text.trim(),
            selectedPhotos: _selectedPhotos,
            chargerType: _selectedCharger ?? '',
            chargerImagePath: chargerImagePath,
          ),
        ),
      );
    }
  }
}
