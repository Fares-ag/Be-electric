import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/service_locator.dart';
import '../config/supabase_config.dart';
import '../services/analytics/analytics_service.dart';
import '../services/comprehensive_cmms_service.dart';
import '../services/error_handling_service.dart';
import '../services/escalation_service.dart';
import '../services/notification_service.dart';
import '../services/parts_request_service.dart';
import '../services/purchase_order_service.dart';
import '../services/realtime_supabase_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_database_service.dart';

/// Shared startup for requestor and technician app binaries.
Future<void> initializeCmms() async {
  try {
    await setupServiceLocator();
    debugPrint('✅ Service Locator: Dependency injection configured');
  } catch (e) {
    debugPrint('❌ Service Locator error: $e');
  }

  try {
    if (!AppConfig.hasValidSupabaseConfig) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
        'Pass both via --dart-define for release builds.',
      );
    }
    if (kReleaseMode && !AppConfig.hasValidLegalConfig) {
      debugPrint(
        '⚠️ Release build: set PRIVACY_POLICY_URL, SUPPORT_URL, and '
        'SUPPORT_EMAIL via --dart-define for App Store compliance.',
      );
    }
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('✅ Supabase: Initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Supabase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // Light Supabase plumbing first so the auth listener inside
  // UnifiedDataProvider has somewhere to attach. We deliberately do NOT call
  // UnifiedDataService.initialize() / ComprehensiveCMMSService.initialize()
  // here anymore: they used to fire ~12 RLS-rejected fetches before the user
  // had a session. They now run automatically once Supabase emits signedIn.
  try {
    await SupabaseAuthService.instance.initialize();
    await SupabaseDatabaseService.instance.initialize();
    await RealtimeSupabaseService.instance.initialize();
    debugPrint('✅ Supabase services: Initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase services initialization error: $e');
  }

  // Fire-and-forget the heavier domain services so they don't block first
  // frame. They each manage their own internal initialization guards.
  unawaited(_initializeDeferredServices());

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    try {
      ErrorHandlingService.logError(details.exception, details.stack);
    } catch (e) {
      debugPrint('Error logging failed: $e');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };
}

/// Deferred initializers that don't need to block the first frame. They are
/// safe to retry after sign-in because each underlying service is idempotent.
Future<void> _initializeDeferredServices() async {
  try {
    await ComprehensiveCMMSService().initialize();
  } catch (e) {
    debugPrint('❌ ComprehensiveCMMSService initialization error: $e');
  }

  try {
    await NotificationService().initialize();
    await EscalationService().initialize();
    await PartsRequestService().initialize();
    await PurchaseOrderService().initialize();
    await getIt<AnalyticsService>().initialize();
    debugPrint('✅ Additional services: Initialized successfully');
  } catch (e) {
    debugPrint('❌ Additional services initialization error: $e');
  }
}
