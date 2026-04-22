import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/web_admin/web_admin_portal_screen.dart';
// Fallback placeholder for missing login screen on mobile

class WebRouter {
  /// Returns the appropriate home screen based on platform
  static Widget getHomeScreen() {
    if (kIsWeb) {
      // For web browsers, show the web admin portal
      return const WebAdminPortalScreen();
    } else {
      // For mobile/desktop apps, show login
      return const _PlaceholderLoginScreen();
    }
  }

  /// Check if running on web platform
  static bool get isWebPlatform => kIsWeb;

  /// Get appropriate initial route based on platform
  static String getInitialRoute() => kIsWeb ? '/web-admin' : '/login';

  /// Web-specific routes
  static Map<String, WidgetBuilder> getWebRoutes(BuildContext context) => {
        '/web-admin': (context) => const WebAdminPortalScreen(),
        '/login': (context) => const _PlaceholderLoginScreen(),
      };
}

class _PlaceholderLoginScreen extends StatelessWidget {
  const _PlaceholderLoginScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: const Center(
          child: Text('Login screen not implemented. Use Web Admin Portal.'),
        ),
      );
}
