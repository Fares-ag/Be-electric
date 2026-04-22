import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class PredictiveInsightsWidget extends StatelessWidget {
  const PredictiveInsightsWidget({
    required this.insights,
    super.key,
  });
  final Map<String, dynamic> insights;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Predictive Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildFailurePredictionCard(context),
          const SizedBox(height: 16),
          _buildMaintenanceOptimizationCard(context),
          const SizedBox(height: 16),
          _buildCostForecastingCard(context),
          const SizedBox(height: 16),
          _buildResourcePlanningCard(context),
        ],
      );

  Widget _buildFailurePredictionCard(BuildContext context) {
    final failureData =
        insights['failurePrediction'] as Map<String, dynamic>? ?? {};
    final highRiskAssets = failureData['highRiskAssets'] as List? ?? [];
    final totalPredictions = failureData['totalPredictions'] as int? ?? 0;
    final averageRiskLevel = failureData['averageRiskLevel'] as double? ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Failure Prediction',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'High Risk Assets',
                    totalPredictions.toString(),
                    Icons.dangerous,
                    totalPredictions > 0
                        ? AppTheme.accentRed
                        : AppTheme.accentGreen,
                  ),
                ),
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'Avg Risk Level',
                    '${averageRiskLevel.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    _getRiskColor(averageRiskLevel),
                  ),
                ),
              ],
            ),
            if (highRiskAssets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Assets at Risk:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...highRiskAssets
                  .take(3)
                  .map((asset) => _buildRiskAssetItem(context, asset)),
              if (highRiskAssets.length > 3)
                Text(
                  '... and ${highRiskAssets.length - 3} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textColor.withOpacity(0.7),
                      ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceOptimizationCard(BuildContext context) {
    final optimizationData =
        insights['maintenanceOptimization'] as Map<String, dynamic>? ?? {};
    final optimizations = optimizationData['optimizations'] as List? ?? [];
    final totalSavings = optimizationData['totalSavings'] as double? ?? 0.0;
    final assetsOptimized = optimizationData['assetsOptimized'] as int? ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.engineering, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Maintenance Optimization',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'Assets Optimized',
                    assetsOptimized.toString(),
                    Icons.tune,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'Potential Savings',
                    'QAR ${totalSavings.toStringAsFixed(0)}',
                    Icons.savings,
                    AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
            if (optimizations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Top Optimizations:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...optimizations
                  .take(3)
                  .map((opt) => _buildOptimizationItem(context, opt)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostForecastingCard(BuildContext context) {
    final costData = insights['costForecasting'] as Map<String, dynamic>? ?? {};
    final monthlyForecast = costData['monthlyForecast'] as double? ?? 0.0;
    final quarterlyForecast = costData['quarterlyForecast'] as double? ?? 0.0;
    final yearlyForecast = costData['yearlyForecast'] as double? ?? 0.0;
    final trend = costData['trend'] as String? ?? 'stable';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppTheme.accentGreen),
                const SizedBox(width: 8),
                Text(
                  'Cost Forecasting',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'Monthly',
                    'QAR ${monthlyForecast.toStringAsFixed(0)}',
                    Icons.calendar_month,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'Quarterly',
                    'QAR ${quarterlyForecast.toStringAsFixed(0)}',
                    Icons.calendar_view_month,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'Yearly',
                    'QAR ${yearlyForecast.toStringAsFixed(0)}',
                    Icons.calendar_today,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getTrendIcon(trend),
                  color: _getTrendColor(trend),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trend: ${trend.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getTrendColor(trend),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcePlanningCard(BuildContext context) {
    final resourceData =
        insights['resourcePlanning'] as Map<String, dynamic>? ?? {};
    final openWorkOrders = resourceData['openWorkOrders'] as int? ?? 0;
    final inProgressWorkOrders =
        resourceData['inProgressWorkOrders'] as int? ?? 0;
    final estimatedCompletionTime =
        resourceData['estimatedCompletionTime'] as double? ?? 0.0;
    final resourceUtilization =
        resourceData['resourceUtilization'] as double? ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Resource Planning',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'Open Orders',
                    openWorkOrders.toString(),
                    Icons.assignment,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'In Progress',
                    inProgressWorkOrders.toString(),
                    Icons.work,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildPredictionStat(
                    context,
                    'Utilization',
                    '${resourceUtilization.toStringAsFixed(1)}%',
                    Icons.person,
                    _getUtilizationColor(resourceUtilization),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Est. Completion: ${estimatedCompletionTime.toStringAsFixed(1)} hours',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textColor.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildRiskAssetItem(BuildContext context, Map<String, dynamic> asset) {
    final assetId = asset['assetId'] as String? ?? 'Unknown';
    final daysUntilFailure = asset['daysUntilFailure'] as int? ?? 0;
    final riskLevel = asset['riskLevel'] as double? ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: _getRiskColor(riskLevel),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Asset $assetId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            '$daysUntilFailure days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getRiskColor(riskLevel),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationItem(
    BuildContext context,
    Map<String, dynamic> optimization,
  ) {
    final assetId = optimization['assetId'] as String? ?? 'Unknown';
    final savings = optimization['savings'] as double? ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.tune, color: AppTheme.primaryColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Asset $assetId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            'QAR ${savings.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(double riskLevel) {
    if (riskLevel >= 80) return AppTheme.accentRed;
    if (riskLevel >= 60) return Colors.orange;
    if (riskLevel >= 40) return Colors.yellow[700]!;
    return AppTheme.accentGreen;
  }

  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'increasing':
        return AppTheme.accentRed;
      case 'decreasing':
        return AppTheme.accentGreen;
      case 'stable':
        return Colors.blue;
      default:
        return AppTheme.textColor;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'increasing':
        return Icons.trending_up;
      case 'decreasing':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }

  Color _getUtilizationColor(double utilization) {
    if (utilization >= 90) return AppTheme.accentRed;
    if (utilization >= 70) return Colors.orange;
    if (utilization >= 50) return Colors.yellow[700]!;
    return AppTheme.accentGreen;
  }
}
