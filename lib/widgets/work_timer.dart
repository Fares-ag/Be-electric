import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A timer widget that displays elapsed time since work started
class WorkTimer extends StatefulWidget {
  const WorkTimer({
    required this.startTime,
    super.key,
    this.isActive = true,
    this.onTimerUpdate,
    this.pauseHistory,
    this.pausedAt,
  });
  final DateTime startTime;
  final bool isActive;
  final VoidCallback? onTimerUpdate;
  final List<Map<String, dynamic>>? pauseHistory;
  final DateTime? pausedAt;

  @override
  State<WorkTimer> createState() => _WorkTimerState();
}

class _WorkTimerState extends State<WorkTimer> {
  late Duration _elapsedTime;
  late Duration _baseDuration;
  late Duration _totalPausedDuration;
  Timer? _timer;
  DateTime? _activeStartTime;

  Duration _calculateTotalPausedDuration() {
    Duration total = Duration.zero;
    
    // Calculate from pause history
    if (widget.pauseHistory != null) {
      for (final entry in widget.pauseHistory!) {
        final pausedAtStr = entry['pausedAt'] as String?;
        final resumedAtStr = entry['resumedAt'] as String?;
        
        if (pausedAtStr != null && resumedAtStr != null) {
          final pausedAt = DateTime.tryParse(pausedAtStr);
          final resumedAt = DateTime.tryParse(resumedAtStr);
          if (pausedAt != null && resumedAt != null) {
            total += resumedAt.difference(pausedAt);
          }
        }
      }
    }
    
    // If currently paused, add time from pausedAt to now
    if (!widget.isActive && widget.pausedAt != null) {
      total += DateTime.now().difference(widget.pausedAt!);
    }
    
    return total;
  }

  @override
  void initState() {
    super.initState();
    _totalPausedDuration = _calculateTotalPausedDuration();
    final rawElapsed = DateTime.now().difference(widget.startTime);
    _baseDuration = rawElapsed - _totalPausedDuration;
    // Ensure base duration is not negative
    if (_baseDuration.isNegative) {
      _baseDuration = Duration.zero;
    }
    _elapsedTime = _baseDuration;
    if (widget.isActive) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(WorkTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recalculate paused duration if pause history or pause state changed
    final pauseChanged = widget.pauseHistory != oldWidget.pauseHistory ||
        widget.pausedAt != oldWidget.pausedAt ||
        widget.isActive != oldWidget.isActive;
    
    if (widget.isActive && !oldWidget.isActive) {
      // Resuming - preserve current elapsed time, don't recalculate from startTime
      // The _baseDuration should already be set from when we paused
      if (_activeStartTime == null) {
        // Timer was stopped, preserve current _baseDuration
        // Don't recalculate - just use what we have
        _elapsedTime = _baseDuration;
      }
      _startTimer();
    } else if (!widget.isActive && oldWidget.isActive) {
      // Pausing - stop timer and freeze elapsed time
      _stopTimer();
      // Update base duration to current elapsed time
      _baseDuration = _elapsedTime;
    } else if (pauseChanged || widget.startTime != oldWidget.startTime) {
      // Pause history changed or start time changed - recalculate
      _totalPausedDuration = _calculateTotalPausedDuration();
      final rawElapsed = DateTime.now().difference(widget.startTime);
      _baseDuration = rawElapsed - _totalPausedDuration;
      // Ensure base duration is not negative
      if (_baseDuration.isNegative) {
        _baseDuration = Duration.zero;
      }
      _elapsedTime = _baseDuration;
      
      if (widget.isActive) {
        _startTimer();
      } else {
        _stopTimer();
      }
    } else if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        // Resuming - preserve current base duration
        _startTimer();
      } else {
        // Pausing - stop and update base duration
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _activeStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _activeStartTime != null) {
        setState(() {
          _elapsedTime =
              _baseDuration + DateTime.now().difference(_activeStartTime!);
        });
        widget.onTimerUpdate?.call();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (_activeStartTime != null) {
      _baseDuration = _elapsedTime;
      _activeStartTime = null;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              'Elapsed: ${_formatDuration(_elapsedTime)}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (widget.isActive) ...[
              const SizedBox(width: AppTheme.spacingS),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      );
}

/// A compact timer widget for use in cards or lists
class CompactWorkTimer extends StatefulWidget {
  const CompactWorkTimer({
    required this.startTime,
    super.key,
    this.isActive = true,
  });
  final DateTime startTime;
  final bool isActive;

  @override
  State<CompactWorkTimer> createState() => _CompactWorkTimerState();
}

class _CompactWorkTimerState extends State<CompactWorkTimer> {
  late Duration _elapsedTime;
  late Duration _baseDuration;
  Timer? _timer;
  DateTime? _activeStartTime;

  @override
  void initState() {
    super.initState();
    _baseDuration = DateTime.now().difference(widget.startTime);
    _elapsedTime = _baseDuration;
    if (widget.isActive) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(CompactWorkTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime) {
      _baseDuration = DateTime.now().difference(widget.startTime);
      _elapsedTime = _baseDuration;
      if (widget.isActive) {
        _startTimer();
      }
    }
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _activeStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _activeStartTime != null) {
        setState(() {
          _elapsedTime =
              _baseDuration + DateTime.now().difference(_activeStartTime!);
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (_activeStartTime != null) {
      _baseDuration = _elapsedTime;
      _activeStartTime = null;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingS,
          vertical: AppTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer,
              color: AppTheme.primaryColor,
              size: 14,
            ),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              _formatDuration(_elapsedTime),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}
