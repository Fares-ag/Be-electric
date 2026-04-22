import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance optimizer for batching and debouncing updates
class PerformanceOptimizer {
  PerformanceOptimizer._();
  static final PerformanceOptimizer instance = PerformanceOptimizer._();

  Timer? _debounceTimer;
  Timer? _batchTimer;
  bool _hasPendingUpdate = false;
  final List<VoidCallback> _pendingCallbacks = [];

  /// Debounce a callback - only execute after delay if no more calls
  void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Batch multiple callbacks into a single execution
  void batch(VoidCallback callback, {Duration delay = const Duration(milliseconds: 100)}) {
    if (!_hasPendingUpdate) {
      _hasPendingUpdate = true;
      _batchTimer?.cancel();
      _batchTimer = Timer(delay, () {
        _hasPendingUpdate = false;
        callback();
        // Execute any pending callbacks
        for (final cb in _pendingCallbacks) {
          cb();
        }
        _pendingCallbacks.clear();
      });
    } else {
      _pendingCallbacks.add(callback);
    }
  }

  /// Cancel all pending operations
  void cancel() {
    _debounceTimer?.cancel();
    _batchTimer?.cancel();
    _pendingCallbacks.clear();
    _hasPendingUpdate = false;
  }

  /// Dispose resources
  void dispose() {
    cancel();
  }
}

/// Helper class for debouncing ChangeNotifier updates
///
/// Use a **stable** [batchKey] (e.g. the [ChangeNotifier] instance). Do not pass
/// a new closure identity as the key — each new `() => notify()` would otherwise
/// schedule separate timers and not coalesce stream bursts.
class ChangeNotifierBatcher {
  static final Map<Object, Timer> _batchTimers = {};

  /// Debounce [callback]: rapid calls with the same [batchKey] coalesce to one
  /// [delay] after the last call (timer is reset on each call).
  static void batchNotify(
    VoidCallback callback, {
    required Object batchKey,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    _batchTimers[batchKey]?.cancel();
    _batchTimers[batchKey] = Timer(delay, () {
      _batchTimers.remove(batchKey);
      callback();
    });
  }

  /// Cancel pending debounced [callback] for [batchKey] (e.g. on [dispose]).
  static void cancel(Object batchKey) {
    _batchTimers[batchKey]?.cancel();
    _batchTimers.remove(batchKey);
  }
}

