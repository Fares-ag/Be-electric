// Analytics Calculator
//
// Handles all analytics calculations including:
// - KPI calculations (MTBF, MTTR, etc.)
// - Metrics computation
// - Statistical analysis
//
// Consolidated from multiple analytics services.

import 'package:cmms_core/models/analytics_models.dart';
import 'package:cmms_core/models/asset.dart';
import 'package:cmms_core/models/pm_task.dart';
import 'package:cmms_core/models/work_order.dart';

/// Calculator for all analytics metrics
class AnalyticsCalculator {
  /// Create an analytics calculator instance
  ///
  /// Note: Use GetIt service locator to obtain instances:
  /// ```dart
  /// final calculator = getIt<AnalyticsCalculator>();
  /// ```
  AnalyticsCalculator();

  /// Calculate comprehensive KPIs.
  /// [workOrders] and [pmTasks] should already be period- and scope-filtered by the caller
  /// (e.g. dashboard filters by updatedAt in period and optional technician/asset).
  Future<KPIMetrics> calculateKPIs({
    required List<WorkOrder> workOrders,
    required List<Asset> assets,
    required List<PMTask> pmTasks,
    Duration period = const Duration(days: 30),
  }) async {
    // Use passed lists as-is so KPIs match dashboard period filter (e.g. updated in period).
    final mttrValue = _calculateMTTR(workOrders);
    final mtbfValue = _calculateMTBF(workOrders, assets);
    final assetUptimeValue = _calculateAssetUptime(assets, workOrders);
    final techEfficiency = _calculateTechnicianEfficiency(workOrders);
    final total = workOrders.length;
    final completed = workOrders
        .where((wo) =>
            wo.status == WorkOrderStatus.completed ||
            wo.status == WorkOrderStatus.closed,)
        .length;
    // Overdue: open WOs created more than 7 days ago
    final overdue = workOrders.where((wo) {
      return wo.status == WorkOrderStatus.open &&
          wo.createdAt
              .isBefore(DateTime.now().subtract(const Duration(days: 7)));
    }).length;
    final completionRate = total > 0 ? (completed / total * 100) : 0.0;
    final avgResponseTime = _calculateAverageResponseTime(workOrders);
    final avgTAT = _calculateAverageTAT(workOrders);
    final compliance = _calculatePMCompliance(pmTasks);

    return KPIMetrics(
      mttr: mttrValue,
      mtbf: mtbfValue,
      assetUptime: assetUptimeValue,
      technicianEfficiency: techEfficiency,
      totalWorkOrders: total,
      completedWorkOrders: completed,
      overdueWorkOrders: overdue,
      completionRate: completionRate,
      averageResponseTime: avgResponseTime,
      averageTAT: avgTAT,
      complianceRate: compliance,
    );
  }

  /// Calculate work order metrics
  Map<String, dynamic> calculateWorkOrderMetrics(List<WorkOrder> workOrders) {
    final total = workOrders.length;
    final completed =
        workOrders.where((wo) => wo.status == WorkOrderStatus.completed).length;
    final open =
        workOrders.where((wo) => wo.status == WorkOrderStatus.open).length;
    final inProgress = workOrders
        .where((wo) => wo.status == WorkOrderStatus.inProgress)
        .length;
    final assigned =
        workOrders.where((wo) => wo.status == WorkOrderStatus.assigned).length;

    final avgCompletionTime = _calculateAverageCompletionTime(workOrders);
    final priorityBreakdown = _calculatePriorityBreakdown(workOrders);

    return {
      'total': total,
      'completed': completed,
      'open': open,
      'inProgress': inProgress,
      'assigned': assigned,
      'completionRate': total > 0 ? (completed / total * 100) : 0.0,
      'avgCompletionTime': avgCompletionTime,
      'priorityBreakdown': priorityBreakdown,
    };
  }

  /// Calculate asset metrics
  Map<String, dynamic> calculateAssetMetrics(
    List<Asset> assets,
    List<WorkOrder> workOrders,
  ) {
    final total = assets.length;
    final operational = assets.where((a) => a.status == 'active').length;
    final maintenance = assets.where((a) => a.status == 'maintenance').length;
    final outOfService = assets.where((a) => a.status == 'inactive').length;

    final highRiskAssets = _identifyHighRiskAssets(assets, workOrders);
    final categoryBreakdown = _calculateCategoryBreakdown(assets);

    return {
      'total': total,
      'operational': operational,
      'maintenance': maintenance,
      'outOfService': outOfService,
      'operationalRate': total > 0 ? (operational / total * 100) : 0.0,
      'highRiskAssets': highRiskAssets.length,
      'categoryBreakdown': categoryBreakdown,
    };
  }

  /// Calculate PM task metrics
  Map<String, dynamic> calculatePMTaskMetrics(List<PMTask> pmTasks) {
    final total = pmTasks.length;
    final completed =
        pmTasks.where((pm) => pm.status == PMTaskStatus.completed).length;
    final pending =
        pmTasks.where((pm) => pm.status == PMTaskStatus.pending).length;
    final overdue =
        pmTasks.where((pm) => pm.status == PMTaskStatus.overdue).length;

    final compliance = total > 0 ? (completed / total * 100) : 0.0;
    final frequencyBreakdown = _calculateFrequencyBreakdown(pmTasks);

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
      'compliance': compliance,
      'frequencyBreakdown': frequencyBreakdown,
    };
  }

  // ============================================================================
  // PRIVATE CALCULATION METHODS
  // ============================================================================

  /// Calculate Mean Time Between Failures
  double _calculateMTBF(List<WorkOrder> workOrders, List<Asset> assets) {
    if (assets.isEmpty) return 0;

    final assetFailures = <String, int>{};
    for (final wo in workOrders) {
      if (wo.status == WorkOrderStatus.completed &&
          wo.assetId != null &&
          wo.assetId!.isNotEmpty) {
        assetFailures[wo.assetId!] = (assetFailures[wo.assetId!] ?? 0) + 1;
      }
    }

    if (assetFailures.isEmpty) return 0;

    final totalFailures = assetFailures.values.reduce((a, b) => a + b);
    final avgFailuresPerAsset = totalFailures / assetFailures.length;

    // Estimate MTBF (hours) - simplified calculation
    return avgFailuresPerAsset > 0
        ? (8760 / avgFailuresPerAsset)
        : 8760.0; // hours in a year
  }

  /// Calculate Mean Time To Repair (hours). Uses fractional hours for accuracy.
  double _calculateMTTR(List<WorkOrder> workOrders) {
    final completed = workOrders
        .where((wo) =>
            wo.status == WorkOrderStatus.completed ||
            wo.status == WorkOrderStatus.closed,)
        .toList();

    if (completed.isEmpty) return 0;

    double totalHours = 0;
    var count = 0;

    for (final wo in completed) {
      final endAt = wo.completedAt ?? wo.updatedAt;
      final duration = endAt.difference(wo.createdAt);
      totalHours += duration.inMilliseconds / (1000 * 60 * 60);
      count++;
    }

    return count > 0 ? totalHours / count : 0.0;
  }

  /// Calculate asset uptime
  double _calculateAssetUptime(List<Asset> assets, List<WorkOrder> workOrders) {
    if (assets.isEmpty) return 100;

    final operational = assets.where((a) => a.status == 'active').length;
    return (operational / assets.length) * 100;
  }

  /// Calculate technician efficiency (completed + closed as success)
  double _calculateTechnicianEfficiency(List<WorkOrder> workOrders) {
    final total = workOrders.length;
    if (total == 0) return 0;

    final completed = workOrders
        .where((wo) =>
            wo.status == WorkOrderStatus.completed ||
            wo.status == WorkOrderStatus.closed,)
        .length;
    return (completed / total) * 100;
  }

  /// Calculate average response time (hours from creation to assignment). Uses fractional hours.
  double _calculateAverageResponseTime(List<WorkOrder> workOrders) {
    final assigned = workOrders.where((wo) => wo.assignedAt != null).toList();

    if (assigned.isEmpty) return 0;

    double totalHours = 0;
    for (final wo in assigned) {
      final duration = wo.assignedAt!.difference(wo.createdAt);
      totalHours += duration.inMilliseconds / (1000 * 60 * 60);
    }

    return totalHours / assigned.length;
  }

  /// Calculate average turnaround time (days from creation to completion). Uses fractional days.
  double _calculateAverageTAT(List<WorkOrder> workOrders) {
    final completed = workOrders
        .where((wo) =>
            wo.status == WorkOrderStatus.completed ||
            wo.status == WorkOrderStatus.closed,)
        .toList();

    if (completed.isEmpty) return 0;

    double totalDays = 0;
    for (final wo in completed) {
      final endAt = wo.completedAt ?? wo.updatedAt;
      final duration = endAt.difference(wo.createdAt);
      totalDays += duration.inMilliseconds / (1000 * 60 * 60 * 24);
    }

    return totalDays / completed.length;
  }

  /// Calculate PM task compliance
  double _calculatePMCompliance(List<PMTask> pmTasks) {
    if (pmTasks.isEmpty) return 100;

    final completed =
        pmTasks.where((pm) => pm.status == PMTaskStatus.completed).length;
    return (completed / pmTasks.length) * 100;
  }

  /// Calculate average completion time (hours). Uses fractional hours. Includes closed WOs; uses completedAt ?? updatedAt.
  double _calculateAverageCompletionTime(List<WorkOrder> workOrders) {
    final completed = workOrders
        .where((wo) =>
            wo.status == WorkOrderStatus.completed ||
            wo.status == WorkOrderStatus.closed,)
        .toList();

    if (completed.isEmpty) return 0;

    double totalHours = 0;
    for (final wo in completed) {
      final endAt = wo.completedAt ?? wo.updatedAt;
      final duration = endAt.difference(wo.createdAt);
      totalHours += duration.inMilliseconds / (1000 * 60 * 60);
    }

    return totalHours / completed.length;
  }

  /// Calculate priority breakdown
  Map<String, int> _calculatePriorityBreakdown(List<WorkOrder> workOrders) => {
        'critical': workOrders
            .where((wo) => wo.priority == WorkOrderPriority.critical)
            .length,
        'high': workOrders
            .where((wo) => wo.priority == WorkOrderPriority.high)
            .length,
        'medium': workOrders
            .where((wo) => wo.priority == WorkOrderPriority.medium)
            .length,
        'low': workOrders
            .where((wo) => wo.priority == WorkOrderPriority.low)
            .length,
      };

  /// Identify high-risk assets
  List<Asset> _identifyHighRiskAssets(
    List<Asset> assets,
    List<WorkOrder> workOrders,
  ) =>
      assets.where((asset) {
        final assetWorkOrders =
            workOrders.where((wo) => wo.assetId == asset.id).length;
        return assetWorkOrders > 5; // More than 5 work orders = high risk
      }).toList();

  /// Calculate category breakdown
  Map<String, int> _calculateCategoryBreakdown(List<Asset> assets) {
    final breakdown = <String, int>{};
    for (final asset in assets) {
      final category =
          (asset.category?.isEmpty ?? true) ? 'Uncategorized' : asset.category!;
      breakdown[category] = (breakdown[category] ?? 0) + 1;
    }
    return breakdown;
  }

  /// Calculate frequency breakdown
  Map<String, int> _calculateFrequencyBreakdown(List<PMTask> pmTasks) => {
        'daily':
            pmTasks.where((pm) => pm.frequency == PMTaskFrequency.daily).length,
        'weekly': pmTasks
            .where((pm) => pm.frequency == PMTaskFrequency.weekly)
            .length,
        'monthly': pmTasks
            .where((pm) => pm.frequency == PMTaskFrequency.monthly)
            .length,
        'quarterly': pmTasks
            .where((pm) => pm.frequency == PMTaskFrequency.quarterly)
            .length,
        'annually': pmTasks
            .where((pm) => pm.frequency == PMTaskFrequency.annually)
            .length,
      };
}
