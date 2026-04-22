import 'package:flutter/material.dart';
import '../models/work_order.dart';
import '../utils/app_theme.dart';

/// Dialog for reopening a work order
/// Allows requestor to provide a reason for reopening and optionally edit the description
class ReopenWorkOrderDialog extends StatefulWidget {
  const ReopenWorkOrderDialog({
    required this.workOrder,
    super.key,
  });

  final WorkOrder workOrder;

  @override
  State<ReopenWorkOrderDialog> createState() => _ReopenWorkOrderDialogState();
}

class _ReopenWorkOrderDialogState extends State<ReopenWorkOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _shouldEditDescription = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.workOrder.problemDescription;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleReopen() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Wait a moment for UI to update
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      final reason = _reasonController.text.trim();
      final editedDescription = _shouldEditDescription
          ? _descriptionController.text.trim()
          : null;

      Navigator.of(context).pop({
        'reopen': true,
        'reason': reason,
        'editedDescription': editedDescription,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.restore,
            color: AppTheme.accentGreen,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reopen Work Order?',
              style: AppTheme.titleStyle.copyWith(
                color: AppTheme.darkTextColor,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will reopen work order ${widget.workOrder.ticketNumber}. '
                        'It will be set back to OPEN status and unassigned. '
                        'Original completion data will be preserved.',
                        style: AppTheme.smallText.copyWith(
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ticket number display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number,
                      color: AppTheme.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.workOrder.ticketNumber,
                      style: AppTheme.heading2.copyWith(
                        color: AppTheme.darkTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Previous status info
              if (widget.workOrder.previousStatus != null ||
                  widget.workOrder.reopenCount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.workOrder.reopenCount > 0)
                        Text(
                          'Reopened ${widget.workOrder.reopenCount} time(s) previously',
                          style: AppTheme.smallText.copyWith(
                            color: AppTheme.secondaryTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (widget.workOrder.reopenedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Last reopened: ${_formatDate(widget.workOrder.reopenedAt!)}',
                          style: AppTheme.smallText.copyWith(
                            color: AppTheme.secondaryTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Reason field (required)
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Reason for Reopening *',
                  hintText: 'Please explain why this work order needs to be reopened...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    borderSide: const BorderSide(
                      color: AppTheme.accentGreen,
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.note,
                    color: AppTheme.accentGreen,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for reopening';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide a more detailed reason (at least 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Optional: Edit description checkbox
              CheckboxListTile(
                value: _shouldEditDescription,
                onChanged: (value) {
                  setState(() {
                    _shouldEditDescription = value ?? false;
                  });
                },
                title: const Text('Edit Problem Description'),
                subtitle: const Text(
                  'Check this to update the problem description',
                ),
                activeColor: AppTheme.accentGreen,
                contentPadding: EdgeInsets.zero,
              ),

              // Description field (if editing)
              if (_shouldEditDescription) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Updated Problem Description',
                    hintText: 'Describe the issue or maintenance needed...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: AppTheme.accentGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (_shouldEditDescription &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please provide a description';
                    }
                    if (_shouldEditDescription &&
                        value != null &&
                        value.trim().length < 10) {
                      return 'Please provide a more detailed description (at least 10 characters)';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.secondaryTextColor),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
          onPressed: _isLoading ? null : _handleReopen,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGreen,
            foregroundColor: Colors.white,
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
              : const Text('Reopen Work Order'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
