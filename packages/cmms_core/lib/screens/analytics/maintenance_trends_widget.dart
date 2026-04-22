import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../utils/app_theme.dart';

class MaintenanceTrendsWidget extends StatelessWidget {

  const MaintenanceTrendsWidget({
    required this.trends, super.key,
  });
  final MaintenanceTrends trends;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Maintenance Trends',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trend analysis and performance over time',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Trend Summary
          _buildTrendSummary(),
          const SizedBox(height: 24),

          // Weekly Trends Chart
          _buildTrendsChart('Weekly Trends', trends.weeklyData),
          const SizedBox(height: 16),

          // Monthly Trends Chart
          if (trends.monthlyData.isNotEmpty) ...[
            _buildTrendsChart('Monthly Trends', trends.monthlyData),
            const SizedBox(height: 16),
          ],

          // Trend Analysis
          _buildTrendAnalysis(),
        ],
      ),
    );

  Widget _buildTrendSummary() => Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trend Summary',
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
                  child: _buildTrendItem(
                    'Overall Trend',
                    trends.trendDescription,
                    _getTrendColor(trends.trendDirection),
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildTrendItem(
                    'Direction',
                    trends.trendDirection > 0
                        ? 'Increasing'
                        : trends.trendDirection < 0
                            ? 'Decreasing'
                            : 'Stable',
                    _getTrendColor(trends.trendDirection),
                    trends.trendDirection > 0
                        ? Icons.trending_up
                        : trends.trendDirection < 0
                            ? Icons.trending_down
                            : Icons.trending_flat,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildTrendItem(
      String label, String value, Color color, IconData icon,) => Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
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

  Widget _buildTrendsChart(String title, List<MaintenanceDataPoint> data) {
    if (data.isEmpty) {
      return Card(
        color: AppTheme.cardColor,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No $title data available',
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildSimpleChart(data),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(List<MaintenanceDataPoint> data) {
    final maxWorkOrders =
        data.map((d) => d.workOrders).reduce((a, b) => a > b ? a : b);
    final maxCompleted =
        data.map((d) => d.completed).reduce((a, b) => a > b ? a : b);
    final maxValue =
        [maxWorkOrders, maxCompleted].reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.map((point) {
        final workOrderHeight = (point.workOrders / maxValue) * 150;
        final completedHeight = (point.completed / maxValue) * 150;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Work Orders Bar
                Container(
                  height: workOrderHeight,
                  width: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.7),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Completed Bar
                Container(
                  height: completedHeight,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.7),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Date Label
                Text(
                  _formatDateLabel(point.date),
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartLegend() => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Total Work Orders', AppTheme.primaryColor),
        const SizedBox(width: 16),
        _buildLegendItem('Completed', Colors.green),
      ],
    );

  Widget _buildLegendItem(String label, Color color) => Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 12,
          ),
        ),
      ],
    );

  Widget _buildTrendAnalysis() => Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trend Analysis',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAnalysisItem(
              'Work Order Volume',
              _analyzeWorkOrderVolume(),
              Icons.assignment,
            ),
            const SizedBox(height: 12),
            _buildAnalysisItem(
              'Completion Rate',
              _analyzeCompletionRate(),
              Icons.check_circle,
            ),
            const SizedBox(height: 12),
            _buildAnalysisItem(
              'MTTR Trend',
              _analyzeMTTRTrend(),
              Icons.build,
            ),
            const SizedBox(height: 12),
            _buildAnalysisItem(
              'Recommendations',
              _getRecommendations(),
              Icons.lightbulb,
            ),
          ],
        ),
      ),
    );

  Widget _buildAnalysisItem(String title, String analysis, IconData icon) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                analysis,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );

  // Analysis methods
  String _analyzeWorkOrderVolume() {
    if (trends.weeklyData.length < 2) return 'Insufficient data for analysis';

    final recent = trends.weeklyData
            .take(4)
            .map((d) => d.workOrders)
            .reduce((a, b) => a + b) /
        4;
    final older = trends.weeklyData
            .skip(4)
            .take(4)
            .map((d) => d.workOrders)
            .reduce((a, b) => a + b) /
        4;

    final change = ((recent - older) / older * 100).abs();

    if (recent > older) {
      return 'Work order volume has increased by ${change.toStringAsFixed(1)}% in recent weeks.';
    } else if (recent < older) {
      return 'Work order volume has decreased by ${change.toStringAsFixed(1)}% in recent weeks.';
    } else {
      return 'Work order volume has remained stable.';
    }
  }

  String _analyzeCompletionRate() {
    if (trends.weeklyData.isEmpty) return 'No data available';

    final avgCompletionRate = trends.weeklyData
            .map((d) =>
                d.workOrders > 0 ? (d.completed / d.workOrders) * 100 : 0,)
            .reduce((a, b) => a + b) /
        trends.weeklyData.length;

    if (avgCompletionRate >= 90) {
      return 'Excellent completion rate of ${avgCompletionRate.toStringAsFixed(1)}%.';
    } else if (avgCompletionRate >= 70) {
      return 'Good completion rate of ${avgCompletionRate.toStringAsFixed(1)}%.';
    } else {
      return 'Completion rate of ${avgCompletionRate.toStringAsFixed(1)}% needs improvement.';
    }
  }

  String _analyzeMTTRTrend() {
    if (trends.weeklyData.length < 2) return 'Insufficient data for analysis';

    final recent =
        trends.weeklyData.take(4).map((d) => d.mttr).reduce((a, b) => a + b) /
            4;
    final older = trends.weeklyData
            .skip(4)
            .take(4)
            .map((d) => d.mttr)
            .reduce((a, b) => a + b) /
        4;

    if (recent < older) {
      return 'MTTR has improved from ${older.toStringAsFixed(1)}h to ${recent.toStringAsFixed(1)}h.';
    } else if (recent > older) {
      return 'MTTR has increased from ${older.toStringAsFixed(1)}h to ${recent.toStringAsFixed(1)}h.';
    } else {
      return 'MTTR has remained stable at ${recent.toStringAsFixed(1)}h.';
    }
  }

  String _getRecommendations() {
    if (trends.trendDirection > 0.5) {
      return 'Consider increasing preventive maintenance to reduce reactive work orders.';
    } else if (trends.trendDirection < -0.5) {
      return 'Great job! Continue current maintenance practices.';
    } else {
      return 'Monitor trends closely and adjust maintenance strategies as needed.';
    }
  }

  // Helper methods
  Color _getTrendColor(double direction) {
    if (direction > 0.5) return Colors.red;
    if (direction < -0.5) return Colors.green;
    return Colors.orange;
  }

  String _formatDateLabel(DateTime date) => '${date.month}/${date.day}';
}





