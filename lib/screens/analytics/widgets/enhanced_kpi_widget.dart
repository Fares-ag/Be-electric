import 'package:flutter/material.dart';
import '../../../models/analytics_models.dart';
import '../../../utils/app_theme.dart';

class EnhancedKPIWidget extends StatelessWidget {
  const EnhancedKPIWidget({
    required this.kpiMetrics,
    super.key,
  });
  final KPIMetrics kpiMetrics;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Performance Indicators',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildKPICard(
                context,
                'MTTR',
                '${kpiMetrics.mttr.toStringAsFixed(1)}h',
                'Mean Time To Repair',
                Icons.build,
                _getMTTRColor(kpiMetrics.mttr),
              ),
              _buildKPICard(
                context,
                'MTBF',
                '${kpiMetrics.mtbf.toStringAsFixed(1)}h',
                'Mean Time Between Failures',
                Icons.schedule,
                _getMTBFColor(kpiMetrics.mtbf),
              ),
              _buildKPICard(
                context,
                'Asset Uptime',
                '${kpiMetrics.assetUptime.toStringAsFixed(1)}%',
                'Overall Asset Availability',
                Icons.offline_bolt,
                _getUptimeColor(kpiMetrics.assetUptime),
              ),
              _buildKPICard(
                context,
                'Completion Rate',
                '${kpiMetrics.completionRate.toStringAsFixed(1)}%',
                'Work Order Completion',
                Icons.check_circle,
                _getCompletionColor(kpiMetrics.completionRate),
              ),
              _buildKPICard(
                context,
                'Response Time',
                '${kpiMetrics.averageResponseTime.toStringAsFixed(1)}h',
                'Average Response Time',
                Icons.timer,
                _getResponseTimeColor(kpiMetrics.averageResponseTime),
              ),
              _buildKPICard(
                context,
                'Technician Efficiency',
                '${kpiMetrics.technicianEfficiency.toStringAsFixed(1)}%',
                'Overall Technician Performance',
                Icons.person,
                _getEfficiencyColor(kpiMetrics.technicianEfficiency),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildWorkOrderStats(context),
          const SizedBox(height: 24),
          _buildPerformanceInsights(context),
        ],
      );

  Widget _buildKPICard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) =>
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textColor.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildWorkOrderStats(BuildContext context) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Work Order Statistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Total',
                      kpiMetrics.totalWorkOrders.toString(),
                      Icons.assignment,
                      AppTheme.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Completed',
                      kpiMetrics.completedWorkOrders.toString(),
                      Icons.check_circle,
                      AppTheme.accentGreen,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Overdue',
                      kpiMetrics.overdueWorkOrders.toString(),
                      Icons.warning,
                      AppTheme.accentRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textColor.withOpacity(0.7),
                ),
          ),
        ],
      );

  Widget _buildPerformanceInsights(BuildContext context) {
    final insights = <String>[];

    // Generate insights based on KPI values
    if (kpiMetrics.mttr < 4) {
      insights.add('âœ… Excellent repair times - MTTR is below 4 hours');
    } else if (kpiMetrics.mttr > 8) {
      insights.add('âš ï¸ Repair times need improvement - MTTR is above 8 hours');
    }

    if (kpiMetrics.assetUptime > 95) {
      insights.add('âœ… Outstanding asset availability - above 95%');
    } else if (kpiMetrics.assetUptime < 85) {
      insights.add('âš ï¸ Asset uptime needs attention - below 85%');
    }

    if (kpiMetrics.completionRate > 90) {
      insights.add('âœ… High work order completion rate');
    } else if (kpiMetrics.completionRate < 70) {
      insights.add('âš ï¸ Work order completion rate needs improvement');
    }

    if (kpiMetrics.technicianEfficiency > 80) {
      insights.add('âœ… Good technician efficiency levels');
    } else if (kpiMetrics.technicianEfficiency < 60) {
      insights.add('âš ï¸ Technician efficiency needs improvement');
    }

    if (insights.isEmpty) {
      insights.add('ðŸ“Š Performance metrics are within normal ranges');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMTTRColor(double mttr) {
    if (mttr <= 4) return AppTheme.accentGreen;
    if (mttr <= 8) return Colors.orange;
    return AppTheme.accentRed;
  }

  Color _getMTBFColor(double mtbf) {
    if (mtbf >= 720) return AppTheme.accentGreen; // 30 days
    if (mtbf >= 168) return Colors.orange; // 7 days
    return AppTheme.accentRed;
  }

  Color _getUptimeColor(double uptime) {
    if (uptime >= 95) return AppTheme.accentGreen;
    if (uptime >= 85) return Colors.orange;
    return AppTheme.accentRed;
  }

  Color _getCompletionColor(double completion) {
    if (completion >= 90) return AppTheme.accentGreen;
    if (completion >= 70) return Colors.orange;
    return AppTheme.accentRed;
  }

  Color _getResponseTimeColor(double responseTime) {
    if (responseTime <= 2) return AppTheme.accentGreen;
    if (responseTime <= 4) return Colors.orange;
    return AppTheme.accentRed;
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 80) return AppTheme.accentGreen;
    if (efficiency >= 60) return Colors.orange;
    return AppTheme.accentRed;
  }
}
