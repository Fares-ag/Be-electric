// Accessibility Utilities for Screen Readers and Inclusive Design
//
// Provides helpers for making the Q-AUTO CMMS accessible to all users:
// - Semantic labels for widgets
// - Screen reader announcements
// - Accessibility hints
// - Focus management
// - Contrast checking
//
// Usage:
// ```dart
// // Add semantic label
// Semantics(
//   label: AccessibilityUtils.getWorkOrderLabel(workOrder),
//   child: WorkOrderCard(),
// );
//
// // Announce to screen reader
// AccessibilityUtils.announce(context, 'Work order created successfully');
// ```

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for inclusive design
class AccessibilityUtils {
  AccessibilityUtils._();

  // ========================================
  // SEMANTIC LABELS
  // ========================================

  /// Get semantic label for work order
  ///
  /// Example: "Work order WO-001, Priority: High, Status: Open, Asset: Pump-A"
  static String getWorkOrderLabel(dynamic workOrder) {
    final id = workOrder.id ?? 'Unknown';
    final priority = workOrder.priority ?? 'Normal';
    final status = workOrder.status?.toString().split('.').last ?? 'Unknown';
    final asset = workOrder.asset?.name ?? 'No asset';

    return 'Work order $id, Priority: $priority, Status: $status, Asset: $asset';
  }

  /// Get semantic label for PM task
  ///
  /// Example: "PM task PM-001, Frequency: Monthly, Status: Pending, Asset: Pump-A"
  static String getPMTaskLabel(dynamic pmTask) {
    final id = pmTask.id ?? 'Unknown';
    final frequency = pmTask.frequency ?? 'Unknown';
    final status = pmTask.status?.toString().split('.').last ?? 'Unknown';
    final asset = pmTask.asset?.name ?? 'No asset';

    return 'PM task $id, Frequency: $frequency, Status: $status, Asset: $asset';
  }

  /// Get semantic label for asset
  ///
  /// Example: "Asset Pump-A, Category: Equipment, Status: Operational"
  static String getAssetLabel(dynamic asset) {
    final name = asset.name ?? 'Unknown';
    final category = asset.category ?? 'Uncategorized';
    final status = asset.status ?? 'Unknown';

    return 'Asset $name, Category: $category, Status: $status';
  }

  /// Get semantic label for inventory item
  ///
  /// Example: "Inventory item Oil Filter, Quantity: 25, Location: Warehouse A"
  static String getInventoryLabel(dynamic item) {
    final name = item.name ?? 'Unknown';
    final quantity = item.quantity ?? 0;
    final location = item.location ?? 'Unknown location';

    return 'Inventory item $name, Quantity: $quantity, Location: $location';
  }

  /// Get semantic label for user
  ///
  /// Example: "User John Doe, Role: Technician, Department: Maintenance"
  static String getUserLabel(dynamic user) {
    final name = user.name ?? 'Unknown user';
    final role = user.role ?? 'Unknown role';
    final department = user.department ?? 'No department';

    return 'User $name, Role: $role, Department: $department';
  }

  // ========================================
  // SCREEN READER ANNOUNCEMENTS
  // ========================================

  /// Announce message to screen reader
  ///
  /// Example:
  /// ```dart
  /// AccessibilityUtils.announce(context, 'Work order created successfully');
  /// ```
  static void announce(
    BuildContext context,
    String message, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (message.isEmpty) return;

    SemanticsService.announce(
      message,
      textDirection,
    );
  }

  /// Announce success message
  static void announceSuccess(BuildContext context, String message) {
    announce(context, 'âœ“ Success: $message');
  }

  /// Announce error message
  static void announceError(BuildContext context, String message) {
    announce(context, 'âœ— Error: $message');
  }

  /// Announce warning message
  static void announceWarning(BuildContext context, String message) {
    announce(context, 'âš  Warning: $message');
  }

  // ========================================
  // ACCESSIBILITY HINTS
  // ========================================

  /// Get hint for button
  static String getButtonHint(String action) => 'Double tap to $action';

  /// Get hint for list item
  static String getListItemHint() => 'Double tap to open, swipe for actions';

  /// Get hint for form field
  static String getFormFieldHint(String fieldName) => 'Enter $fieldName';

  /// Get hint for toggle
  static String getToggleHint(bool isOn) =>
      isOn ? 'Double tap to turn off' : 'Double tap to turn on';

  // ========================================
  // FOCUS MANAGEMENT
  // ========================================

  /// Request focus on widget
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  /// Move focus to next field
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous field
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Unfocus all fields
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // ========================================
  // CONTRAST CHECKING
  // ========================================

  /// Calculate contrast ratio between two colors
  ///
  /// Returns ratio from 1:1 (no contrast) to 21:1 (maximum contrast)
  /// WCAG AA requires at least 4.5:1 for normal text
  /// WCAG AAA requires at least 7:1 for normal text
  static double getContrastRatio(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA standard
  static bool meetsWCAGAA(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = getContrastRatio(foreground, background);
    return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  /// Check if contrast ratio meets WCAG AAA standard
  static bool meetsWCAGAAA(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = getContrastRatio(foreground, background);
    return isLargeText ? ratio >= 4.5 : ratio >= 7.0;
  }

  // ========================================
  // TEXT SCALING
  // ========================================

  /// Get accessible font size (respects system text scaling)
  static double getAccessibleFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return baseFontSize * textScaleFactor.clamp(1.0, 2.0); // Limit to 200%
  }

  /// Check if user has large text enabled
  static bool isLargeTextEnabled(BuildContext context) =>
      MediaQuery.of(context).textScaleFactor > 1.3;

  // ========================================
  // SCREEN READER DETECTION
  // ========================================

  /// Check if screen reader is enabled
  static bool isScreenReaderEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.accessibleNavigation;
  }

  /// Check if reduce motion is enabled
  static bool isReduceMotionEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.disableAnimations;
  }

  /// Check if high contrast is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.highContrast;
  }

  // ========================================
  // SEMANTIC WIDGETS
  // ========================================

  /// Wrap widget with semantic label
  static Widget withSemantics({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool? button,
    bool? enabled,
    VoidCallback? onTap,
  }) =>
      Semantics(
        label: label,
        hint: hint,
        value: value,
        button: button,
        enabled: enabled,
        onTap: onTap,
        child: child,
      );

  /// Create accessible button wrapper
  static Widget accessibleButton({
    required Widget child,
    required String label,
    required VoidCallback onPressed,
    String? hint,
    bool enabled = true,
  }) =>
      Semantics(
        label: label,
        hint: hint ?? getButtonHint(label.toLowerCase()),
        button: true,
        enabled: enabled,
        onTap: enabled ? onPressed : null,
        child: child,
      );

  /// Create accessible list item wrapper
  static Widget accessibleListItem({
    required Widget child,
    required String label,
    required VoidCallback onTap,
    String? hint,
  }) =>
      Semantics(
        label: label,
        hint: hint ?? getListItemHint(),
        button: true,
        onTap: onTap,
        child: child,
      );

  // ========================================
  // HELPERS
  // ========================================

  /// Format date for screen readers
  static String formatDateForScreenReader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// Format number for screen readers
  static String formatNumberForScreenReader(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)} million';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)} thousand';
    } else {
      return number.toString();
    }
  }

  /// Format priority for screen readers
  static String formatPriorityForScreenReader(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
      case 'urgent':
        return 'Critical priority';
      case 'high':
        return 'High priority';
      case 'medium':
      case 'normal':
        return 'Normal priority';
      case 'low':
        return 'Low priority';
      default:
        return '$priority priority';
    }
  }

  /// Format status for screen readers
  static String formatStatusForScreenReader(String status) {
    final formatted = status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    return 'Status: $formatted';
  }
}
