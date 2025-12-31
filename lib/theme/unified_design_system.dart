// Unified Design System - Q-AUTO CMMS Branding
// Ensures consistent design across all screens following original branding

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class UnifiedDesignSystem {
  // ============================================================================
  // CORE DESIGN TOKENS
  // ============================================================================

  /// Primary Brand Colors
  static const Color primary = AppTheme.primaryColor;
  static const Color primaryDark = AppTheme.primaryDarkColor;
  static const Color primaryLight = AppTheme.primaryLightColor;
  static const Color surface = AppTheme.surfaceColor;
  static const Color background = AppTheme.backgroundColor;
  static const Color cardBackground = AppTheme.cardBackgroundColor;

  /// Text Colors
  static const Color textPrimary = AppTheme.primaryColor;
  static const Color textSecondary = AppTheme.secondaryTextColor;
  static const Color textDisabled = AppTheme.disabledColor;
  static const Color textDark = AppTheme.darkTextColor;

  /// Border Colors
  static const Color borderColor = AppTheme.borderColor;

  /// Accent Colors (Minimal Use)
  static const Color accentBlue = AppTheme.accentBlue;
  static const Color accentRed = AppTheme.accentRed;
  static const Color accentGreen = AppTheme.accentGreen;
  static const Color accentOrange = AppTheme.accentOrange;

  /// Status Colors (All Grey Shades)
  static const Color statusActive = AppTheme.activeColor;
  static const Color statusInactive = AppTheme.inactiveColor;
  static const Color statusPending = AppTheme.pendingColor;
  static const Color statusCompleted = AppTheme.completedColor;
  static const Color statusCancelled = AppTheme.cancelledColor;

  // ============================================================================
  // TYPOGRAPHY SYSTEM
  // ============================================================================

  /// Heading Styles
  static const TextStyle heading1 = AppTheme.heading1;
  static const TextStyle heading2 = AppTheme.heading2;
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static const TextStyle heading4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Body Text Styles
  static const TextStyle bodyLarge = AppTheme.bodyText;
  static const TextStyle bodyMedium = AppTheme.secondaryText;
  static const TextStyle bodySmall = AppTheme.smallText;

  /// Specialized Text Styles
  static const TextStyle caption = AppTheme.captionText;
  static const TextStyle button = AppTheme.buttonTextStyle;
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  // ============================================================================
  // SPACING SYSTEM
  // ============================================================================

  static const double spaceXS = AppTheme.spacingXS;
  static const double spaceS = AppTheme.spacingS;
  static const double spaceM = AppTheme.spacingM;
  static const double spaceL = AppTheme.spacingL;
  static const double spaceXL = AppTheme.spacingXL;
  static const double spaceXXL = AppTheme.spacingXXL;

  // ============================================================================
  // BORDER RADIUS SYSTEM
  // ============================================================================

  static const double radiusS = AppTheme.radiusS;
  static const double radiusM = AppTheme.radiusM;
  static const double radiusL = AppTheme.radiusL;
  static const double radiusXL = AppTheme.radiusXL;

  // ============================================================================
  // ELEVATION SYSTEM
  // ============================================================================

  static const double elevationS = AppTheme.elevationS;
  static const double elevationM = AppTheme.elevationM;
  static const double elevationL = AppTheme.elevationL;

  // ============================================================================
  // COMPONENT STYLES
  // ============================================================================

  /// Card Styles
  static BoxDecoration get cardDecoration => AppTheme.getCardDecoration();

  static BoxDecoration get cardDecorationElevated => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Button Styles
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: surface,
        padding:
            const EdgeInsets.symmetric(horizontal: spaceXL, vertical: spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        elevation: elevationS,
        textStyle: button,
      );

  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(),
        padding:
            const EdgeInsets.symmetric(horizontal: spaceXL, vertical: spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        textStyle: button,
      );

  static ButtonStyle get accentButton => ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: surface,
        padding:
            const EdgeInsets.symmetric(horizontal: spaceXL, vertical: spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        elevation: elevationS,
        textStyle: button,
      );

  static ButtonStyle get successButton => ElevatedButton.styleFrom(
        backgroundColor: accentGreen,
        foregroundColor: surface,
        padding:
            const EdgeInsets.symmetric(horizontal: spaceXL, vertical: spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        elevation: elevationS,
        textStyle: button,
      );

  static ButtonStyle get warningButton => ElevatedButton.styleFrom(
        backgroundColor: accentOrange,
        foregroundColor: surface,
        padding:
            const EdgeInsets.symmetric(horizontal: spaceXL, vertical: spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        elevation: elevationS,
        textStyle: button,
      );

  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
        backgroundColor: accentRed,
        foregroundColor: surface,
        padding:
            const EdgeInsets.symmetric(horizontal: spaceXL, vertical: spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        elevation: elevationS,
        textStyle: button,
      );

  /// Input Field Styles
  static InputDecoration get inputDecoration => AppTheme.inputDecoration;

  static InputDecoration get searchInputDecoration => InputDecoration(
        hintText: 'Search...',
        prefixIcon: const Icon(Icons.search, color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: accentBlue),
        ),
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: spaceM, vertical: spaceM),
      );

  // ============================================================================
  // STATUS INDICATORS
  // ============================================================================

  /// Status Badge Styles
  static BoxDecoration getStatusBadge(String status) {
    final color = AppTheme.getStatusColor(status);
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(radiusS),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    );
  }

  static TextStyle getStatusText(String status) {
    final color = AppTheme.getStatusColor(status);
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  /// Priority Badge Styles
  static BoxDecoration getPriorityBadge(String priority) {
    final color = AppTheme.getPriorityColor(priority);
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(radiusS),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    );
  }

  static TextStyle getPriorityText(String priority) {
    final color = AppTheme.getPriorityColor(priority);
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  // ============================================================================
  // LAYOUT COMPONENTS
  // ============================================================================

  /// Screen Container
  static Widget screenContainer({
    required Widget child,
    EdgeInsets? padding,
    Color? backgroundColor,
  }) =>
      Container(
        width: double.infinity,
        height: double.infinity,
        color: backgroundColor ?? background,
        padding: padding ?? const EdgeInsets.all(spaceM),
        child: child,
      );

  /// Section Header
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    Widget? action,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: spaceM),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: heading2),
                  if (subtitle != null) ...[
                    const SizedBox(height: spaceXS),
                    Text(subtitle, style: bodyMedium),
                  ],
                ],
              ),
            ),
            if (action != null) action,
          ],
        ),
      );

  /// Info Card
  static Widget infoCard({
    required String title,
    required String value,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) =>
      Card(
        elevation: elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusL),
          child: Padding(
            padding: const EdgeInsets.all(spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: iconColor ?? textSecondary, size: 20),
                      const SizedBox(width: spaceS),
                    ],
                    Expanded(
                      child: Text(title, style: bodyMedium),
                    ),
                  ],
                ),
                const SizedBox(height: spaceS),
                Text(value, style: heading3),
                if (subtitle != null) ...[
                  const SizedBox(height: spaceXS),
                  Text(subtitle, style: caption),
                ],
              ],
            ),
          ),
        ),
      );

  /// Action Card
  static Widget actionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) =>
      Card(
        elevation: elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusL),
          child: Padding(
            padding: const EdgeInsets.all(spaceM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(spaceM),
                  decoration: BoxDecoration(
                    color: (iconColor ?? accentBlue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(radiusM),
                  ),
                  child: Icon(icon, color: iconColor ?? accentBlue, size: 24),
                ),
                const SizedBox(width: spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: heading4),
                      const SizedBox(height: spaceXS),
                      Text(description, style: bodyMedium),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
      );

  /// Empty State
  static Widget emptyState({
    required String title,
    required String description,
    IconData? icon,
    Widget? action,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(spaceXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 64, color: textDisabled),
                const SizedBox(height: spaceM),
              ],
              Text(title, style: heading3, textAlign: TextAlign.center),
              const SizedBox(height: spaceS),
              Text(description, style: bodyMedium, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: spaceL),
                action,
              ],
            ],
          ),
        ),
      );

  /// Loading State
  static Widget loadingState({String? message}) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: accentBlue),
            if (message != null) ...[
              const SizedBox(height: spaceM),
              Text(message, style: bodyMedium),
            ],
          ],
        ),
      );

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get Status Color
  static Color getStatusColor(String status) => AppTheme.getStatusColor(status);

  /// Get Priority Color
  static Color getPriorityColor(String priority) =>
      AppTheme.getPriorityColor(priority);

  /// Get PM Task Status Color
  static Color getPMTaskStatusColor(String status) =>
      AppTheme.getPMTaskStatusColor(status);

  /// Create Status Container
  static BoxDecoration getStatusContainer(Color color) =>
      AppTheme.getStatusContainerDecoration(color);
}
