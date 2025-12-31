// Activity History Timeline Widget - Displays activity logs in a timeline view

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/activity_log.dart';
import '../utils/app_theme.dart';

class ActivityHistoryTimeline extends StatelessWidget {
  const ActivityHistoryTimeline({
    required this.activityLogs,
    super.key,
  });

  final List<ActivityLog> activityLogs;

  @override
  Widget build(BuildContext context) {
    if (activityLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Activity History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Activity will be tracked here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: activityLogs.length,
      itemBuilder: (context, index) {
        final log = activityLogs[index];
        final isLast = index == activityLogs.length - 1;

        return _buildTimelineItem(log, isLast);
      },
    );
  }

  Widget _buildTimelineItem(ActivityLog log, bool isLast) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getActivityColor(log.activityType)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getActivityColor(log.activityType),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getActivityIcon(log.activityType),
                    size: 16,
                    color: _getActivityColor(log.activityType),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Activity content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity description with completion cycle badge if applicable
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.getDescription(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkTextColor,
                            ),
                          ),
                        ),
                        // Show completion cycle badge for PM tasks
                        if (log.entityType == 'pm_task' &&
                            log.additionalData != null &&
                            log.additionalData!.containsKey('completionCycle')) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '#${log.additionalData!['completionCycle']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // User and timestamp
                    Row(
                      children: [
                        if (log.userName != null &&
                            log.userName!.isNotEmpty) ...[
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log.userName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(log.timestamp),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    // Additional data if present
                    if (log.additionalData != null &&
                        log.additionalData!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: log.additionalData!.entries
                              .map(
                                (entry) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return AppTheme.accentGreen;
      case ActivityType.statusChanged:
        return AppTheme.accentBlue;
      case ActivityType.assigned:
      case ActivityType.reassigned:
        return Colors.purple;
      case ActivityType.unassigned:
        return AppTheme.accentOrange;
      case ActivityType.started:
        return Colors.teal;
      case ActivityType.completed:
        return AppTheme.successColor;
      case ActivityType.updated:
        return AppTheme.accentBlue;
      case ActivityType.deleted:
      case ActivityType.cancelled:
        return AppTheme.errorColor;
      case ActivityType.priorityChanged:
        return AppTheme.accentOrange;
      case ActivityType.noteAdded:
      case ActivityType.photoAdded:
        return Colors.indigo;
      case ActivityType.paused:
        return AppTheme.warningColor;
      case ActivityType.resumed:
        return Colors.teal;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return Icons.add_circle_outline;
      case ActivityType.statusChanged:
        return Icons.swap_horiz;
      case ActivityType.assigned:
        return Icons.person_add_outlined;
      case ActivityType.unassigned:
        return Icons.person_remove_outlined;
      case ActivityType.reassigned:
        return Icons.people_outline;
      case ActivityType.started:
        return Icons.play_arrow;
      case ActivityType.completed:
        return Icons.check_circle_outline;
      case ActivityType.updated:
        return Icons.edit_outlined;
      case ActivityType.deleted:
        return Icons.delete_outline;
      case ActivityType.cancelled:
        return Icons.cancel_outlined;
      case ActivityType.priorityChanged:
        return Icons.priority_high;
      case ActivityType.noteAdded:
        return Icons.note_add_outlined;
      case ActivityType.photoAdded:
        return Icons.photo_camera_outlined;
      case ActivityType.paused:
        return Icons.pause_circle_outline;
      case ActivityType.resumed:
        return Icons.play_circle_outline;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y HH:mm').format(timestamp);
    }
  }
}
