import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Dialog to collect pause reason from technician
class PauseReasonDialog extends StatefulWidget {
  const PauseReasonDialog({super.key});

  @override
  State<PauseReasonDialog> createState() => _PauseReasonDialogState();
}

class _PauseReasonDialogState extends State<PauseReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedQuickReason;

  final List<String> _quickReasons = [
    'Waiting for parts',
    'Waiting for approval',
    'Equipment unavailable',
    'Safety issue',
    'Break time',
    'Lunch break',
    'End of shift',
    'Need additional help',
    'Waiting for access',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pause_circle, color: AppTheme.accentOrange),
            SizedBox(width: 8),
            Text('Pause Task'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please provide a reason for pausing this task',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Quick reason dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedQuickReason,
                  decoration: const InputDecoration(
                    labelText: 'Quick Reason',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.list, color: AppTheme.accentBlue),
                  ),
                  items: _quickReasons.map((reason) => DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedQuickReason = value;
                      if (value != 'Other') {
                        _reasonController.text = value!;
                      } else {
                        _reasonController.clear();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null &&
                        _reasonController.text.trim().isEmpty) {
                      return 'Please select or enter a reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Additional details text field
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details (Optional)',
                    hintText: 'Enter any additional information...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes, color: AppTheme.accentBlue),
                  ),
                  maxLines: 3,
                  enabled: _selectedQuickReason == 'Other' ||
                      _selectedQuickReason == null,
                  validator: (value) {
                    if (_selectedQuickReason == null &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please provide a reason';
                    }
                    if (_selectedQuickReason == 'Other' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please provide details for "Other"';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final reason = _reasonController.text.trim().isNotEmpty
                    ? _reasonController.text.trim()
                    : _selectedQuickReason!;
                Navigator.of(context).pop(reason);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pause'),
          ),
        ],
      );
}

/// Show pause reason dialog and return the reason if provided
Future<String?> showPauseReasonDialog(BuildContext context) async =>
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PauseReasonDialog(),
    );
