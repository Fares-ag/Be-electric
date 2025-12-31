import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../utils/app_theme.dart';

class KPIMetricsWidget extends StatelessWidget {

  const KPIMetricsWidget({
    required this.kpiMetrics, required this.period, super.key,
  });
  final KPIMetrics kpiMetrics;
  final String period;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Key Performance Indicators',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Performance metrics for the last ${_getPeriodDisplayName(period)}',
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // KPI Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildKPICard(
                title: 'MTTR',
                value: '${kpiMetrics.mttr.toStringAsFixed(1)}h',
                subtitle: 'Mean Time To Repair',
                icon: Icons.build,
                color: _getMTTRColor(kpiMetrics.mttr),
                trend: _getMTTRTrend(kpiMetrics.mttr),
              ),
              _buildKPICard(
                title: 'MTBF',
                value: '${kpiMetrics.mtbf.toStringAsFixed(0)}h',
                subtitle: 'Mean Time Between Failures',
                icon: Icons.schedule,
                color: _getMTBFColor(kpiMetrics.mtbf),
                trend: _getMTBFTrend(kpiMetrics.mtbf),
              ),
              _buildKPICard(
                title: 'Uptime',
                value: '${kpiMetrics.assetUptime.toStringAsFixed(1)}%',
                subtitle: 'Asset Uptime',
                icon: Icons.trending_up,
                color: _getUptimeColor(kpiMetrics.assetUptime),
                trend: _getUptimeTrend(kpiMetrics.assetUptime),
              ),
              _buildKPICard(
                title: 'Efficiency',
                value: '${kpiMetrics.technicianEfficiency.toStringAsFixed(1)}%',
                subtitle: 'Technician Efficiency',
                icon: Icons.people,
                color: _getEfficiencyColor(kpiMetrics.technicianEfficiency),
                trend: _getEfficiencyTrend(kpiMetrics.technicianEfficiency),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Work Order Statistics
          _buildWorkOrderStatsCard(),

          const SizedBox(height: 16),

          // Response Time Card
          _buildResponseTimeCard(),

          const SizedBox(height: 16),

          // Performance Indicators
          _buildPerformanceIndicatorsCard(),
        ],
      ),
    );

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
  }) => Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trend != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTrendColor(trend),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trend,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildWorkOrderStatsCard() => Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Work Order Statistics',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    kpiMetrics.totalWorkOrders.toString(),
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    kpiMetrics.completedWorkOrders.toString(),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Overdue',
                    kpiMetrics.overdueWorkOrders.toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: kpiMetrics.completionRate / 100,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                kpiMetrics.completionRate >= 80
                    ? Colors.green
                    : kpiMetrics.completionRate >= 60
                        ? Colors.orange
                        : Colors.red,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              'Completion Rate: ${kpiMetrics.completionRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildStatItem(String label, String value, Color color) => Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 12,
          ),
        ),
      ],
    );

  Widget _buildResponseTimeCard() => Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response Time',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: _getResponseTimeColor(kpiMetrics.averageResponseTime),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${kpiMetrics.averageResponseTime.toStringAsFixed(1)} hours',
                        style: TextStyle(
                          color: _getResponseTimeColor(
                              kpiMetrics.averageResponseTime,),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Average response time',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildPerformanceIndicatorsCard() => Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Indicators',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPerformanceIndicator(
              'Asset Uptime',
              kpiMetrics.assetUptime,
              100,
              _getUptimeColor(kpiMetrics.assetUptime),
            ),
            const SizedBox(height: 16),
            _buildPerformanceIndicator(
              'Technician Efficiency',
              kpiMetrics.technicianEfficiency,
              100,
              _getEfficiencyColor(kpiMetrics.technicianEfficiency),
            ),
            const SizedBox(height: 16),
            _buildPerformanceIndicator(
              'Completion Rate',
              kpiMetrics.completionRate,
              100,
              kpiMetrics.completionRate >= 80
                  ? Colors.green
                  : kpiMetrics.completionRate >= 60
                      ? Colors.orange
                      : Colors.red,
            ),
          ],
        ),
      ),
    );

  Widget _buildPerformanceIndicator(
      String label, double value, double maxValue, Color color,) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: AppTheme.borderColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  // Helper methods for colors and trends
  Color _getMTTRColor(double mttr) {
    if (mttr <= 2) return Colors.green;
    if (mttr <= 4) return Colors.orange;
    return Colors.red;
  }

  Color _getMTBFColor(double mtbf) {
    if (mtbf >= 720) return Colors.green; // 30 days
    if (mtbf >= 168) return Colors.orange; // 7 days
    return Colors.red;
  }

  Color _getUptimeColor(double uptime) {
    if (uptime >= 95) return Colors.green;
    if (uptime >= 90) return Colors.orange;
    return Colors.red;
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 80) return Colors.green;
    if (efficiency >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getResponseTimeColor(double responseTime) {
    if (responseTime <= 2) return Colors.green;
    if (responseTime <= 4) return Colors.orange;
    return Colors.red;
  }

  String? _getMTTRTrend(double mttr) {
    if (mttr <= 2) return 'EXCELLENT';
    if (mttr <= 4) return 'GOOD';
    return 'NEEDS IMPROVEMENT';
  }

  String? _getMTBFTrend(double mtbf) {
    if (mtbf >= 720) return 'EXCELLENT';
    if (mtbf >= 168) return 'GOOD';
    return 'NEEDS IMPROVEMENT';
  }

  String? _getUptimeTrend(double uptime) {
    if (uptime >= 95) return 'EXCELLENT';
    if (uptime >= 90) return 'GOOD';
    return 'NEEDS IMPROVEMENT';
  }

  String? _getEfficiencyTrend(double efficiency) {
    if (efficiency >= 80) return 'EXCELLENT';
    if (efficiency >= 60) return 'GOOD';
    return 'NEEDS IMPROVEMENT';
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'EXCELLENT':
        return Colors.green;
      case 'GOOD':
        return Colors.orange;
      case 'NEEDS IMPROVEMENT':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getPeriodDisplayName(String period) {
    switch (period) {
      case 'week':
        return 'week';
      case 'month':
        return 'month';
      case 'quarter':
        return 'quarter';
      case 'year':
        return 'year';
      default:
        return 'month';
    }
  }
}





