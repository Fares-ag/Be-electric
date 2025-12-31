// Tests for the logger service utilities
import 'package:flutter_test/flutter_test.dart';
import 'package:qauto_cmms/services/logger_service.dart';

void main() {
  group('LoggerService Tests', () {
    setUp(() {
      // Reset logger configuration before each test
      LoggerService.configure(
        minimumLogLevel: LogLevel.debug,
        enableTimestamps: true,
        enableStackTraces: true,
      );
    });

    test('Debug log should be created', () {
      // This test verifies the method can be called without errors
      expect(() => LoggerService.debug('Test debug message'), returnsNormally);
    });

    test('Info log should be created', () {
      expect(() => LoggerService.info('Test info message'), returnsNormally);
    });

    test('Warning log should be created', () {
      expect(
        () => LoggerService.warning('Test warning message'),
        returnsNormally,
      );
    });

    test('Error log should be created', () {
      expect(() => LoggerService.error('Test error message'), returnsNormally);
    });

    test('Error log with exception and stack trace', () {
      final exception = Exception('Test exception');
      final stackTrace = StackTrace.current;

      expect(
        () => LoggerService.error(
          'Test error with exception',
          error: exception,
          stackTrace: stackTrace,
        ),
        returnsNormally,
      );
    });

    test('Log with tag should be created', () {
      expect(
        () => LoggerService.info('Test message', tag: 'TestTag'),
        returnsNormally,
      );
    });

    test('Configure logger with custom settings', () {
      expect(
        () => LoggerService.configure(
          minimumLogLevel: LogLevel.warning,
          enableTimestamps: false,
          enableStackTraces: false,
        ),
        returnsNormally,
      );
    });

    test('Log network request', () {
      expect(
        () => LoggerService.logRequest(
          method: 'GET',
          url: 'https://api.example.com/users',
          headers: {'Authorization': 'Bearer token'},
        ),
        returnsNormally,
      );
    });

    test('Log network response', () {
      expect(
        () => LoggerService.logResponse(
          statusCode: 200,
          url: 'https://api.example.com/users',
          body: {'success': true},
          duration: const Duration(milliseconds: 150),
        ),
        returnsNormally,
      );
    });

    test('Log user action', () {
      expect(
        () => LoggerService.logUserAction(
          'button_clicked',
          parameters: {'button_id': 'submit_button'},
        ),
        returnsNormally,
      );
    });

    test('Log performance measurement', () {
      expect(
        () => LoggerService.logPerformance(
          'Data loading',
          const Duration(milliseconds: 500),
        ),
        returnsNormally,
      );
    });

    test('Measure sync operation performance', () {
      final result = LoggerService.measureSync('Test operation', () {
        // Simulate some work
        var sum = 0;
        for (var i = 0; i < 100; i++) {
          sum += i;
        }
        return sum;
      });

      expect(result, 4950); // Sum of 0 to 99
    });

    test('Measure async operation performance', () async {
      final result =
          await LoggerService.measureAsync('Async test operation', () async {
        // Simulate async work
        await Future.delayed(const Duration(milliseconds: 10));
        return 42;
      });

      expect(result, 42);
    });

    test('Measure sync operation with exception', () {
      expect(
        () => LoggerService.measureSync('Failing operation', () {
          throw Exception('Test exception');
        }),
        throwsException,
      );
    });

    test('Measure async operation with exception', () async {
      expect(
        () async =>
            LoggerService.measureAsync('Failing async operation', () async {
          throw Exception('Test async exception');
        }),
        throwsException,
      );
    });

    test('Configure crash reporter', () {
      var crashReported = false;

      LoggerService.configure(
        crashReporter: (error, stackTrace) {
          crashReported = true;
        },
      );

      LoggerService.error(
        'Test error for crash reporting',
        error: Exception('Test'),
      );

      expect(crashReported, true);
    });
  });
}
