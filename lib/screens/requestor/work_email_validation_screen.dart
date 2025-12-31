import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/unified_data_provider.dart';
import '../../utils/app_theme.dart';

class WorkEmailValidationScreen extends StatefulWidget {
  const WorkEmailValidationScreen({super.key});

  @override
  State<WorkEmailValidationScreen> createState() =>
      _WorkEmailValidationScreenState();
}

class _WorkEmailValidationScreenState extends State<WorkEmailValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workEmailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _workEmailController.dispose();
    super.dispose();
  }

  bool _isValidWorkEmail(String email) {
    // Basic email validation
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    // Check if it's a work email (not common personal email providers)
    final personalDomains = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'icloud.com',
      'aol.com',
      'live.com',
      'msn.com',
    ];

    final domain = email.split('@')[1].toLowerCase();
    return !personalDomains.contains(domain);
  }

  Future<void> _saveWorkEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        // Update user with work email
        final updatedUser =
            user.copyWith(workEmail: _workEmailController.text.trim());

        // Save to database using UnifiedDataProvider
        await Provider.of<UnifiedDataProvider>(context, listen: false)
            .updateUser(updatedUser);

        // Update auth provider
        Provider.of<AuthProvider>(context, listen: false).setUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Work email saved successfully!'),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving work email: $e'),
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
          title: const Text('Work Email Validation'),
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.darkTextColor,
          elevation: AppTheme.elevationS,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.business,
                        size: 60,
                        color: AppTheme.accentBlue,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'Work Email Required',
                        style: AppTheme.heading1.copyWith(
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        'Please provide your work email address to submit maintenance requests.',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXL),

                // Email Input
                TextFormField(
                  controller: _workEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Work Email Address',
                    hintText: 'your.name@company.com',
                    prefixIcon: const Icon(Icons.email_outlined),
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
                      return 'Please enter your work email address';
                    }
                    if (!_isValidWorkEmail(value.trim())) {
                      return 'Please enter a valid work email address (not personal email)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: AppTheme.accentBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.accentBlue,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Why do we need your work email?',
                              style: AppTheme.smallText.copyWith(
                                color: AppTheme.accentBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              'â€¢ To verify your identity when submitting requests\n'
                              'â€¢ To notify you about the status of your requests\n'
                              'â€¢ To ensure only authorized personnel can request maintenance',
                              style: AppTheme.smallText.copyWith(
                                color: AppTheme.accentBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveWorkEmail,
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
                  label: Text(_isLoading ? 'Saving...' : 'Save Work Email'),
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


