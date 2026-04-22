import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../utils/app_theme.dart';

class AssetPerformanceWidget extends StatelessWidget {
  const AssetPerformanceWidget({
    required this.assetPerformance,
    super.key,
  });
  final List<AssetPerformance> assetPerformance;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Asset Performance',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Performance metrics for ${assetPerformance.length} assets',
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Performance Summary
            if (assetPerformance.isNotEmpty) ...[
              _buildPerformanceSummary(),
              const SizedBox(height: 24),
            ],

            // Asset List
            if (assetPerformance.isEmpty)
              const Center(
                child: Text(
                  'No asset performance data available',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 16,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assetPerformance.length,
                itemBuilder: (context, index) {
                  final asset = assetPerformance[index];
                  return _buildAssetCard(asset);
                },
              ),
          ],
        ),
      );

  Widget _buildPerformanceSummary() {
    final avgUptime =
        assetPerformance.map((a) => a.uptime).reduce((a, b) => a + b) /
            assetPerformance.length;

    final totalFailures =
        assetPerformance.map((a) => a.totalFailures).reduce((a, b) => a + b);

    final totalDowntimeCost =
        assetPerformance.map((a) => a.costOfDowntime).reduce((a, b) => a + b);

    return Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asset Performance Summary',
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
                  child: _buildSummaryItem(
                    'Avg Uptime',
                    '${avgUptime.toStringAsFixed(1)}%',
                    _getUptimeColor(avgUptime),
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Failures',
                    totalFailures.toString(),
                    Colors.red,
                    Icons.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Downtime Cost',
                    'QAR ${totalDowntimeCost.toStringAsFixed(0)}',
                    Colors.orange,
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Assets Monitored',
                    assetPerformance.length.toString(),
                    AppTheme.primaryColor,
                    Icons.build,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) =>
      Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
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
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildAssetCard(AssetPerformance asset) => Card(
        color: AppTheme.cardColor,
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getUptimeColor(asset.uptime),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.build,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.assetName,
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          asset.category ?? 'Unknown',
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getUptimeColor(asset.uptime),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${asset.uptime.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Performance Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Failures',
                      asset.totalFailures.toString(),
                      Colors.red,
                      Icons.warning,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      'Critical',
                      asset.criticalFailures.toString(),
                      Colors.red,
                      Icons.error,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      'MTBF',
                      '${asset.mtbf.toStringAsFixed(0)}h',
                      AppTheme.primaryColor,
                      Icons.schedule,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      'MTTR',
                      '${asset.mttr.toStringAsFixed(1)}h',
                      Colors.orange,
                      Icons.build,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Uptime Indicator
              _buildPerformanceIndicator(
                'Uptime',
                asset.uptime,
                100,
                _getUptimeColor(asset.uptime),
              ),
              const SizedBox(height: 16),

              // Cost and Time Information
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Downtime Cost',
                      'QAR ${asset.costOfDowntime.toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Last Failure',
                      asset.lastFailure != null
                          ? _formatDate(asset.lastFailure!)
                          : 'N/A',
                      Icons.history,
                      AppTheme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Next Maintenance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Next Maintenance: ',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      asset.nextMaintenance != null
                          ? _formatDate(asset.nextMaintenance!)
                          : 'N/A',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMetricItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) =>
      Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildPerformanceIndicator(
    String label,
    double value,
    double maxValue,
    Color color,
  ) {
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
                fontSize: 12,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: AppTheme.borderColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  // Helper methods
  Color _getUptimeColor(double uptime) {
    if (uptime >= 95) return Colors.green;
    if (uptime >= 90) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Overdue';
    }
  }
}
