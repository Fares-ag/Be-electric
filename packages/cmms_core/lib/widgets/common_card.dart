import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A standardized card widget that ensures consistent padding, margins, and styling
/// across the entire application
class CommonCard extends StatelessWidget {

  const CommonCard({
    required this.child, super.key,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.showShadow = true,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) => Card(
      elevation: elevation ?? (showShadow ? 2 : 0),
      color: backgroundColor ?? AppTheme.surfaceColor,
      shadowColor: showShadow ? Colors.black12 : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusL),
      ),
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
        child: child,
      ),
    );
}

/// A standardized section header widget for consistent typography
class SectionHeader extends StatelessWidget {

  const SectionHeader({
    required this.title, super.key,
    this.subtitle,
    this.action,
    this.padding,
  });
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
      padding: padding ??
          const EdgeInsets.only(
            left: AppTheme.spacingM,
            right: AppTheme.spacingM,
            top: AppTheme.spacingM,
            bottom: AppTheme.spacingS,
          ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    subtitle!,
                    style: AppTheme.subtitleStyle,
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
}

/// A standardized info row widget for displaying key-value pairs
class InfoRow extends StatelessWidget {

  const InfoRow({
    required this.label, required this.value, super.key,
    this.trailing,
    this.padding,
  });
  final String label;
  final String value;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
      padding: padding ?? const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textColor,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
}

/// A standardized stat card widget for displaying metrics
class StatCard extends StatelessWidget {

  const StatCard({
    required this.title, required this.value, required this.color, required this.icon, super.key,
    this.subtitle,
  });
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle!,
              style: AppTheme.captionStyle,
            ),
          ],
        ],
      ),
    );
}

/// A standardized form section widget
class FormSection extends StatelessWidget {

  const FormSection({
    required this.title, required this.children, super.key,
    this.padding,
  });
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        ...children,
      ],
    );
}
