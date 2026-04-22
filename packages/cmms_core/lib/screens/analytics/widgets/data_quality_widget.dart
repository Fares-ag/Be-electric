import 'package:flutter/material.dart';
import '../../../services/data_quality_service.dart';
import '../../../utils/app_theme.dart';

class DataQualityWidget extends StatelessWidget {
  const DataQualityWidget({
    required this.qualityReport,
    super.key,
  });
  final DataQualityReport qualityReport;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Quality Report',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildQualityScoreCard(context),
          const SizedBox(height: 16),
          _buildQualityMetrics(context),
          const SizedBox(height: 16),
          _buildQualityInsights(context),
        ],
      );

  Widget _buildQualityScoreCard(BuildContext context) {
    final score = qualityReport.accuracyScore;
    final color = _getQualityColor(score);
    final status = _getQualityStatus(score);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 16),
            Text(
              '${score.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              status,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data Quality Score',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityMetrics(BuildContext context) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quality Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildMetricRow(
                context,
                'Total Records',
                qualityReport.totalRecords.toString(),
                Icons.storage,
                AppTheme.primaryColor,
              ),
              _buildMetricRow(
                context,
                'Incomplete Records',
                qualityReport.incompleteRecords.toString(),
                Icons.error_outline,
                qualityReport.incompleteRecords > 0
                    ? AppTheme.accentRed
                    : AppTheme.accentGreen,
              ),
              _buildMetricRow(
                context,
                'Duplicate Records',
                qualityReport.duplicateRecords.toString(),
                Icons.copy,
                qualityReport.duplicateRecords > 0
                    ? Colors.orange
                    : AppTheme.accentGreen,
              ),
              _buildMetricRow(
                context,
                'Outlier Records',
                qualityReport.outlierRecords.toString(),
                Icons.trending_up,
                qualityReport.outlierRecords > 0
                    ? Colors.orange
                    : AppTheme.accentGreen,
              ),
              _buildMetricRow(
                context,
                'Data Freshness',
                '${qualityReport.dataFreshness.toStringAsFixed(1)}%',
                Icons.schedule,
                _getFreshnessColor(qualityReport.dataFreshness),
              ),
            ],
          ),
        ),
      );

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
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
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );

  Widget _buildQualityInsights(BuildContext context) {
    final insights = <String>[];

    // Generate insights based on quality metrics
    if (qualityReport.accuracyScore >= 90) {
      insights.add('âœ… Excellent data quality - all systems performing well');
    } else if (qualityReport.accuracyScore >= 80) {
      insights.add('âœ… Good data quality with minor issues to address');
    } else if (qualityReport.accuracyScore >= 70) {
      insights.add('âš ï¸ Data quality needs attention - several issues detected');
    } else {
      insights.add('ðŸš¨ Poor data quality - immediate action required');
    }

    if (qualityReport.incompleteRecords > 0) {
      insights.add(
        'âš ï¸ ${qualityReport.incompleteRecords} incomplete records need attention',
      );
    }

    if (qualityReport.duplicateRecords > 0) {
      insights.add(
        'âš ï¸ ${qualityReport.duplicateRecords} duplicate records detected',
      );
    }

    if (qualityReport.outlierRecords > 0) {
      insights.add(
        'âš ï¸ ${qualityReport.outlierRecords} outlier records may need review',
      );
    }

    if (qualityReport.dataFreshness < 80) {
      insights.add(
        'âš ï¸ Data freshness is below 80% - consider more frequent updates',
      );
    }

    if (insights.length == 1 && insights.first.contains('Excellent')) {
      insights.add('ðŸ“Š All quality metrics are within acceptable ranges');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quality Insights',
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

  Color _getQualityColor(double score) {
    if (score >= 90) return AppTheme.accentGreen;
    if (score >= 80) return Colors.orange;
    if (score >= 70) return Colors.deepOrange;
    return AppTheme.accentRed;
  }

  String _getQualityStatus(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Fair';
    if (score >= 60) return 'Poor';
    return 'Critical';
  }

  Color _getFreshnessColor(double freshness) {
    if (freshness >= 90) return AppTheme.accentGreen;
    if (freshness >= 80) return Colors.orange;
    return AppTheme.accentRed;
  }
}
