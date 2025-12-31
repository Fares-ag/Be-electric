import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class SystemHealthWidget extends StatelessWidget {
  const SystemHealthWidget({
    required this.systemHealth,
    super.key,
  });
  final Map<String, dynamic> systemHealth;

  @override
  Widget build(BuildContext context) {
    final overallHealth = systemHealth['overallHealth'] as double? ?? 0.0;
    final healthStatus = systemHealth['healthStatus'] as String? ?? 'unknown';
    final dataQuality = systemHealth['dataQuality'] as double? ?? 0.0;
    final kpiHealth = systemHealth['kpiHealth'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Health',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildOverallHealthCard(context, overallHealth, healthStatus),
        const SizedBox(height: 16),
        _buildHealthMetricsCard(context, dataQuality, kpiHealth),
        const SizedBox(height: 16),
        _buildHealthRecommendations(context, overallHealth, healthStatus),
      ],
    );
  }

  Widget _buildOverallHealthCard(
    BuildContext context,
    double overallHealth,
    String healthStatus,
  ) {
    final color = _getHealthColor(overallHealth);
    final statusIcon = _getHealthIcon(healthStatus);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: color, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      healthStatus.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'System Health',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              value: overallHealth / 100,
              strokeWidth: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 16),
            Text(
              '${overallHealth.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricsCard(
    BuildContext context,
    double dataQuality,
    Map<String, dynamic> kpiHealth,
  ) {
    final completionRate = kpiHealth['completionRate'] as double? ?? 0.0;
    final assetUptime = kpiHealth['assetUptime'] as double? ?? 0.0;
    final technicianEfficiency =
        kpiHealth['technicianEfficiency'] as double? ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildHealthMetric(
              context,
              'Data Quality',
              dataQuality,
              Icons.verified_user,
              _getHealthColor(dataQuality),
            ),
            _buildHealthMetric(
              context,
              'Completion Rate',
              completionRate,
              Icons.check_circle,
              _getHealthColor(completionRate),
            ),
            _buildHealthMetric(
              context,
              'Asset Uptime',
              assetUptime,
              Icons.offline_bolt,
              _getHealthColor(assetUptime),
            ),
            _buildHealthMetric(
              context,
              'Technician Efficiency',
              technicianEfficiency,
              Icons.person,
              _getHealthColor(technicianEfficiency),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(
    BuildContext context,
    String label,
    double value,
    IconData icon,
    Color color,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${value.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: value / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildHealthRecommendations(
    BuildContext context,
    double overallHealth,
    String healthStatus,
  ) {
    final recommendations = <String>[];

    // Generate recommendations based on health status
    if (overallHealth < 60) {
      recommendations.addAll([
        'ðŸš¨ Critical: Immediate action required to improve system health',
        'ðŸ“Š Review data quality issues and fix incomplete records',
        'ðŸ”§ Address overdue work orders and improve completion rates',
        'ðŸ‘¥ Provide additional training for technicians',
        'ðŸ“ˆ Implement preventive maintenance strategies',
      ]);
    } else if (overallHealth < 80) {
      recommendations.addAll([
        'âš ï¸ System health needs attention',
        'ðŸ“Š Focus on improving data quality and completeness',
        'ðŸ”§ Optimize work order processes',
        'ðŸ“ˆ Increase preventive maintenance activities',
      ]);
    } else if (overallHealth < 90) {
      recommendations.addAll([
        'âœ… Good system health with room for improvement',
        'ðŸ“Š Continue monitoring data quality',
        'ðŸ”§ Fine-tune maintenance processes',
        'ðŸ“ˆ Consider predictive maintenance strategies',
      ]);
    } else {
      recommendations.addAll([
        'ðŸŽ‰ Excellent system health!',
        'ðŸ“Š Continue current data quality practices',
        'ðŸ”§ Maintain current maintenance processes',
        'ðŸ“ˆ Consider advanced analytics and optimization',
      ]);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...recommendations.map(
              (recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
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

  Color _getHealthColor(double value) {
    if (value >= 90) return AppTheme.accentGreen;
    if (value >= 80) return Colors.lightGreen;
    if (value >= 70) return Colors.orange;
    if (value >= 60) return Colors.deepOrange;
    return AppTheme.accentRed;
  }

  IconData _getHealthIcon(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Icons.health_and_safety;
      case 'good':
        return Icons.check_circle;
      case 'fair':
        return Icons.warning;
      case 'poor':
        return Icons.error;
      case 'critical':
        return Icons.dangerous;
      default:
        return Icons.help_outline;
    }
  }
}
