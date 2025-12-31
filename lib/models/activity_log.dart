// Activity Log Model - Tracks changes to work orders and PM tasks

enum ActivityType {
  created,
  statusChanged,
  assigned,
  unassigned,
  reassigned,
  started,
  completed,
  updated,
  deleted,
  cancelled,
  priorityChanged,
  noteAdded,
  photoAdded,
  paused,
  resumed,
}

class ActivityLog {
  ActivityLog({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.activityType,
    required this.timestamp,
    required this.userId,
    this.userName,
    this.description,
    this.oldValue,
    this.newValue,
    this.additionalData,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map) => ActivityLog(
        id: map['id'] as String,
        entityId: map['entityId'] as String,
        entityType: map['entityType'] as String,
        activityType: ActivityType.values.firstWhere(
          (e) => e.name == map['activityType'],
          orElse: () => ActivityType.updated,
        ),
        timestamp: DateTime.parse(map['timestamp'] as String),
        userId: map['userId'] as String,
        userName: map['userName'] as String?,
        description: map['description'] as String?,
        oldValue: map['oldValue'] as String?,
        newValue: map['newValue'] as String?,
        additionalData: map['additionalData'] as Map<String, dynamic>?,
      );

  final String id;
  final String entityId; // Work Order ID or PM Task ID
  final String entityType; // 'work_order' or 'pm_task'
  final ActivityType activityType;
  final DateTime timestamp;
  final String userId;
  final String? userName;
  final String? description;
  final String? oldValue;
  final String? newValue;
  final Map<String, dynamic>? additionalData;

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityId': entityId,
        'entityType': entityType,
        'activityType': activityType.name,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'userName': userName,
        'description': description,
        'oldValue': oldValue,
        'newValue': newValue,
        'additionalData': additionalData,
      };

  ActivityLog copyWith({
    String? id,
    String? entityId,
    String? entityType,
    ActivityType? activityType,
    DateTime? timestamp,
    String? userId,
    String? userName,
    String? description,
    String? oldValue,
    String? newValue,
    Map<String, dynamic>? additionalData,
  }) =>
      ActivityLog(
        id: id ?? this.id,
        entityId: entityId ?? this.entityId,
        entityType: entityType ?? this.entityType,
        activityType: activityType ?? this.activityType,
        timestamp: timestamp ?? this.timestamp,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        description: description ?? this.description,
        oldValue: oldValue ?? this.oldValue,
        newValue: newValue ?? this.newValue,
        additionalData: additionalData ?? this.additionalData,
      );

  /// Get a human-readable description of the activity
  String getDescription() {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }

    switch (activityType) {
      case ActivityType.created:
        return 'Created';
      case ActivityType.statusChanged:
        return 'Status changed from ${_formatValue(oldValue)} to ${_formatValue(newValue)}';
      case ActivityType.assigned:
        return 'Assigned to ${_formatValue(newValue)}';
      case ActivityType.unassigned:
        return 'Unassigned from ${_formatValue(oldValue)}';
      case ActivityType.reassigned:
        return 'Reassigned from ${_formatValue(oldValue)} to ${_formatValue(newValue)}';
      case ActivityType.started:
        return 'Started work';
      case ActivityType.completed:
        return 'Completed';
      case ActivityType.updated:
        return 'Updated';
      case ActivityType.deleted:
        return 'Deleted';
      case ActivityType.cancelled:
        return 'Cancelled';
      case ActivityType.priorityChanged:
        return 'Priority changed from ${_formatValue(oldValue)} to ${_formatValue(newValue)}';
      case ActivityType.noteAdded:
        return 'Added note';
      case ActivityType.photoAdded:
        return 'Added photo';
      case ActivityType.paused:
        return 'Work paused${description != null ? ': $description' : ''}';
      case ActivityType.resumed:
        return 'Work resumed';
    }
  }

  String _formatValue(String? value) {
    if (value == null || value.isEmpty) return 'N/A';
    return value;
  }
}
