// Performance Diagnostic Screen
//
// Displays real-time performance metrics and statistics.
// Helps identify bottlenecks and optimize app performance.

import 'package:flutter/material.dart';
import 'package:qauto_cmms/utils/app_theme.dart';
import 'package:qauto_cmms/utils/performance_monitor.dart';

class PerformanceDiagnosticScreen extends StatefulWidget {
  const PerformanceDiagnosticScreen({super.key});

  @override
  State<PerformanceDiagnosticScreen> createState() =>
      _PerformanceDiagnosticScreenState();
}

class _PerformanceDiagnosticScreenState
    extends State<PerformanceDiagnosticScreen> {
  String? _selectedOperation;
  bool _showOnlySlowOps = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Performance Diagnostics'),
          backgroundColor: AppTheme.primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearDialog,
              tooltip: 'Clear Metrics',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildFilterCard(),
              const SizedBox(height: 16),
              _buildOperationsCard(),
              const SizedBox(height: 16),
              if (_selectedOperation != null) _buildOperationDetailsCard(),
            ],
          ),
        ),
      );

  Widget _buildSummaryCard() {
    final metrics = PerformanceMonitor.getMetrics();
    final operations = PerformanceMonitor.getOperations();
    final slowOps = PerformanceMonitor.getSlowOperations();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Performance Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Total Operations Tracked',
              '${metrics.length}',
              Icons.analytics,
            ),
            _buildSummaryRow(
              'Unique Operations',
              '${operations.length}',
              Icons.category,
            ),
            _buildSummaryRow(
              'Slow Operations',
              '${slowOps.length}',
              Icons.warning_amber,
              slowOps.isNotEmpty ? Colors.orange : null,
            ),
            _buildSummaryRow(
              'Threshold',
              '${PerformanceMonitor.slowOperationThreshold.inMilliseconds}ms',
              Icons.timer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_list, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Show only slow operations'),
                value: _showOnlySlowOps,
                onChanged: (value) {
                  setState(() {
                    _showOnlySlowOps = value;
                    _selectedOperation = null;
                  });
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      );

  Widget _buildOperationsCard() {
    final allStats = PerformanceMonitor.getAllStats();
    var stats = allStats.entries.toList();

    // Sort by average duration (slowest first)
    stats.sort((a, b) => b.value.avgDuration.compareTo(a.value.avgDuration));

    // Filter if needed
    if (_showOnlySlowOps) {
      stats = stats
          .where(
            (entry) =>
                entry.value.avgDuration >
                PerformanceMonitor.slowOperationThreshold,
          )
          .toList();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Operations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (stats.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No operations tracked yet'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = stats[index];
                  return _buildOperationTile(entry.key, entry.value);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationTile(String operation, PerformanceStats stats) {
    final isSlow =
        stats.avgDuration > PerformanceMonitor.slowOperationThreshold;
    final isSelected = _selectedOperation == operation;

    return ListTile(
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      leading: Icon(
        isSlow ? Icons.warning_amber : Icons.check_circle,
        color: isSlow ? Colors.orange : Colors.green,
      ),
      title: Text(
        operation,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Avg: ${stats.avgDuration.inMilliseconds}ms | '
        'Count: ${stats.count}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text('${stats.avgDuration.inMilliseconds}ms'),
            backgroundColor: isSlow
                ? Colors.orange.withValues(alpha: 0.2)
                : Colors.green.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
          Icon(isSelected ? Icons.expand_less : Icons.expand_more),
        ],
      ),
      onTap: () {
        setState(() {
          _selectedOperation = isSelected ? null : operation;
        });
      },
    );
  }

  Widget _buildOperationDetailsCard() {
    final stats = PerformanceMonitor.getStatsForOperation(_selectedOperation!);
    if (stats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedOperation!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedOperation = null),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('Total Executions', '${stats.count}'),
            _buildDetailRow(
              'Total Time',
              '${stats.totalDuration.inMilliseconds}ms',
            ),
            _buildDetailRow(
              'Average Time',
              '${stats.avgDuration.inMilliseconds}ms',
            ),
            _buildDetailRow(
              'Minimum Time',
              '${stats.minDuration.inMilliseconds}ms',
            ),
            _buildDetailRow(
              'Maximum Time',
              '${stats.maxDuration.inMilliseconds}ms',
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent Executions (last 10):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.recentDurations.map((duration) {
                final isSlow =
                    duration > PerformanceMonitor.slowOperationThreshold;
                return Chip(
                  label: Text('${duration.inMilliseconds}ms'),
                  backgroundColor:
                      isSlow ? Colors.orange.withValues(alpha: 0.2) : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Performance Metrics'),
        content: const Text(
          'Are you sure you want to clear all performance metrics? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              PerformanceMonitor.clear();
              Navigator.pop(context);
              setState(() {
                _selectedOperation = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Performance metrics cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }
}
