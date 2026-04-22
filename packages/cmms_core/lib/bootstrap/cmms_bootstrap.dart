import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/service_locator.dart';
import '../config/supabase_config.dart';
import '../services/analytics/analytics_service.dart';
import '../services/comprehensive_cmms_service.dart';
import '../services/error_handling_service.dart';
import '../services/escalation_service.dart';
import '../services/notification_service.dart';
import '../services/onesignal_push_service.dart';
import '../services/parts_request_service.dart';
import '../services/purchase_order_service.dart';
import '../services/realtime_supabase_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_database_service.dart';
import '../services/unified_data_service.dart';

/// Shared startup for requestor and technician app binaries.
Future<void> initializeCmms() async {
  try {
    await setupServiceLocator();
    debugPrint('✅ Service Locator: Dependency injection configured');
  } catch (e) {
    debugPrint('❌ Service Locator error: $e');
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('✅ Supabase: Initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Supabase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  try {
    await UnifiedDataService.instance.initialize();
    debugPrint('✅ UnifiedDataService: Initialized successfully');
  } catch (e) {
    debugPrint('❌ UnifiedDataService initialization error: $e');
  }

  try {
    await ComprehensiveCMMSService().initialize();
    debugPrint('✅ ComprehensiveCMMSService: Initialized successfully');
  } catch (e) {
    debugPrint('❌ ComprehensiveCMMSService initialization error: $e');
  }

  try {
    await SupabaseAuthService.instance.initialize();
    await SupabaseDatabaseService.instance.initialize();
    await RealtimeSupabaseService.instance.initialize();
    debugPrint('✅ Supabase services: Initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase services initialization error: $e');
  }

  try {
    await OneSignalPushService().initialize();
    await NotificationService().initialize();
    await EscalationService().initialize();
    await PartsRequestService().initialize();
    await PurchaseOrderService().initialize();
    await getIt<AnalyticsService>().initialize();
    debugPrint('✅ Additional services: Initialized successfully');
  } catch (e) {
    debugPrint('❌ Additional services initialization error: $e');
  }

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
