import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../utils/app_theme.dart';

class TechnicianPerformanceWidget extends StatelessWidget {
  const TechnicianPerformanceWidget({
    required this.technicianPerformance,
    super.key,
  });
  final List<TechnicianPerformance> technicianPerformance;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Technician Performance',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Performance metrics for ${technicianPerformance.length} technicians',
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Performance Summary Cards
            if (technicianPerformance.isNotEmpty) ...[
              _buildPerformanceSummary(),
              const SizedBox(height: 24),
            ],

            // Technician List
            if (technicianPerformance.isEmpty)
              const Center(
                child: Text(
                  'No technician performance data available',
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
                itemCount: technicianPerformance.length,
                itemBuilder: (context, index) {
                  final technician = technicianPerformance[index];
                  return _buildTechnicianCard(technician);
                },
              ),
          ],
        ),
      );

  Widget _buildPerformanceSummary() {
    final avgEfficiency = technicianPerformance
            .map((t) => t.efficiencyScore)
            .reduce((a, b) => a + b) /
        technicianPerformance.length;

    final avgCompletionRate = technicianPerformance
            .map((t) => t.completionRate)
            .reduce((a, b) => a + b) /
        technicianPerformance.length;

    final totalWorkOrders = technicianPerformance
        .map((t) => t.totalWorkOrders)
        .reduce((a, b) => a + b);

    final totalCompleted = technicianPerformance
        .map((t) => t.completedWorkOrders)
        .reduce((a, b) => a + b);

    return Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Performance Summary',
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
                    'Avg Efficiency',
                    '${avgEfficiency.toStringAsFixed(1)}%',
                    _getEfficiencyColor(avgEfficiency),
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Avg Completion',
                    '${avgCompletionRate.toStringAsFixed(1)}%',
                    _getCompletionColor(avgCompletionRate),
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Work Orders',
                    totalWorkOrders.toString(),
                    AppTheme.primaryColor,
                    Icons.assignment,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Completed',
                    totalCompleted.toString(),
                    Colors.green,
                    Icons.done_all,
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

  Widget _buildTechnicianCard(TechnicianPerformance technician) => Card(
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
                  CircleAvatar(
                    backgroundColor:
                        _getEfficiencyColor(technician.efficiencyScore),
                    child: Text(
                      technician.technicianName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technician.technicianName,
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last activity: ${technician.lastActivity != null ? _formatDate(technician.lastActivity!) : 'Never'}',
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
                      color: _getEfficiencyColor(technician.efficiencyScore),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${technician.efficiencyScore.toStringAsFixed(0)}%',
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

              // Work Order Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      technician.totalWorkOrders.toString(),
                      AppTheme.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Completed',
                      technician.completedWorkOrders.toString(),
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Overdue',
                      technician.overdueWorkOrders.toString(),
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Performance Indicators
              _buildPerformanceIndicator(
                'Completion Rate',
                technician.completionRate,
                100,
                _getCompletionColor(technician.completionRate),
              ),
              const SizedBox(height: 12),
              _buildPerformanceIndicator(
                'Efficiency Score',
                technician.efficiencyScore,
                100,
                _getEfficiencyColor(technician.efficiencyScore),
              ),
              const SizedBox(height: 16),

              // Time Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildTimeMetric(
                      'Avg Completion Time',
                      '${technician.averageCompletionTime.toStringAsFixed(1)}h',
                      Icons.timer,
                    ),
                  ),
                  Expanded(
                    child: _buildTimeMetric(
                      'Avg Response Time',
                      '${technician.averageResponseTime.toStringAsFixed(1)}h',
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Specializations
              if (technician.specializations.isNotEmpty) ...[
                const Text(
                  'Specializations:',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: technician.specializations
                      .map(
                        (spec) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            spec,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
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

  Widget _buildTimeMetric(String label, String value, IconData icon) => Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColor,
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

  // Helper methods
  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 80) return Colors.green;
    if (efficiency >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getCompletionColor(double completion) {
    if (completion >= 90) return Colors.green;
    if (completion >= 70) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
