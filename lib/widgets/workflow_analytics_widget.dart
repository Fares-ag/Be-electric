// Workflow Analytics Widget - Displays analytics cards and charts

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workflow_provider.dart';
import '../utils/app_theme.dart';

class WorkflowAnalyticsWidget extends StatelessWidget {
  const WorkflowAnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final workflowProvider = Provider.of<WorkflowProvider>(context);
    final statistics = workflowProvider.getStatistics();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workflow Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 16),

        // Key Metrics Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Completion Rate',
                '${statistics['completionRate'].toStringAsFixed(1)}%',
                Icons.check_circle,
                AppTheme.green,
                subtitle: '${statistics['completed']} / ${statistics['total']}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Approval Rate',
                '${statistics['approvalRate'].toStringAsFixed(1)}%',
                Icons.approval,
                AppTheme.blue,
                subtitle: '${statistics['approved']} approved',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Status Breakdown
        const Text(
          'Workflow Status Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusBreakdown(statistics),
        const SizedBox(height: 24),

        // Visual Progress Bars
        _buildProgressBars(statistics),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) =>
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.lightGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.lightGrey,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildStatusBreakdown(Map<String, dynamic> statistics) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusRow(
                'Pending',
                statistics['pending'],
                statistics['total'],
                AppTheme.blue,
              ),
              const Divider(height: 24),
              _buildStatusRow(
                'In Progress',
                statistics['inProgress'],
                statistics['total'],
                AppTheme.blue,
              ),
              const Divider(height: 24),
              _buildStatusRow(
                'Pending Approval',
                statistics['pendingApproval'],
                statistics['total'],
                AppTheme.orange,
              ),
              const Divider(height: 24),
              _buildStatusRow(
                'Approved',
                statistics['approved'],
                statistics['total'],
                AppTheme.green,
              ),
              const Divider(height: 24),
              _buildStatusRow(
                'Rejected',
                statistics['rejected'],
                statistics['total'],
                AppTheme.red,
              ),
              const Divider(height: 24),
              _buildStatusRow(
                'Completed',
                statistics['completed'],
                statistics['total'],
                AppTheme.green,
              ),
              if (statistics['overdue'] > 0) ...[
                const Divider(height: 24),
                _buildStatusRow(
                  'Overdue',
                  statistics['overdue'],
                  statistics['total'],
                  AppTheme.red,
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildStatusRow(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.lightGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBars(Map<String, dynamic> statistics) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Metrics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildProgressBar(
                'Completion Rate',
                statistics['completionRate'],
                AppTheme.green,
              ),
              const SizedBox(height: 16),
              _buildProgressBar(
                'Approval Rate',
                statistics['approvalRate'],
                AppTheme.blue,
              ),
              const SizedBox(height: 16),
              _buildProgressBar(
                'Workflow Efficiency',
                _calculateEfficiency(statistics),
                AppTheme.orange,
              ),
            ],
          ),
        ),
      );

  Widget _buildProgressBar(String label, double percentage, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percentage / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      );

  double _calculateEfficiency(Map<String, dynamic> statistics) {
    // Efficiency calculation: completed workflows with low rejection rate
    final total = statistics['total'] as int;
    if (total == 0) return 0;

    final completed = statistics['completed'] as int;
    final rejected = statistics['rejected'] as int;

    // Efficiency = (completed - rejected) / total * 100
    final efficiency = ((completed - rejected) / total) * 100;
    return efficiency.clamp(0.0, 100.0);
  }
}

/// Compact Workflow Statistics Card for Dashboard
class WorkflowStatsCard extends StatelessWidget {
  const WorkflowStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final workflowProvider = Provider.of<WorkflowProvider>(context);
    final statistics = workflowProvider.getStatistics();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Workflow Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactStat(
                  'Total',
                  statistics['total'].toString(),
                  Icons.layers,
                  AppTheme.blue,
                ),
                _buildCompactStat(
                  'Pending',
                  statistics['pendingApproval'].toString(),
                  Icons.pending_actions,
                  AppTheme.orange,
                ),
                _buildCompactStat(
                  'Completed',
                  statistics['completed'].toString(),
                  Icons.check_circle,
                  AppTheme.green,
                ),
                _buildCompactStat(
                  'Overdue',
                  statistics['overdue'].toString(),
                  Icons.warning,
                  AppTheme.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${statistics['completionRate'].toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.green,
                      ),
                    ),
                    const Text(
                      'Completion',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightGrey,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: AppTheme.borderColor,
                ),
                Column(
                  children: [
                    Text(
                      '${statistics['approvalRate'].toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blue,
                      ),
                    ),
                    const Text(
                      'Approval',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.lightGrey,
            ),
          ),
        ],
      );
}
