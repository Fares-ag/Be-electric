import 'package:flutter/material.dart';

class AppTheme {
  // Color Scheme - Be Electric Design System
  static const Color primaryColor = Colors.black;
  static const Color primaryDarkColor = Colors.black;
  static const Color primaryLightColor = Color(0xFF757575); // Colors.grey[600]
  static const Color backgroundColor = Color(0xFFF5F5F5); // Colors.grey[50]
  static const Color surfaceColor = Colors.white;
  static const Color cardBackgroundColor =
      Color(0xFFEEEEEE); // Colors.grey[100]
  static const Color borderColor = Color(0xFFE0E0E0); // Colors.grey[200]
  static const Color disabledColor = Color(0xFFBDBDBD); // Colors.grey[300]
  static const Color secondaryTextColor = Color(0xFF757575); // Colors.grey[600]
  static const Color darkTextColor = Color(0xFF424242); // Colors.grey[800]

  // Accent Colors (Minimal Use)
  static const Color accentBlue = Color(0xFF1976D2); // Colors.blue[600]
  static const Color accentRed = Color(0xFFD32F2F); // Colors.red[600]
  static const Color accentGreen = Color(0xFF002911); // Main brand green
  static const Color accentOrange = Color(0xFFF57C00); // Colors.orange[600]

  // Status Colors - All grey shades
  static const Color activeColor = Color(0xFFF5F5F5); // Colors.grey[100]
  static const Color inactiveColor = Color(0xFFEEEEEE); // Colors.grey[200]
  static const Color writtenOffColor = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color pendingColor = Color(0xFFBDBDBD); // Colors.grey[400]
  static const Color completedColor = Color(0xFF9E9E9E); // Colors.grey[500]
  static const Color cancelledColor = Color(0xFF757575); // Colors.grey[600]

  // Priority Colors - Grey shades only
  static const Color lowPriorityColor = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color mediumPriorityColor =
      Color(0xFFBDBDBD); // Colors.grey[400]
  static const Color highPriorityColor = Color(0xFF9E9E9E); // Colors.grey[500]
  static const Color criticalPriorityColor =
      Color(0xFF757575); // Colors.grey[600]

  // Additional colors for analytics and notifications
  static const Color textColor = Colors.black87;
  static const Color cardColor = Colors.white;
  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFF44336);
  static const Color orange = Color(0xFFFF9800);
  static const Color blue = Color(0xFF2196F3);
  static const Color purple = Color(0xFF9C27B0);
  static const Color darkGrey = Color(0xFF424242);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color nearlyWhite = Color(0xFFFAFAFA);
  static const Color accentColor = Color(0xFF607D8B);

  // Input Decoration
  static const InputDecoration inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: accentBlue),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    filled: true,
    fillColor: surfaceColor,
  );

  // Button Styles
  static const ButtonStyle elevatedButtonStyle = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(accentBlue),
    foregroundColor: WidgetStatePropertyAll(Colors.white),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );

  static const ButtonStyle outlinedButtonStyle = ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(accentBlue),
    side: WidgetStatePropertyAll(BorderSide(color: accentBlue)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );
  static const Color white = Colors.white;

  // Legacy color constants for backward compatibility
  static const Color errorColor = accentRed;
  static const Color successColor = accentGreen;
  static const Color warningColor = accentOrange;
  static const Color infoColor = accentBlue;

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Suisse Int\'l',
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentBlue,
          primary: darkTextColor,
          secondary: secondaryTextColor,
          surface: surfaceColor,
          background: backgroundColor,
          error: accentRed,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceColor,
          foregroundColor: primaryColor,
          elevation: 1,
          centerTitle: true,
          shadowColor: Colors.black12,
          titleTextStyle: TextStyle(
            fontFamily: 'Suisse Int\'l',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkTextColor,
            foregroundColor: surfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            minimumSize: const Size(120, 44),
            textStyle: const TextStyle(
              fontFamily: 'Suisse Int\'l',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkTextColor,
            side: const BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: const Size(120, 44),
            textStyle: const TextStyle(
              fontFamily: 'Suisse Int\'l',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontFamily: 'Suisse Int\'l',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: surfaceColor,
          shadowColor: Colors.black12,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: secondaryTextColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentRed),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: backgroundColor,
          labelStyle: const TextStyle(
            fontFamily: 'Suisse Int\'l',
            color: secondaryTextColor,
          ),
          hintStyle: const TextStyle(
            fontFamily: 'Suisse Int\'l',
            color: disabledColor,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: surfaceColor,
          elevation: 2,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surfaceColor,
          selectedItemColor: darkTextColor,
          unselectedItemColor: disabledColor,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0),
          thickness: 1,
          space: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Suisse Int\'l'),
          displayMedium: TextStyle(fontFamily: 'Suisse Int\'l'),
          displaySmall: TextStyle(fontFamily: 'Suisse Int\'l'),
          headlineLarge: TextStyle(fontFamily: 'Suisse Int\'l'),
          headlineMedium: TextStyle(fontFamily: 'Suisse Int\'l'),
          headlineSmall: TextStyle(fontFamily: 'Suisse Int\'l'),
          titleLarge: TextStyle(fontFamily: 'Suisse Int\'l'),
          titleMedium: TextStyle(fontFamily: 'Suisse Int\'l'),
          titleSmall: TextStyle(fontFamily: 'Suisse Int\'l'),
          bodyLarge: TextStyle(fontFamily: 'Suisse Int\'l'),
          bodyMedium: TextStyle(fontFamily: 'Suisse Int\'l'),
          bodySmall: TextStyle(fontFamily: 'Suisse Int\'l'),
          labelLarge: TextStyle(fontFamily: 'Suisse Int\'l'),
          labelMedium: TextStyle(fontFamily: 'Suisse Int\'l'),
          labelSmall: TextStyle(fontFamily: 'Suisse Int\'l'),
        ),
      );

  // Typography styles - Be Electric Design System
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Suisse Int\'l',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Suisse Int\'l',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: 'Suisse Int\'l',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: darkTextColor,
  );

  static const TextStyle secondaryText = TextStyle(
    fontFamily: 'Suisse Int\'l',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryTextColor,
  );

  static const TextStyle smallText = TextStyle(
    fontFamily: 'Suisse Int\'l',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: secondaryTextColor,
  );

  // Additional text styles
  static const TextStyle headline4 = TextStyle(
    fontFamily: 'Suisse Int\'l',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle headline6 = TextStyle(
    fontFamily: 'Suisse Int\'l',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle captionText = TextStyle(
    fontFamily: 'Suisse Int\'l',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: secondaryTextColor,
  );

  // Legacy styles for backward compatibility
  static const TextStyle titleStyle = heading1;
  static const TextStyle subtitleStyle = secondaryText;
  static const TextStyle bodyStyle = bodyText;
  static const TextStyle buttonTextStyle = TextStyle(
    fontFamily: 'Suisse Int\'l',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle captionStyle = smallText;

  // Status color getters - all return grey shades
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return pendingColor;
      case 'assigned':
        return mediumPriorityColor;
      case 'inprogress':
      case 'in_progress':
        return highPriorityColor;
      case 'completed':
        return completedColor;
      case 'closed':
        return cancelledColor;
      case 'cancelled':
        return cancelledColor;
      case 'active':
        return activeColor;
      case 'inactive':
        return inactiveColor;
      case 'written_off':
        return writtenOffColor;
      default:
        return const Color(0xFFBDBDBD); // Colors.grey[400]
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return lowPriorityColor;
      case 'medium':
        return mediumPriorityColor;
      case 'high':
        return highPriorityColor;
      case 'urgent':
        return const Color(0xFFFF7043); // Deep orange for urgent cases
      case 'critical':
        return criticalPriorityColor;
      default:
        return mediumPriorityColor;
    }
  }

  static Color getPMTaskStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pendingColor;
      case 'inprogress':
      case 'in_progress':
        return highPriorityColor;
      case 'completed':
        return completedColor;
      case 'overdue':
        return criticalPriorityColor;
      case 'cancelled':
        return cancelledColor;
      default:
        return const Color(0xFFBDBDBD); // Colors.grey[400]
    }
  }

  // Container decorations
  static BoxDecoration getCardDecoration() => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration getStatusContainerDecoration(Color color) =>
      BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      );

  // Spacing constants
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 20;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;

  // Border radius constants
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;

  // Elevation constants
  static const double elevationS = 2;
  static const double elevationM = 4;
  static const double elevationL = 8;
}
