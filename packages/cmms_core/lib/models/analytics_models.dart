// Analytics Models
//
// Contains all analytics-related data models for the CMMS system.

import 'package:flutter/material.dart';

/// KPI Metrics model
class KPIMetrics {
  const KPIMetrics({
    required this.mttr,
    required this.mtbf,
    required this.assetUptime,
    required this.technicianEfficiency,
    required this.totalWorkOrders,
    required this.completedWorkOrders,
    required this.overdueWorkOrders,
    required this.completionRate,
    required this.averageResponseTime,
    required this.averageTAT,
    required this.complianceRate,
  });

  factory KPIMetrics.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const KPIMetrics(
        mttr: 0,
        mtbf: 0,
        assetUptime: 0,
        technicianEfficiency: 0,
        totalWorkOrders: 0,
        completedWorkOrders: 0,
        overdueWorkOrders: 0,
        completionRate: 0,
        averageResponseTime: 0,
        averageTAT: 0,
        complianceRate: 0,
      );
    }

    return KPIMetrics(
      mttr: ((json['mttr'] as num?) ?? 0).toDouble(),
      mtbf: ((json['mtbf'] as num?) ?? 0).toDouble(),
      assetUptime: ((json['assetUptime'] as num?) ?? 0).toDouble(),
      technicianEfficiency:
          ((json['technicianEfficiency'] as num?) ?? 0).toDouble(),
      totalWorkOrders: json['totalWorkOrders'] as int? ?? 0,
      completedWorkOrders: json['completedWorkOrders'] as int? ?? 0,
      overdueWorkOrders: json['overdueWorkOrders'] as int? ?? 0,
      completionRate: ((json['completionRate'] as num?) ?? 0).toDouble(),
      averageResponseTime:
          ((json['averageResponseTime'] as num?) ?? 0).toDouble(),
      averageTAT: ((json['averageTAT'] as num?) ?? 0).toDouble(),
      complianceRate: ((json['complianceRate'] as num?) ?? 0).toDouble(),
    );
  }

  factory KPIMetrics.empty() => const KPIMetrics(
        mttr: 0,
        mtbf: 0,
        assetUptime: 0,
        technicianEfficiency: 0,
        totalWorkOrders: 0,
        completedWorkOrders: 0,
        overdueWorkOrders: 0,
        completionRate: 0,
        averageResponseTime: 0,
        averageTAT: 0,
        complianceRate: 0,
      );

  final double mttr; // Mean Time To Repair (hours)
  final double mtbf; // Mean Time Between Failures (hours)
  final double assetUptime; // Asset uptime percentage
  final double technicianEfficiency; // Technician efficiency percentage
  final int totalWorkOrders; // Total work orders in period
  final int completedWorkOrders; // Completed work orders in period
  final int overdueWorkOrders; // Overdue work orders
  final double completionRate; // Work order completion rate percentage
  final double averageResponseTime; // Average response time in hours
  final double averageTAT; // Average turnaround time in days
  final double complianceRate; // PM compliance rate percentage

  Map<String, dynamic> toJson() => {
        'mttr': mttr,
        'mtbf': mtbf,
        'assetUptime': assetUptime,
        'technicianEfficiency': technicianEfficiency,
        'totalWorkOrders': totalWorkOrders,
        'completedWorkOrders': completedWorkOrders,
        'overdueWorkOrders': overdueWorkOrders,
        'completionRate': completionRate,
        'averageResponseTime': averageResponseTime,
        'averageTAT': averageTAT,
        'complianceRate': complianceRate,
      };
}

/// Technician Performance model
class TechnicianPerformance {
  const TechnicianPerformance({
    required this.technicianId,
    required this.technicianName,
    required this.totalWorkOrders,
    required this.completedWorkOrders,
    required this.completionRate,
    required this.averageResponseTime,
    required this.averageCompletionTime,
    required this.overdueWorkOrders,
    required this.efficiencyScore,
    required this.specializations,
    required this.lastActivity,
    this.qualityScore,
    this.efficiency,
  });

  factory TechnicianPerformance.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TechnicianPerformance(
        technicianId: '',
        technicianName: '',
        totalWorkOrders: 0,
        completedWorkOrders: 0,
        completionRate: 0,
        averageResponseTime: 0,
        averageCompletionTime: 0,
        overdueWorkOrders: 0,
        efficiencyScore: 0,
        specializations: [],
        lastActivity: null,
      );
    }

    return TechnicianPerformance(
      technicianId: json['technicianId'] as String? ?? '',
      technicianName: json['technicianName'] as String? ?? '',
      totalWorkOrders: json['totalWorkOrders'] as int? ?? 0,
      completedWorkOrders: json['completedWorkOrders'] as int? ?? 0,
      completionRate: ((json['completionRate'] as num?) ?? 0).toDouble(),
      averageResponseTime:
          ((json['averageResponseTime'] as num?) ?? 0).toDouble(),
      averageCompletionTime:
          ((json['averageCompletionTime'] as num?) ?? 0).toDouble(),
      overdueWorkOrders: json['overdueWorkOrders'] as int? ?? 0,
      efficiencyScore: ((json['efficiencyScore'] as num?) ?? 0).toDouble(),
      specializations:
          List<String>.from((json['specializations'] as List?) ?? []),
      lastActivity: json['lastActivity'] != null
          ? DateTime.tryParse(json['lastActivity'] as String)
          : null,
      qualityScore: (json['qualityScore'] as num?)?.toDouble(),
      efficiency: (json['efficiency'] as num?)?.toDouble(),
    );
  }

  final String technicianId;
  final String technicianName;
  final int totalWorkOrders;
  final int completedWorkOrders;
  final double completionRate;
  final double averageResponseTime;
  final double averageCompletionTime;
  final int overdueWorkOrders;
  final double efficiencyScore;
  final List<String> specializations;
  final DateTime? lastActivity;
  final double? qualityScore;
  final double? efficiency;

  Map<String, dynamic> toJson() => {
        'technicianId': technicianId,
        'technicianName': technicianName,
        'totalWorkOrders': totalWorkOrders,
        'completedWorkOrders': completedWorkOrders,
        'completionRate': completionRate,
        'averageResponseTime': averageResponseTime,
        'averageCompletionTime': averageCompletionTime,
        'overdueWorkOrders': overdueWorkOrders,
        'efficiencyScore': efficiencyScore,
        'specializations': specializations,
        'lastActivity': lastActivity?.toIso8601String(),
        'qualityScore': qualityScore,
        'efficiency': efficiency,
      };
}

/// Asset Performance model
class AssetPerformance {
  const AssetPerformance({
    required this.assetId,
    required this.assetName,
    required this.totalWorkOrders,
    required this.uptime,
    required this.mtbf,
    required this.mttr,
    required this.maintenanceCost,
    required this.lastMaintenance,
    this.riskLevel,
    this.totalFailures = 0,
    this.criticalFailures = 0,
    this.costOfDowntime = 0.0,
    this.lastFailure,
    this.nextMaintenance,
    this.category,
  });

  factory AssetPerformance.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AssetPerformance(
        assetId: '',
        assetName: '',
        totalWorkOrders: 0,
        uptime: 0,
        mtbf: 0,
        mttr: 0,
        maintenanceCost: 0,
        lastMaintenance: null,
      );
    }

    return AssetPerformance(
      assetId: json['assetId'] as String? ?? '',
      assetName: json['assetName'] as String? ?? '',
      totalWorkOrders: json['totalWorkOrders'] as int? ?? 0,
      uptime: ((json['uptime'] as num?) ?? 0).toDouble(),
      mtbf: ((json['mtbf'] as num?) ?? 0).toDouble(),
      mttr: ((json['mttr'] as num?) ?? 0).toDouble(),
      maintenanceCost: ((json['maintenanceCost'] as num?) ?? 0).toDouble(),
      lastMaintenance: json['lastMaintenance'] != null
          ? DateTime.tryParse(json['lastMaintenance'] as String)
          : null,
      riskLevel: json['riskLevel'] as String?,
      totalFailures: json['totalFailures'] as int? ?? 0,
      criticalFailures: json['criticalFailures'] as int? ?? 0,
      costOfDowntime: ((json['costOfDowntime'] as num?) ?? 0).toDouble(),
      lastFailure: json['lastFailure'] != null
          ? DateTime.tryParse(json['lastFailure'] as String)
          : null,
      nextMaintenance: json['nextMaintenance'] != null
          ? DateTime.tryParse(json['nextMaintenance'] as String)
          : null,
      category: json['category'] as String?,
    );
  }

  final String assetId;
  final String assetName;
  final int totalWorkOrders;
  final double uptime;
  final double mtbf;
  final double mttr;
  final double maintenanceCost;
  final DateTime? lastMaintenance;
  final String? riskLevel;
  final int totalFailures;
  final int criticalFailures;
  final double costOfDowntime;
  final DateTime? lastFailure;
  final DateTime? nextMaintenance;
  final String? category;

  Map<String, dynamic> toJson() => {
        'assetId': assetId,
        'assetName': assetName,
        'totalWorkOrders': totalWorkOrders,
        'uptime': uptime,
        'mtbf': mtbf,
        'mttr': mttr,
        'maintenanceCost': maintenanceCost,
        'lastMaintenance': lastMaintenance?.toIso8601String(),
        'riskLevel': riskLevel,
        'totalFailures': totalFailures,
        'criticalFailures': criticalFailures,
        'costOfDowntime': costOfDowntime,
        'lastFailure': lastFailure?.toIso8601String(),
        'nextMaintenance': nextMaintenance?.toIso8601String(),
        'category': category,
      };
}

/// Maintenance Data Point model
class MaintenanceDataPoint {
  const MaintenanceDataPoint({
    required this.date,
    required this.reactiveWorkOrders,
    required this.preventiveWorkOrders,
    required this.totalWorkOrders,
    required this.totalCost,
    required this.workOrders,
    required this.completed,
    required this.mttr,
    required this.mtbf,
  });

  factory MaintenanceDataPoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MaintenanceDataPoint(
        date: DateTime.now(),
        reactiveWorkOrders: 0,
        preventiveWorkOrders: 0,
        totalWorkOrders: 0,
        totalCost: 0,
        workOrders: 0,
        completed: 0,
        mttr: 0,
        mtbf: 0,
      );
    }

    return MaintenanceDataPoint(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      reactiveWorkOrders: json['reactiveWorkOrders'] as int? ?? 0,
      preventiveWorkOrders: json['preventiveWorkOrders'] as int? ?? 0,
      totalWorkOrders: json['totalWorkOrders'] as int? ?? 0,
      totalCost: ((json['totalCost'] as num?) ?? 0).toDouble(),
      workOrders: json['workOrders'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      mttr: ((json['mttr'] as num?) ?? 0).toDouble(),
      mtbf: ((json['mtbf'] as num?) ?? 0).toDouble(),
    );
  }

  final DateTime date;
  final int reactiveWorkOrders;
  final int preventiveWorkOrders;
  final int totalWorkOrders;
  final double totalCost;
  final int workOrders;
  final int completed;
  final double mttr;
  final double mtbf;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'reactiveWorkOrders': reactiveWorkOrders,
        'preventiveWorkOrders': preventiveWorkOrders,
        'totalWorkOrders': totalWorkOrders,
        'totalCost': totalCost,
        'workOrders': workOrders,
        'completed': completed,
        'mttr': mttr,
        'mtbf': mtbf,
      };
}

/// Maintenance Trends model
class MaintenanceTrends {
  const MaintenanceTrends({
    required this.dataPoints,
    required this.period,
    required this.trendDirection,
    required this.weeklyData,
    required this.monthlyData,
    required this.yearlyData,
    required this.trendDescription,
  });

  factory MaintenanceTrends.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MaintenanceTrends(
        dataPoints: [],
        period: '',
        trendDirection: 0,
        weeklyData: [],
        monthlyData: [],
        yearlyData: [],
        trendDescription: '',
      );
    }

    return MaintenanceTrends(
      dataPoints: ((json['dataPoints'] as List?) ?? [])
          .map((e) => MaintenanceDataPoint.fromJson(e as Map<String, dynamic>?))
          .toList(),
      period: json['period'] as String? ?? '',
      trendDirection: ((json['trendDirection'] as num?) ?? 0).toDouble(),
      weeklyData: ((json['weeklyData'] as List?) ?? [])
          .map((e) => MaintenanceDataPoint.fromJson(e as Map<String, dynamic>?))
          .toList(),
      monthlyData: ((json['monthlyData'] as List?) ?? [])
          .map((e) => MaintenanceDataPoint.fromJson(e as Map<String, dynamic>?))
          .toList(),
      yearlyData: ((json['yearlyData'] as List?) ?? [])
          .map((e) => MaintenanceDataPoint.fromJson(e as Map<String, dynamic>?))
          .toList(),
      trendDescription: json['trendDescription'] as String? ?? '',
    );
  }

  final List<MaintenanceDataPoint> dataPoints;
  final String period; // e.g., "last_30_days", "last_6_months"
  final double trendDirection; // -1 (decreasing), 0 (stable), 1 (increasing)
  final List<MaintenanceDataPoint> weeklyData;
  final List<MaintenanceDataPoint> monthlyData;
  final List<MaintenanceDataPoint> yearlyData;
  final String trendDescription;

  Map<String, dynamic> toJson() => {
        'dataPoints': dataPoints.map((e) => e.toJson()).toList(),
        'period': period,
        'trendDirection': trendDirection,
        'weeklyData': weeklyData.map((e) => e.toJson()).toList(),
        'monthlyData': monthlyData.map((e) => e.toJson()).toList(),
        'yearlyData': yearlyData.map((e) => e.toJson()).toList(),
        'trendDescription': trendDescription,
      };
}

/// Cost Analysis model
class CostAnalysis {
  const CostAnalysis({
    required this.totalMaintenanceCost,
    required this.preventiveMaintenanceCost,
    required this.reactiveMaintenanceCost,
    required this.costByCategory,
    required this.costByAsset,
    required this.costPerWorkOrder,
    required this.costPerAsset,
    required this.downtimeCost,
    required this.laborCost,
    required this.partsCost,
    this.totalCost,
    this.averageCost,
    this.costByPriority,
    this.costTrend,
    this.budgetUtilization,
  });

  factory CostAnalysis.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CostAnalysis(
        totalMaintenanceCost: 0,
        preventiveMaintenanceCost: 0,
        reactiveMaintenanceCost: 0,
        costByCategory: {},
        costByAsset: {},
        costPerWorkOrder: 0,
        costPerAsset: 0,
        downtimeCost: 0,
        laborCost: 0,
        partsCost: 0,
      );
    }

    return CostAnalysis(
      totalMaintenanceCost:
          ((json['totalMaintenanceCost'] as num?) ?? 0).toDouble(),
      preventiveMaintenanceCost:
          ((json['preventiveMaintenanceCost'] as num?) ?? 0).toDouble(),
      reactiveMaintenanceCost:
          ((json['reactiveMaintenanceCost'] as num?) ?? 0).toDouble(),
      costByCategory:
          Map<String, double>.from((json['costByCategory'] as Map?) ?? {}),
      costByAsset:
          Map<String, double>.from((json['costByAsset'] as Map?) ?? {}),
      costPerWorkOrder: ((json['costPerWorkOrder'] as num?) ?? 0).toDouble(),
      costPerAsset: ((json['costPerAsset'] as num?) ?? 0).toDouble(),
      downtimeCost: ((json['downtimeCost'] as num?) ?? 0).toDouble(),
      laborCost: ((json['laborCost'] as num?) ?? 0).toDouble(),
      partsCost: ((json['partsCost'] as num?) ?? 0).toDouble(),
    );
  }

  final double totalMaintenanceCost;
  final double preventiveMaintenanceCost;
  final double reactiveMaintenanceCost;
  final Map<String, double> costByCategory;
  final Map<String, double> costByAsset;
  final double costPerWorkOrder;
  final double costPerAsset;
  final double downtimeCost;
  final double laborCost;
  final double partsCost;
  final double? totalCost;
  final double? averageCost;
  final Map<String, double>? costByPriority;
  final double? costTrend;
  final double? budgetUtilization;

  Map<String, dynamic> toJson() => {
        'totalMaintenanceCost': totalMaintenanceCost,
        'preventiveMaintenanceCost': preventiveMaintenanceCost,
        'reactiveMaintenanceCost': reactiveMaintenanceCost,
        'costByCategory': costByCategory,
        'costByAsset': costByAsset,
        'costPerWorkOrder': costPerWorkOrder,
        'costPerAsset': costPerAsset,
        'downtimeCost': downtimeCost,
        'laborCost': laborCost,
        'partsCost': partsCost,
        'totalCost': totalCost,
        'averageCost': averageCost,
        'costByPriority': costByPriority,
        'costTrend': costTrend,
        'budgetUtilization': budgetUtilization,
      };
}

/// Analytics Report model
class AnalyticsReport {
  const AnalyticsReport({
    required this.kpiMetrics,
    required this.technicianPerformance,
    required this.assetPerformance,
    required this.maintenanceTrends,
    required this.costAnalysis,
    required this.generatedAt,
    required this.reportPeriod,
    required this.trends,
  });

  factory AnalyticsReport.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AnalyticsReport(
        kpiMetrics: KPIMetrics.empty(),
        technicianPerformance: [],
        assetPerformance: [],
        maintenanceTrends: const MaintenanceTrends(
          dataPoints: [],
          period: '',
          trendDirection: 0,
          weeklyData: [],
          monthlyData: [],
          yearlyData: [],
          trendDescription: '',
        ),
        costAnalysis: const CostAnalysis(
          totalMaintenanceCost: 0,
          preventiveMaintenanceCost: 0,
          reactiveMaintenanceCost: 0,
          costByCategory: {},
          costByAsset: {},
          costPerWorkOrder: 0,
          costPerAsset: 0,
          downtimeCost: 0,
          laborCost: 0,
          partsCost: 0,
        ),
        generatedAt: DateTime.now(),
        reportPeriod: '',
        trends: const MaintenanceTrends(
          dataPoints: [],
          period: '',
          trendDirection: 0,
          weeklyData: [],
          monthlyData: [],
          yearlyData: [],
          trendDescription: '',
        ),
      );
    }

    return AnalyticsReport(
      kpiMetrics:
          KPIMetrics.fromJson(json['kpiMetrics'] as Map<String, dynamic>?),
      technicianPerformance: ((json['technicianPerformance'] as List?) ?? [])
          .map(
            (e) => TechnicianPerformance.fromJson(e as Map<String, dynamic>?),
          )
          .toList(),
      assetPerformance: ((json['assetPerformance'] as List?) ?? [])
          .map((e) => AssetPerformance.fromJson(e as Map<String, dynamic>?))
          .toList(),
      maintenanceTrends: MaintenanceTrends.fromJson(
        json['maintenanceTrends'] as Map<String, dynamic>?,
      ),
      costAnalysis:
          CostAnalysis.fromJson(json['costAnalysis'] as Map<String, dynamic>?),
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      reportPeriod: json['reportPeriod'] as String? ?? '',
      trends:
          MaintenanceTrends.fromJson(json['trends'] as Map<String, dynamic>?),
    );
  }

  final KPIMetrics kpiMetrics;
  final List<TechnicianPerformance> technicianPerformance;
  final List<AssetPerformance> assetPerformance;
  final MaintenanceTrends maintenanceTrends;
  final CostAnalysis costAnalysis;
  final DateTime generatedAt;
  final String reportPeriod;
  final MaintenanceTrends trends;

  Map<String, dynamic> toJson() => {
        'kpiMetrics': kpiMetrics.toJson(),
        'technicianPerformance':
            technicianPerformance.map((e) => e.toJson()).toList(),
        'assetPerformance': assetPerformance.map((e) => e.toJson()).toList(),
        'maintenanceTrends': maintenanceTrends.toJson(),
        'costAnalysis': costAnalysis.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
        'reportPeriod': reportPeriod,
        'trends': trends.toJson(),
      };
}

/// Notification Data model
class NotificationData {
  const NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.readAt,
    this.isRead = false,
    this.data = const {},
    this.technicianId,
    this.pmTaskId,
    this.assetId,
  });

  factory NotificationData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return NotificationData(
        id: '',
        title: '',
        body: '',
        type: NotificationType.systemUpdate,
        priority: NotificationPriority.medium,
        createdAt: DateTime.now(),
      );
    }

    return NotificationData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: _parseNotificationType(json['type'] as String?),
      priority: _parseNotificationPriority(json['priority'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      data: Map<String, dynamic>.from((json['data'] as Map?) ?? {}),
      technicianId: json['technicianId'] as String?,
      pmTaskId: json['pmTaskId'] as String?,
      assetId: json['assetId'] as String?,
    );
  }

  /// Create a copy of this notification with updated fields
  NotificationData copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? readAt,
    bool? isRead,
    Map<String, dynamic>? data,
    String? technicianId,
    String? pmTaskId,
    String? assetId,
  }) =>
      NotificationData(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        createdAt: createdAt ?? this.createdAt,
        readAt: readAt ?? this.readAt,
        isRead: isRead ?? this.isRead,
        data: data ?? this.data,
        technicianId: technicianId ?? this.technicianId,
        pmTaskId: pmTaskId ?? this.pmTaskId,
        assetId: assetId ?? this.assetId,
      );

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;
  final Map<String, dynamic> data;
  final String? technicianId;
  final String? pmTaskId;
  final String? assetId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
        'isRead': isRead,
        'data': data,
        'technicianId': technicianId,
        'pmTaskId': pmTaskId,
        'assetId': assetId,
      };

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'workOrderAssigned':
        return NotificationType.workOrderAssigned;
      case 'workOrderCompleted':
        return NotificationType.workOrderCompleted;
      case 'workOrderOverdue':
        return NotificationType.workOrderOverdue;
      case 'pmTaskDue':
        return NotificationType.pmTaskDue;
      case 'pmTaskOverdue':
        return NotificationType.pmTaskOverdue;
      case 'assetFailure':
        return NotificationType.assetFailure;
      case 'criticalAlert':
        return NotificationType.criticalAlert;
      case 'systemUpdate':
        return NotificationType.systemUpdate;
      case 'maintenanceReminder':
        return NotificationType.maintenanceReminder;
      default:
        return NotificationType.systemUpdate;
    }
  }

  static NotificationPriority _parseNotificationPriority(String? priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      case 'critical':
        return NotificationPriority.critical;
      default:
        return NotificationPriority.medium;
    }
  }
}

/// Notification Type enum
enum NotificationType {
  workOrderAssigned,
  workOrderCompleted,
  workOrderOverdue,
  pmTaskDue,
  pmTaskOverdue,
  assetFailure,
  criticalAlert,
  systemUpdate,
  maintenanceReminder,
}

/// Notification Priority enum
enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

/// Extension for NotificationType to provide icon and display name
extension NotificationTypeExtension on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.workOrderAssigned:
        return Icons.assignment;
      case NotificationType.workOrderCompleted:
        return Icons.check_circle;
      case NotificationType.workOrderOverdue:
        return Icons.warning;
      case NotificationType.pmTaskDue:
        return Icons.schedule;
      case NotificationType.pmTaskOverdue:
        return Icons.error;
      case NotificationType.assetFailure:
        return Icons.build;
      case NotificationType.criticalAlert:
        return Icons.priority_high;
      case NotificationType.systemUpdate:
        return Icons.system_update;
      case NotificationType.maintenanceReminder:
        return Icons.construction;
    }
  }
}

/// Extension for NotificationPriority to provide display name
extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.critical:
        return 'Critical';
    }
  }
}
