import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/service_locator.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/unified_data_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/requestor/create_maintenance_request_screen.dart';
import 'screens/requestor/requestor_splash_screen.dart';
import 'screens/analytics/consolidated_analytics_dashboard.dart';
import 'services/analytics/analytics_service.dart';
import 'services/comprehensive_cmms_service.dart';
import 'services/error_handling_service.dart';
import 'services/escalation_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/supabase_database_service.dart';
import 'services/notification_service.dart';
import 'services/parts_request_service.dart';
import 'services/purchase_order_service.dart';
import 'services/realtime_supabase_service.dart';
import 'services/unified_data_service.dart';
import 'utils/app_theme.dart';
import 'widgets/role_based_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection (GetIt)
  try {
    await setupServiceLocator();
    debugPrint('✅ Service Locator: Dependency injection configured');
  } catch (e) {
    debugPrint('❌ Service Locator error: $e');
    // Continue even if service locator fails
  }

  // Initialize Supabase with error handling
  try {
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('✅ Supabase: Initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Supabase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue without Supabase if initialization fails - app should still work
  }

  // Initialize services with individual error handling to prevent crashes
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
    await NotificationService().initialize();
    await EscalationService().initialize();
    await PartsRequestService().initialize();
    await PurchaseOrderService().initialize();
    await getIt<AnalyticsService>().initialize();
    debugPrint('✅ Additional services: Initialized successfully');
  } catch (e) {
    debugPrint('❌ Additional services initialization error: $e');
  }

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');

    // Log error for debugging (with error handling to prevent crashes)
    try {
      ErrorHandlingService.logError(details.exception, details.stack);
    } catch (e) {
      debugPrint('Error logging failed: $e');
    }
  };

  // Handle platform errors to prevent app crashes
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true; // Prevent app from crashing
  };

  runApp(const BeElectricApp());
}

class BeElectricApp extends StatelessWidget {
  const BeElectricApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => UnifiedDataProvider()),
          ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ],
        child: MaterialApp(
          title: 'Be Electric',
          theme: AppTheme.lightTheme,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/create_maintenance_request': (context) {
              final args = ModalRoute.of(context)!.settings.arguments!
                  as Map<String, dynamic>;
              return CreateMaintenanceRequestScreen(
                asset: args['asset'],
                qrCode: args['qrCode'],
              );
            },
            '/analytics_dashboard': (context) =>
                const ConsolidatedAnalyticsDashboard(),
          },
        ),
      );
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;
  bool _splashCompleted = false;
  bool _listenerAdded = false;

  @override
  void initState() {
    super.initState();
    // Show splash screen first, then check auth status
    _startSplashSequence();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Add listener only once after dependencies are available
    if (!_listenerAdded) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.addListener(_onAuthChanged);
        _listenerAdded = true;
        debugPrint('🔧 AuthWrapper: Listener added to AuthProvider');
      } catch (e) {
        debugPrint('⚠️ AuthWrapper: Error adding listener: $e');
      }
    }
  }

  void _onAuthChanged() {
    if (mounted) {
      debugPrint('🔔 AuthWrapper: Auth state changed listener triggered - forcing rebuild');
      setState(() {
        // Force rebuild
      });
    }
  }

  @override
  void dispose() {
    if (_listenerAdded) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.removeListener(_onAuthChanged);
        debugPrint('🔧 AuthWrapper: Listener removed from AuthProvider');
      } catch (e) {
        debugPrint('⚠️ AuthWrapper: Error removing listener: $e');
      }
    }
    super.dispose();
  }

  void _startSplashSequence() {
    // After splash completes (3 seconds), check auth status
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
          _splashCompleted = true;
        });
        _checkAuthStatus();
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      // No local DB initialization needed - Supabase is the only database
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkAuthStatus();
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      // Continue with app even if auth check fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen first
    if (_showSplash) {
      return const RequestorSplashScreen();
    }

    // After splash, show login or main screen based on auth status
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        debugPrint(
          '🔄 AuthWrapper REBUILD: isAuthenticated=${authProvider.isAuthenticated}, '
          'isLoading=${authProvider.isLoading}, '
          'currentUser=${authProvider.currentUser?.name}, '
          'splashCompleted=$_splashCompleted',
        );

        if (!_splashCompleted || authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          debugPrint(
            '✅ AuthWrapper: Navigating to RoleBasedNavigation for user: ${authProvider.currentUser!.name}',
          );
          return RoleBasedNavigation(key: ValueKey(authProvider.currentUser!.id));
        }

        debugPrint('⚠️ AuthWrapper: Showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}
