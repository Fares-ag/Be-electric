// Performance Monitoring Utilities
//
// Provides tools for measuring and monitoring app performance.
// Helps identify bottlenecks and optimize slow operations.
//
// Usage:
// ```dart
// // Monitor a specific operation
// await PerformanceMonitor.measure('loadWorkOrders', () async {
//   await loadWorkOrders();
// });
//
// // Get performance report
// final report = PerformanceMonitor.getReport();
// debugPrint(report);
// ```

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:qauto_cmms/services/logger_service.dart';

/// Performance metric for a specific operation
class PerformanceMetric {
  PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  /// Convert to map for logging/export
  Map<String, dynamic> toMap() => {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'timestamp': timestamp.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

  /// Check if this metric exceeds a threshold
  bool isSlowOperation(Duration threshold) => duration > threshold;

  @override
  String toString() => '$operation: ${duration.inMilliseconds}ms';
}

/// Performance statistics for an operation
class PerformanceStats {
  PerformanceStats({
    required this.operation,
    required this.count,
    required this.totalDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.avgDuration,
    required this.recentDurations,
  });
  final String operation;
  final int count;
  final Duration totalDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final Duration avgDuration;
  final List<Duration> recentDurations;

  /// Convert to map for logging/export
  Map<String, dynamic> toMap() => {
        'operation': operation,
        'count': count,
        'total_ms': totalDuration.inMilliseconds,
        'min_ms': minDuration.inMilliseconds,
        'max_ms': maxDuration.inMilliseconds,
        'avg_ms': avgDuration.inMilliseconds,
        'recent_ms': recentDurations.map((d) => d.inMilliseconds).toList(),
      };

  @override
  String toString() => '$operation: avg=${avgDuration.inMilliseconds}ms, '
      'min=${minDuration.inMilliseconds}ms, '
      'max=${maxDuration.inMilliseconds}ms, '
      'count=$count';
}

/// Central performance monitoring service
class PerformanceMonitor {
  PerformanceMonitor._();

  /// Store all performance metrics
  static final List<PerformanceMetric> _metrics = [];

  /// Maximum metrics to keep in memory
  static const int _maxMetrics = 1000;

  /// Slow operation threshold (default: 500ms)
  static Duration slowOperationThreshold = const Duration(milliseconds: 500);

  /// Enable/disable performance monitoring
  static bool enabled = kDebugMode; // Only enabled in debug by default

  /// Measure the performance of a synchronous operation
  static T measure<T>(
    String operation,
    T Function() fn, {
    Map<String, dynamic>? metadata,
  }) {
    if (!enabled) return fn();

    final stopwatch = Stopwatch()..start();
    try {
      return fn();
    } finally {
      stopwatch.stop();
      _recordMetric(operation, stopwatch.elapsed, metadata);
    }
  }

  /// Measure the performance of an asynchronous operation
  static Future<T> measureAsync<T>(
    String operation,
    Future<T> Function() fn, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!enabled) return fn();

    final stopwatch = Stopwatch()..start();
    try {
      return await fn();
    } finally {
      stopwatch.stop();
      _recordMetric(operation, stopwatch.elapsed, metadata);
    }
  }

  /// Start timing an operation (for manual timing)
  static Stopwatch start() => Stopwatch()..start();

  /// End timing and record metric
  static void end(
    Stopwatch stopwatch,
    String operation, {
    Map<String, dynamic>? metadata,
  }) {
    if (!enabled) return;

    stopwatch.stop();
    _recordMetric(operation, stopwatch.elapsed, metadata);
  }

  /// Record a metric
  static void _recordMetric(
    String operation,
    Duration duration,
    Map<String, dynamic>? metadata,
  ) {
    final metric = PerformanceMetric(
      operation: operation,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _metrics.add(metric);

    // Keep only the most recent metrics
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }

    // Log slow operations
    if (metric.isSlowOperation(slowOperationThreshold)) {
      LoggerService.warning(
        'Slow operation detected: $operation took ${duration.inMilliseconds}ms',
        tag: 'Performance',
      );
    }
  }

  /// Get all metrics
  static List<PerformanceMetric> getMetrics() => List.unmodifiable(_metrics);

  /// Get metrics for a specific operation
  static List<PerformanceMetric> getMetricsForOperation(String operation) =>
      _metrics.where((m) => m.operation == operation).toList();

  /// Get performance statistics for an operation
  static PerformanceStats? getStatsForOperation(String operation) {
    final metrics = getMetricsForOperation(operation);
    if (metrics.isEmpty) return null;

    final durations = metrics.map((m) => m.duration).toList();
    final totalDuration = durations.fold<Duration>(
      Duration.zero,
      (sum, d) => sum + d,
    );

    return PerformanceStats(
      operation: operation,
      count: metrics.length,
      totalDuration: totalDuration,
      minDuration: durations.reduce((a, b) => a < b ? a : b),
      maxDuration: durations.reduce((a, b) => a > b ? a : b),
      avgDuration: Duration(
        microseconds: totalDuration.inMicroseconds ~/ metrics.length,
      ),
      recentDurations: durations.take(10).toList(),
    );
  }

  /// Get all operation names
  static List<String> getOperations() =>
      _metrics.map((m) => m.operation).toSet().toList()..sort();

  /// Get statistics for all operations
  static Map<String, PerformanceStats> getAllStats() {
    final operations = getOperations();
    final stats = <String, PerformanceStats>{};

    for (final operation in operations) {
      final opStats = getStatsForOperation(operation);
      if (opStats != null) {
        stats[operation] = opStats;
      }
    }

    return stats;
  }

  /// Get slow operations
  static List<PerformanceMetric> getSlowOperations([Duration? threshold]) {
    final thresh = threshold ?? slowOperationThreshold;
    return _metrics.where((m) => m.isSlowOperation(thresh)).toList();
  }

  /// Get performance report as string
  static String getReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== PERFORMANCE REPORT ===');
    buffer.writeln('Total operations tracked: ${_metrics.length}');
    buffer.writeln('Unique operations: ${getOperations().length}');
    buffer.writeln(
      'Slow operations (>${slowOperationThreshold.inMilliseconds}ms): ${getSlowOperations().length}',
    );
    buffer.writeln('\n=== OPERATION STATISTICS ===');

    final stats = getAllStats();
    final sortedOps = stats.entries.toList()
      ..sort((a, b) => b.value.avgDuration.compareTo(a.value.avgDuration));

    for (final entry in sortedOps) {
      buffer.writeln(entry.value);
    }

    return buffer.toString();
  }

  /// Export metrics as JSON-compatible map
  static Map<String, dynamic> exportMetrics() => {
        'timestamp': DateTime.now().toIso8601String(),
        'total_metrics': _metrics.length,
        'operations': getOperations(),
        'slow_operations_count': getSlowOperations().length,
        'statistics':
            getAllStats().map((key, value) => MapEntry(key, value.toMap())),
        'recent_metrics': _metrics.take(50).map((m) => m.toMap()).toList(),
      };

  /// Clear all metrics
  static void clear() {
    _metrics.clear();
    LoggerService.debug('Performance metrics cleared', tag: 'Performance');
  }

  /// Reset specific operation metrics
  static void clearOperation(String operation) {
    _metrics.removeWhere((m) => m.operation == operation);
    LoggerService.debug('Cleared metrics for: $operation', tag: 'Performance');
  }

  /// Print report to console
  static void printReport() {
    if (kDebugMode) {
      debugPrint(getReport());
    }
  }
}

/// Widget performance tracker
class WidgetPerformanceTracker {
  WidgetPerformanceTracker(this.widgetName);
  final String widgetName;
  final Stopwatch _buildStopwatch = Stopwatch();
  int _buildCount = 0;

  /// Start tracking a build
  void startBuild() {
    _buildStopwatch.start();
  }

  /// End tracking a build
  void endBuild() {
    _buildStopwatch.stop();
    _buildCount++;

    PerformanceMonitor._recordMetric(
      'widget_build:$widgetName',
      _buildStopwatch.elapsed,
      {'build_count': _buildCount},
    );

    _buildStopwatch.reset();
  }

  /// Get build count
  int get buildCount => _buildCount;
}

/// Memory usage tracker
class MemoryTracker {
  MemoryTracker._();

  /// Track memory snapshot
  static void snapshot(String label) {
    if (!kDebugMode) return;

    LoggerService.debug(
      'Memory snapshot: $label',
      tag: 'Memory',
    );
  }

  /// Log memory warning
  static void warning(String message) {
    LoggerService.warning(
      'Memory warning: $message',
      tag: 'Memory',
    );
  }
}

/// Frame rate monitor
class FrameRateMonitor {
  FrameRateMonitor._();

  static final List<Duration> _frameTimes = [];
  static const int _maxFrames = 120; // 2 seconds at 60 FPS

  /// Record a frame time
  static void recordFrame(Duration duration) {
    _frameTimes.add(duration);

    if (_frameTimes.length > _maxFrames) {
      _frameTimes.removeAt(0);
    }

    // Warn on dropped frames (>16.67ms = <60fps)
    if (duration.inMilliseconds > 16) {
      LoggerService.warning(
        'Frame dropped: ${duration.inMilliseconds}ms',
        tag: 'FrameRate',
      );
    }
  }

  /// Get average frame time
  static Duration getAverageFameTime() {
    if (_frameTimes.isEmpty) return Duration.zero;

    final total = _frameTimes.fold<Duration>(
      Duration.zero,
      (sum, d) => sum + d,
    );

    return Duration(microseconds: total.inMicroseconds ~/ _frameTimes.length);
  }

  /// Get estimated FPS
  static double getEstimatedFPS() {
    final avgFrameTime = getAverageFameTime();
    if (avgFrameTime.inMicroseconds == 0) return 0;

    return 1000000 / avgFrameTime.inMicroseconds;
  }

  /// Clear frame times
  static void clear() {
    _frameTimes.clear();
  }
}
