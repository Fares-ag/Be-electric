// Service Locator Configuration
//
// Centralized dependency injection setup using GetIt.
//
// This file registers all services that need to be injected throughout the app.
// Services are registered as lazy singletons, meaning they are only created
// when first requested.
//
// Usage:
// ```dart
// // Get a service
// final analytics = getIt<AnalyticsService>();
//
// // Or with type inference
// final AnalyticsService analytics = getIt();
// ```

import 'package:get_it/get_it.dart';
import '../services/analytics/analytics_calculator.dart';
import '../services/analytics/analytics_monitor.dart';
import '../services/analytics/analytics_service.dart';

// The global service locator instance
final getIt = GetIt.instance;

// Setup and register all services
//
// This should be called once at app startup, before runApp().
// Services are registered as lazy singletons, so they won't be instantiated
// until first use.
Future<void> setupServiceLocator() async {
  // ==========================================================================
  // CORE DATA SERVICES
  // ==========================================================================

  // Note: Core data services still use singleton pattern for now
  // They will be migrated in a future phase
  // For now, they can be accessed via their existing .instance getters

  // ==========================================================================
  // ANALYTICS SERVICES
  // ==========================================================================

  // Analytics calculator
  getIt.registerLazySingleton<AnalyticsCalculator>(
    AnalyticsCalculator.new,
  );

  // Analytics service (main)
  getIt.registerLazySingleton<AnalyticsService>(
    AnalyticsService.new,
  );

  // Analytics monitor (real-time)
  getIt.registerLazySingleton<AnalyticsMonitor>(
    AnalyticsMonitor.new,
  );

  // ==========================================================================
  // FEATURE SERVICES
  // ==========================================================================

  // Note: Other services still use singleton pattern for now
  // They will be migrated in future phases
  // For now, they can be accessed via their existing patterns

  print('Service Locator: All services registered successfully');
}

// Reset the service locator (useful for testing)
//
// WARNING: This will unregister all services. Only use this in tests!
Future<void> resetServiceLocator() async {
  await getIt.reset();
  print('Service Locator: Reset complete');
}

// Check if a service is registered
//
// Useful for conditional logic or debugging
bool isServiceRegistered<T extends Object>() => getIt.isRegistered<T>();
