import 'package:flutter/material.dart';

class AppTheme {
  // Color System
  static const Color primaryBlack = Colors.black;
  static const Color primaryWhite = Colors.white;
  static const Color lightGrey = Color(0xFFF5F5F5); // Colors.grey[50]
  static const Color cardGrey = Color(0xFFEEEEEE); // Colors.grey[100]
  static const Color borderGrey = Color(0xFFE0E0E0); // Colors.grey[200]
  static const Color disabledGrey = Color(0xFFBDBDBD); // Colors.grey[300]
  static const Color secondaryTextGrey = Color(0xFF757575); // Colors.grey[600]
  static const Color darkTextGrey = Color(0xFF424242); // Colors.grey[800]

  // Accent Colors (Minimal Use)
  static const Color accentBlue = Color(0xFF1976D2); // Colors.blue[600]
  static const Color accentRed = Color(0xFFD32F2F); // Colors.red[600]
  static const Color accentGreen = Color(0xFF388E3C); // Colors.green[600]
  static const Color accentOrange = Color(0xFFF57C00); // Colors.orange[600]
  static const Color accentPurple = Color(0xFF7B1FA2); // Colors.purple[600]

  // Typography
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryBlack,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryBlack,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: darkTextGrey,
  );

  static const TextStyle secondaryText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryTextGrey,
  );

  static const TextStyle smallText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: secondaryTextGrey,
  );

  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;

  // Border Radius
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;

  // Elevation
  static const double elevationS = 2;
  static const double elevationM = 4;
  static const double elevationL = 8;

  // Component Styles
  // Using inline CardTheme in ThemeData (no getter) to avoid type mismatches across SDKs

  static ElevatedButtonThemeData get elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkTextGrey,
          foregroundColor: primaryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingS,
          ),
          minimumSize: const Size(120, 44),
        ),
      );

  static OutlinedButtonThemeData get outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextGrey,
          side: const BorderSide(color: borderGrey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingS,
          ),
        ),
      );

  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: secondaryTextGrey),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
        filled: true,
        fillColor: lightGrey,
      );

  static AppBarTheme get appBarTheme => const AppBarTheme(
        backgroundColor: primaryWhite,
        foregroundColor: primaryBlack,
        elevation: elevationS,
        centerTitle: true,
        titleTextStyle: heading2,
      );

  static BottomNavigationBarThemeData get bottomNavigationBarTheme =>
      const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: darkTextGrey,
        unselectedItemColor: disabledGrey,
        backgroundColor: primaryWhite,
        elevation: elevationL,
      );

  // Main Theme
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentBlue,
          primary: darkTextGrey,
          secondary: secondaryTextGrey,
          surface: primaryWhite,
          background: lightGrey,
        ),
        cardTheme: const CardThemeData(
          elevation: elevationS,
          color: primaryWhite,
        ),
        elevatedButtonTheme: elevatedButtonTheme,
        outlinedButtonTheme: outlinedButtonTheme,
        inputDecorationTheme: inputDecorationTheme,
        appBarTheme: appBarTheme,
        bottomNavigationBarTheme: bottomNavigationBarTheme,
        scaffoldBackgroundColor: lightGrey,
        fontFamily: 'Roboto',
      );
}

// Responsive Layout Helper
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    required this.tablet,
    required this.desktop,
    super.key,
  });
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 768) {
            return mobile;
          } else if (constraints.maxWidth < 1024) {
            return tablet;
          } else {
            return desktop;
          }
        },
      );
}

// Responsive Grid Helper
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    super.key,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
  });
  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;
          if (constraints.maxWidth < 768) {
            crossAxisCount = 2; // Mobile
          } else if (constraints.maxWidth < 1024) {
            crossAxisCount = 3; // Tablet
          } else {
            crossAxisCount = 4; // Desktop
          }

          return GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            children: children,
          );
        },
      );
}

// Standard Card Component
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
            child: child,
          ),
        ),
      );
}

// Standard Button Components
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.text,
    super.key,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: AppTheme.spacingS),
                  ],
                  Text(text),
                ],
              ),
      );
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.text,
    super.key,
    this.onPressed,
    this.icon,
  });
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: AppTheme.spacingS),
            ],
            Text(text),
          ],
        ),
      );
}
