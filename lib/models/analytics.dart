// Analytics data models for KPI calculations and reporting

class KPIMetrics {
  KPIMetrics({
    required this.mttr,
    required this.mtbf,
    required this.assetUptime,
    required this.totalWorkOrders,
    required this.completedWorkOrders,
    required this.overdueWorkOrders,
    required this.completionRate,
    required this.averageResponseTime,
    required this.calculatedAt,
  });

  factory KPIMetrics.fromMap(Map<String, dynamic> map) => KPIMetrics(
        mttr: map['mttr']?.toDouble() ?? 0.0,
        mtbf: map['mtbf']?.toDouble() ?? 0.0,
        assetUptime: map['assetUptime']?.toDouble() ?? 0.0,
        totalWorkOrders: map['totalWorkOrders']?.toInt() ?? 0,
        completedWorkOrders: map['completedWorkOrders']?.toInt() ?? 0,
        overdueWorkOrders: map['overdueWorkOrders']?.toInt() ?? 0,
        completionRate: map['completionRate']?.toDouble() ?? 0.0,
        averageResponseTime: map['averageResponseTime']?.toDouble() ?? 0.0,
        calculatedAt: DateTime.parse(map['calculatedAt']),
      );
  final double mttr; // Mean Time To Repair (hours)
  final double mtbf; // Mean Time Between Failures (hours)
  final double assetUptime; // Asset uptime percentage
  final int totalWorkOrders;
  final int completedWorkOrders;
  final int overdueWorkOrders;
  final double completionRate;
  final double averageResponseTime; // hours
  final DateTime calculatedAt;

  Map<String, dynamic> toMap() => {
        'mttr': mttr,
        'mtbf': mtbf,
        'assetUptime': assetUptime,
        'totalWorkOrders': totalWorkOrders,
        'completedWorkOrders': completedWorkOrders,
        'overdueWorkOrders': overdueWorkOrders,
        'completionRate': completionRate,
        'averageResponseTime': averageResponseTime,
        'calculatedAt': calculatedAt.toIso8601String(),
      };
}

class TechnicianPerformance {
  TechnicianPerformance({
    required this.technicianId,
    required this.technicianName,
    required this.totalWorkOrders,
    required this.completedWorkOrders,
    required this.completionRate,
    required this.averageResponseTime,
    required this.averageCompletionTime,
    required this.overdueWorkOrders,
    required this.customerSatisfaction,
    required this.lastUpdated,
  });

  factory TechnicianPerformance.fromMap(Map<String, dynamic> map) =>
      TechnicianPerformance(
        technicianId: map['technicianId'] ?? '',
        technicianName: map['technicianName'] ?? '',
        totalWorkOrders: map['totalWorkOrders']?.toInt() ?? 0,
        completedWorkOrders: map['completedWorkOrders']?.toInt() ?? 0,
        completionRate: map['completionRate']?.toDouble() ?? 0.0,
        averageResponseTime: map['averageResponseTime']?.toDouble() ?? 0.0,
        averageCompletionTime: map['averageCompletionTime']?.toDouble() ?? 0.0,
        overdueWorkOrders: map['overdueWorkOrders']?.toInt() ?? 0,
        customerSatisfaction: map['customerSatisfaction']?.toDouble() ?? 0.0,
        lastUpdated: DateTime.parse(map['lastUpdated']),
      );
  final String technicianId;
  final String technicianName;
  final int totalWorkOrders;
  final int completedWorkOrders;
  final double completionRate;
  final double averageResponseTime; // hours
  final double averageCompletionTime; // hours
  final int overdueWorkOrders;
  final double customerSatisfaction; // 1-5 scale
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() => {
        'technicianId': technicianId,
        'technicianName': technicianName,
        'totalWorkOrders': totalWorkOrders,
        'completedWorkOrders': completedWorkOrders,
        'completionRate': completionRate,
        'averageResponseTime': averageResponseTime,
        'averageCompletionTime': averageCompletionTime,
        'overdueWorkOrders': overdueWorkOrders,
        'customerSatisfaction': customerSatisfaction,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}

class AssetDowntime {
  AssetDowntime({
    required this.assetId,
    required this.assetName,
    required this.assetLocation,
    required this.totalDowntimeHours,
    required this.failureCount,
    required this.averageDowntimePerFailure,
    required this.downtimeCost,
    required this.commonFailureReasons,
    required this.lastFailure,
    required this.lastUpdated,
  });

  factory AssetDowntime.fromMap(Map<String, dynamic> map) => AssetDowntime(
        assetId: map['assetId'] ?? '',
        assetName: map['assetName'] ?? '',
        assetLocation: map['assetLocation'] ?? '',
        totalDowntimeHours: map['totalDowntimeHours']?.toDouble() ?? 0.0,
        failureCount: map['failureCount']?.toInt() ?? 0,
        averageDowntimePerFailure:
            map['averageDowntimePerFailure']?.toDouble() ?? 0.0,
        downtimeCost: map['downtimeCost']?.toDouble() ?? 0.0,
        commonFailureReasons:
            List<String>.from(map['commonFailureReasons'] ?? []),
        lastFailure: DateTime.parse(map['lastFailure']),
        lastUpdated: DateTime.parse(map['lastUpdated']),
      );
  final String assetId;
  final String assetName;
  final String assetLocation;
  final double totalDowntimeHours;
  final int failureCount;
  final double averageDowntimePerFailure; // hours
  final double downtimeCost; // estimated cost
  final List<String> commonFailureReasons;
  final DateTime lastFailure;
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() => {
        'assetId': assetId,
        'assetName': assetName,
        'assetLocation': assetLocation,
        'totalDowntimeHours': totalDowntimeHours,
        'failureCount': failureCount,
        'averageDowntimePerFailure': averageDowntimePerFailure,
        'downtimeCost': downtimeCost,
        'commonFailureReasons': commonFailureReasons,
        'lastFailure': lastFailure.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}

class MaintenanceTrend {
  MaintenanceTrend({
    required this.date,
    required this.preventiveMaintenance,
    required this.reactiveMaintenance,
    required this.emergencyMaintenance,
    required this.totalCost,
    required this.averageCompletionTime,
  });

  factory MaintenanceTrend.fromMap(Map<String, dynamic> map) =>
      MaintenanceTrend(
        date: DateTime.parse(map['date']),
        preventiveMaintenance: map['preventiveMaintenance']?.toInt() ?? 0,
        reactiveMaintenance: map['reactiveMaintenance']?.toInt() ?? 0,
        emergencyMaintenance: map['emergencyMaintenance']?.toInt() ?? 0,
        totalCost: map['totalCost']?.toDouble() ?? 0.0,
        averageCompletionTime: map['averageCompletionTime']?.toDouble() ?? 0.0,
      );
  final DateTime date;
  final int preventiveMaintenance;
  final int reactiveMaintenance;
  final int emergencyMaintenance;
  final double totalCost;
  final double averageCompletionTime;

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'preventiveMaintenance': preventiveMaintenance,
        'reactiveMaintenance': reactiveMaintenance,
        'emergencyMaintenance': emergencyMaintenance,
        'totalCost': totalCost,
        'averageCompletionTime': averageCompletionTime,
      };
}

class AnalyticsSummary {
  // "daily", "weekly", "monthly", "yearly"

  AnalyticsSummary({
    required this.kpiMetrics,
    required this.technicianPerformance,
    required this.assetDowntime,
    required this.maintenanceTrends,
    required this.generatedAt,
    required this.period,
  });

  factory AnalyticsSummary.fromMap(Map<String, dynamic> map) =>
      AnalyticsSummary(
        kpiMetrics: KPIMetrics.fromMap(map['kpiMetrics']),
        technicianPerformance: List<TechnicianPerformance>.from(
          map['technicianPerformance']
                  ?.map((x) => TechnicianPerformance.fromMap(x)) ??
              [],
        ),
        assetDowntime: List<AssetDowntime>.from(
          map['assetDowntime']?.map((x) => AssetDowntime.fromMap(x)) ?? [],
        ),
        maintenanceTrends: List<MaintenanceTrend>.from(
          map['maintenanceTrends']?.map((x) => MaintenanceTrend.fromMap(x)) ??
              [],
        ),
        generatedAt: DateTime.parse(map['generatedAt']),
        period: map['period'] ?? 'monthly',
      );
  final KPIMetrics kpiMetrics;
  final List<TechnicianPerformance> technicianPerformance;
  final List<AssetDowntime> assetDowntime;
  final List<MaintenanceTrend> maintenanceTrends;
  final DateTime generatedAt;
  final String period;

  Map<String, dynamic> toMap() => {
        'kpiMetrics': kpiMetrics.toMap(),
        'technicianPerformance':
            technicianPerformance.map((x) => x.toMap()).toList(),
        'assetDowntime': assetDowntime.map((x) => x.toMap()).toList(),
        'maintenanceTrends': maintenanceTrends.map((x) => x.toMap()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
        'period': period,
      };
}
