import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../utils/app_theme.dart';

class CostAnalysisWidget extends StatelessWidget {
  const CostAnalysisWidget({
    required this.costAnalysis,
    super.key,
  });
  final CostAnalysis costAnalysis;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Cost Analysis',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Maintenance cost breakdown and analysis',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Total Cost Summary
            _buildTotalCostSummary(),
            const SizedBox(height: 16),

            // Cost Breakdown
            _buildCostBreakdown(),
            const SizedBox(height: 16),

            // Cost by Category
            _buildCostByCategory(),
            const SizedBox(height: 16),

            // Cost Efficiency Metrics
            _buildCostEfficiencyMetrics(),
          ],
        ),
      );

  Widget _buildTotalCostSummary() => Card(
        color: AppTheme.cardColor,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Maintenance Cost',
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
                    child: Column(
                      children: [
                        Text(
                          'QAR ${costAnalysis.totalMaintenanceCost.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total Cost',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'QAR ${costAnalysis.downtimeCost.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Downtime Cost',
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

  Widget _buildCostBreakdown() => Card(
        color: AppTheme.cardColor,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cost Breakdown',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCostItem(
                'Labor Cost',
                costAnalysis.laborCost,
                costAnalysis.totalMaintenanceCost,
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildCostItem(
                'Parts Cost',
                costAnalysis.partsCost,
                costAnalysis.totalMaintenanceCost,
                Icons.build,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildCostItem(
                'Downtime Cost',
                costAnalysis.downtimeCost,
                costAnalysis.totalMaintenanceCost,
                Icons.schedule,
                Colors.red,
              ),
              const SizedBox(height: 16),
              _buildCostComparison(),
            ],
          ),
        ),
      );

  Widget _buildCostItem(
    String label,
    double cost,
    double totalCost,
    IconData icon,
    Color color,
  ) {
    final percentage = totalCost > 0 ? (cost / totalCost) * 100 : 0;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              'QAR ${cost.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppTheme.borderColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildCostComparison() {
    final preventivePercentage = costAnalysis.totalMaintenanceCost > 0
        ? (costAnalysis.preventiveMaintenanceCost /
                costAnalysis.totalMaintenanceCost) *
            100
        : 0.0;
    final reactivePercentage = costAnalysis.totalMaintenanceCost > 0
        ? (costAnalysis.reactiveMaintenanceCost /
                costAnalysis.totalMaintenanceCost) *
            100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preventive vs Reactive',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildComparisonItem(
                'Preventive',
                costAnalysis.preventiveMaintenanceCost,
                preventivePercentage,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildComparisonItem(
                'Reactive',
                costAnalysis.reactiveMaintenanceCost,
                reactivePercentage,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonItem(
    String label,
    double cost,
    double percentage,
    Color color,
  ) =>
      Column(
        children: [
          Text(
            'QAR ${cost.toStringAsFixed(0)}',
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
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  Widget _buildCostByCategory() {
    if (costAnalysis.costByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cost by Category',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...costAnalysis.costByCategory.entries.map((entry) {
              final percentage = costAnalysis.totalMaintenanceCost > 0
                  ? (entry.value / costAnalysis.totalMaintenanceCost) * 100
                  : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          'QAR ${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: AppTheme.borderColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                      minHeight: 4,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCostEfficiencyMetrics() => Card(
        color: AppTheme.cardColor,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cost Efficiency Metrics',
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
                    child: _buildEfficiencyMetric(
                      'Cost per Asset',
                      'QAR ${costAnalysis.costPerAsset.toStringAsFixed(0)}',
                      Icons.build,
                      _getCostPerAssetColor(costAnalysis.costPerAsset),
                    ),
                  ),
                  Expanded(
                    child: _buildEfficiencyMetric(
                      'Cost per Work Order',
                      'QAR ${costAnalysis.costPerWorkOrder.toStringAsFixed(0)}',
                      Icons.assignment,
                      _getCostPerWorkOrderColor(costAnalysis.costPerWorkOrder),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCostEfficiencyAnalysis(),
            ],
          ),
        ),
      );

  Widget _buildEfficiencyMetric(
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

  Widget _buildCostEfficiencyAnalysis() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost Efficiency Analysis',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnalysisItem(
            'Preventive vs Reactive Ratio',
            _getPreventiveReactiveAnalysis(),
            Icons.balance,
          ),
          const SizedBox(height: 8),
          _buildAnalysisItem(
            'Downtime Impact',
            _getDowntimeAnalysis(),
            Icons.schedule,
          ),
          const SizedBox(height: 8),
          _buildAnalysisItem(
            'Cost Optimization',
            _getCostOptimizationRecommendations(),
            Icons.lightbulb,
          ),
        ],
      );

  Widget _buildAnalysisItem(String title, String analysis, IconData icon) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  analysis,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  // Analysis methods
  String _getPreventiveReactiveAnalysis() {
    final preventivePercentage = costAnalysis.totalMaintenanceCost > 0
        ? (costAnalysis.preventiveMaintenanceCost /
                costAnalysis.totalMaintenanceCost) *
            100
        : 0;

    if (preventivePercentage >= 70) {
      return 'Excellent preventive maintenance ratio.';
    } else if (preventivePercentage >= 50) {
      return 'Good preventive maintenance ratio.';
    } else {
      return 'Consider increasing preventive maintenance.';
    }
  }

  String _getDowntimeAnalysis() {
    final downtimePercentage = costAnalysis.totalMaintenanceCost > 0
        ? (costAnalysis.downtimeCost / costAnalysis.totalMaintenanceCost) * 100
        : 0;

    if (downtimePercentage <= 20) {
      return 'Low downtime cost impact.';
    } else if (downtimePercentage <= 40) {
      return 'Moderate downtime cost impact.';
    } else {
      return 'High downtime cost impact - focus on reliability.';
    }
  }

  String _getCostOptimizationRecommendations() {
    final preventivePercentage = costAnalysis.totalMaintenanceCost > 0
        ? (costAnalysis.preventiveMaintenanceCost /
                costAnalysis.totalMaintenanceCost) *
            100
        : 0;

    if (preventivePercentage < 50) {
      return 'Increase preventive maintenance to reduce reactive costs.';
    } else if (costAnalysis.costPerWorkOrder > 200) {
      return 'Review work order processes for efficiency gains.';
    } else {
      return 'Cost structure is well optimized.';
    }
  }

  // Helper methods for colors
  Color _getCostPerAssetColor(double cost) {
    if (cost <= 1000) return Colors.green;
    if (cost <= 2000) return Colors.orange;
    return Colors.red;
  }

  Color _getCostPerWorkOrderColor(double cost) {
    if (cost <= 150) return Colors.green;
    if (cost <= 250) return Colors.orange;
    return Colors.red;
  }
}
