// OneSignal push notification service
// Links device to Supabase user ID for targeted pushes (work order assigned, PM due, etc.)

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../config/app_config.dart';

class OneSignalPushService {
  factory OneSignalPushService() => _instance;
  OneSignalPushService._internal();
  static final OneSignalPushService _instance = OneSignalPushService._internal();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize OneSignal. Call early in app lifecycle (e.g. main.dart).
  /// No-op if ONE_SIGNAL_APP_ID is not set.
  Future<void> initialize() async {
    debugPrint('OneSignal: oneSignalAppId="${AppConfig.oneSignalAppId}", enabled=${AppConfig.oneSignalEnabled}');
    if (!AppConfig.oneSignalEnabled) {
      debugPrint('OneSignal: Disabled (no ONE_SIGNAL_APP_ID)');
      return;
    }
    if (_initialized) return;

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      debugPrint('OneSignal: Calling initialize...');
      await OneSignal.initialize(AppConfig.oneSignalAppId);
      debugPrint('OneSignal: SDK initialized, requesting permission...');
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('OneSignal: Foreground notification received: ${event.notification.title}');
        event.notification.display();
      });
      await OneSignal.Notifications.requestPermission(true);
      _initialized = true;
      debugPrint('OneSignal: Fully initialized and permission requested');
    } catch (e, st) {
      debugPrint('OneSignal: Init error $e');
      debugPrint('OneSignal: Stack trace $st');
    }
  }

  /// Link device to Supabase/public.users user ID.
  /// Call after successful login so pushes can target this user.
  Future<void> login(String userId) async {
    if (!_initialized || !AppConfig.oneSignalEnabled) return;
    try {
      await OneSignal.login(userId);
      debugPrint('OneSignal: Logged in as $userId');
    } catch (e) {
      debugPrint('OneSignal: Login error $e');
    }
  }

  /// Unlink device from user. Call on logout.
  Future<void> logout() async {
    if (!_initialized || !AppConfig.oneSignalEnabled) return;
    try {
      await OneSignal.logout();
      debugPrint('OneSignal: Logged out');
    } catch (e) {
      debugPrint('OneSignal: Logout error $e');
    }
  }
}
