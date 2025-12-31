import 'package:flutter/foundation.dart';

class ErrorHandlingService {
  ErrorHandlingService._();

  static void logError(dynamic exception, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('Error: $exception');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }

    // In production, you might want to send this to a crash reporting service
    // like Firebase Crashlytics, Sentry, etc.
  }

  static void logInfo(String message) {
    if (kDebugMode) {
      print('Info: $message');
    }
  }

  static void logWarning(String message) {
    if (kDebugMode) {
      print('Warning: $message');
    }
  }
}
