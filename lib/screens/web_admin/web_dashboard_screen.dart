import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/pm_task.dart';
import '../../models/work_order.dart';
import '../../providers/unified_data_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/chart_theme.dart';

class WebDashboardScreen extends StatelessWidget {
  const WebDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<UnifiedDataProvider>(
        builder: (context, dataProvider, child) {
          final workOrders = dataProvider.workOrders;
          final pmTasks = dataProvider.pmTasks;
          final assets = dataProvider.assets;

          // Calculate KPIs
          final openWorkOrders = workOrders
              .where((wo) => wo.status == WorkOrderStatus.open)
              .length;
          final inProgressWorkOrders = workOrders
              .where((wo) => wo.status == WorkOrderStatus.inProgress)
              .length;
          final completedThisMonth = workOrders
              .where(
                (wo) =>
                    wo.status == WorkOrderStatus.completed &&
                    wo.completedAt != null &&
                    wo.completedAt!.month == DateTime.now().month,
              )
              .length;
          final overduePMTasks = pmTasks
              .where(
                (pm) =>
                    pm.nextDueDate != null &&
                    pm.nextDueDate!.isBefore(DateTime.now()) &&
                    pm.status != PMTaskStatus.completed,
              )
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        'Open Work Orders',
                        openWorkOrders.toString(),
                        Icons.work_outline,
                        const Color(0xFF3B82F6),
                        '+12%',
                        true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKPICard(
                        'In Progress',
                        inProgressWorkOrders.toString(),
                        Icons.engineering,
                        const Color(0xFFF59E0B),
                        '+5%',
                        true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKPICard(
                        'Completed (Month)',
                        completedThisMonth.toString(),
                        Icons.check_circle_outline,
                        const Color(0xFF10B981),
                        '+18%',
                        true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKPICard(
                        'Overdue PM Tasks',
                        overduePMTasks.toString(),
                        Icons.warning_amber_outlined,
                        const Color(0xFFEF4444),
                        '-3%',
                        false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Charts Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Work Orders Trend Chart
                    Expanded(
                      flex: 2,
                      child: _buildChartCard(
                          'Work Orders Trend', _buildSfLineChart(workOrders),),
                    ),
                    const SizedBox(width: 16),
                    // Status Distribution
                    Expanded(
                      child: _buildChartCard(
                          'Status Distribution', _buildSfPieChart(workOrders),),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Activity and Assets Health
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent Work Orders
                    Expanded(
                      child: _buildRecentWorkOrders(workOrders),
                    ),
                    const SizedBox(width: 16),
                    // Asset Health
                    Expanded(
                      child:
                          _buildAssetHealth(assets.length, workOrders.length),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    bool isPositive,
  ) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isPositive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
          ],
        ),
      );

  Widget _buildChartCard(String title, Widget chart) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 250, child: chart),
          ],
        ),
      );

  Widget _buildSfLineChart(List<WorkOrder> workOrders) {
    // Group work orders by last 7 days
    final now = DateTime.now();
    final data = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final count = workOrders
          .where(
            (wo) =>
                wo.createdAt.year == date.year &&
                wo.createdAt.month == date.month &&
                wo.createdAt.day == date.day,
          )
          .length;
      return _DayCount(date: date, count: count.toDouble());
    });

    return SfCartesianChart(
      primaryXAxis: ChartThemeUtil.dateTimeXAxis(),
      primaryYAxis: ChartThemeUtil.yAxisZero(),
      tooltipBehavior: ChartThemeUtil.tooltip('point.x: point.y'),
      series: <CartesianSeries<_DayCount, DateTime>>[
        SplineSeries<_DayCount, DateTime>(
          dataSource: data,
          xValueMapper: (_DayCount d, _) => d.date,
          yValueMapper: (_DayCount d, _) => d.count,
          color: AppTheme.accentBlue,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildSfPieChart(List<WorkOrder> workOrders) {
    final statusCounts = <WorkOrderStatus, int>{};
    for (final wo in workOrders) {
      statusCounts[wo.status] = (statusCounts[wo.status] ?? 0) + 1;
    }

    final colors = {
      WorkOrderStatus.open: const Color(0xFF3B82F6),
      WorkOrderStatus.assigned: const Color(0xFF8B5CF6),
      WorkOrderStatus.inProgress: const Color(0xFFF59E0B),
      WorkOrderStatus.completed: const Color(0xFF10B981),
      WorkOrderStatus.closed: const Color(0xFF6B7280),
    };

    final data = statusCounts.entries
        .map(
          (e) => _StatusSlice(
            label: e.key.name,
            value: e.value.toDouble(),
            color: colors[e.key] ?? Colors.grey,
          ),
        )
        .toList();

    return SfCircularChart(
      legend: ChartThemeUtil.legendRight(),
      tooltipBehavior: ChartThemeUtil.tooltip('point.x: point.y'),
      series: <CircularSeries<_StatusSlice, String>>[
        DoughnutSeries<_StatusSlice, String>(
          dataSource: data,
          xValueMapper: (_StatusSlice s, _) => s.label,
          yValueMapper: (_StatusSlice s, _) => s.value,
          pointColorMapper: (_StatusSlice s, _) => s.color,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          innerRadius: '55%',
          explode: true,
          explodeIndex: 0,
        ),
      ],
    );
  }

  // DTOs for charts moved to top-level

  Widget _buildRecentWorkOrders(List<WorkOrder> workOrders) {
    final recent = workOrders.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Work Orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ...recent.map(
            (wo) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(wo.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.work_outline,
                      color: _getStatusColor(wo.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wo.ticketNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          wo.problemDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(wo.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetHealth(int totalAssets, int totalWorkOrders) {
    final healthScore = totalAssets > 0
        ? ((totalAssets - (totalWorkOrders * 0.1)) / totalAssets * 100)
            .clamp(0, 100)
            .toInt()
        : 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Asset Health Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkTextColor,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: healthScore / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getHealthColor(healthScore),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$healthScore%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _getHealthColor(healthScore),
                      ),
                    ),
                    Text(
                      _getHealthLabel(healthScore),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHealthMetric('Total Assets', totalAssets.toString()),
              _buildHealthMetric('Work Orders', totalWorkOrders.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );

  Widget _buildStatusBadge(WorkOrderStatus status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status.name.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _getStatusColor(status),
          ),
        ),
      );

  Color _getStatusColor(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.open:
        return const Color(0xFF3B82F6);
      case WorkOrderStatus.assigned:
        return const Color(0xFF8B5CF6);
      case WorkOrderStatus.inProgress:
        return const Color(0xFFF59E0B);
      case WorkOrderStatus.completed:
        return const Color(0xFF10B981);
      case WorkOrderStatus.closed:
        return const Color(0xFF6B7280);
      case WorkOrderStatus.cancelled:
        return const Color(0xFF9CA3AF);
    }
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getHealthLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Needs Attention';
  }
}

// DTOs for charts (top-level)
class _DayCount {
  _DayCount({required this.date, required this.count});
  final DateTime date;
  final double count;
}

class _StatusSlice {
  _StatusSlice({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;
}
