import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/work_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/unified_data_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class RequestorAnalyticsScreen extends StatelessWidget {
  const RequestorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFE5E7EB),
        appBar: const CustomAppBar(
          title: 'My Analytics',
          showMenu: false,
        ),
        body: Consumer<UnifiedDataProvider>(
          builder: (context, unifiedProvider, child) {
            final currentUser =
                Provider.of<AuthProvider>(context, listen: false).currentUser;
            if (currentUser == null) {
              return const Center(child: Text('Not logged in'));
            }

            final myWorkOrders = unifiedProvider.workOrders
                .where((wo) => wo.requestorId == currentUser.id)
                .toList();

            return RefreshIndicator(
              onRefresh: () => unifiedProvider.refreshAll(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverviewStats(myWorkOrders),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildStatusBreakdown(myWorkOrders),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildPriorityBreakdown(myWorkOrders),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildPerformanceMetrics(myWorkOrders),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildRecentTrends(myWorkOrders),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildTopAssets(myWorkOrders, unifiedProvider),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _buildOverviewStats(List<WorkOrder> workOrders) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: AppTheme.heading1.copyWith(
                  color: AppTheme.darkTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Requests',
                      workOrders.length.toString(),
                      Icons.assignment,
                      const Color(0xFF002911), // Be Electric green
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildStatCard(
                      'Completed',
                      workOrders
                          .where((wo) => wo.status == WorkOrderStatus.completed)
                          .length
                          .toString(),
                      Icons.check_circle,
                      const Color(0xFF002911), // Be Electric green
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'In Progress',
                      workOrders
                          .where((wo) => wo.status == WorkOrderStatus.inProgress)
                          .length
                          .toString(),
                      Icons.work,
                      AppTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      workOrders
                          .where((wo) => wo.status == WorkOrderStatus.open ||
                              wo.status == WorkOrderStatus.assigned)
                          .length
                          .toString(),
                      Icons.pending,
                      AppTheme.disabledColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              value,
              style: AppTheme.heading1.copyWith(color: color),
            ),
            Text(
              title,
              style: AppTheme.smallText.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildStatusBreakdown(List<WorkOrder> workOrders) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Breakdown',
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.darkTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              ...WorkOrderStatus.values.map((status) {
                final count =
                    workOrders.where((wo) => wo.status == status).length;
                if (count == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          _getStatusText(status),
                          style: AppTheme.bodyText,
                        ),
                      ),
                      Text(
                        count.toString(),
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );

  Widget _buildPriorityBreakdown(List<WorkOrder> workOrders) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Priority Breakdown',
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.darkTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              ...WorkOrderPriority.values.map((priority) {
                final count =
                    workOrders.where((wo) => wo.priority == priority).length;
                if (count == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: Row(
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        size: 16,
                        color: _getPriorityColor(priority),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          priority.name.toUpperCase(),
                          style: AppTheme.bodyText,
                        ),
                      ),
                      Text(
                        count.toString(),
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(priority),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );

  Widget _buildPerformanceMetrics(List<WorkOrder> workOrders) {
    final completedOrders = workOrders
        .where((wo) => wo.status == WorkOrderStatus.completed &&
            wo.completedAt != null &&
            wo.createdAt != null)
        .toList();

    if (completedOrders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 48,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'No performance data available',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                'Complete some requests to see metrics',
                style: AppTheme.smallText.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate average resolution time
    final totalDays = completedOrders.fold<double>(
      0,
      (sum, wo) {
        final duration = wo.completedAt!.difference(wo.createdAt);
        return sum + duration.inDays + (duration.inHours % 24) / 24;
      },
    );
    final avgDays = totalDays / completedOrders.length;

    // Find fastest and slowest
    final fastest = completedOrders.reduce((a, b) {
      final aDuration = a.completedAt!.difference(a.createdAt);
      final bDuration = b.completedAt!.difference(b.createdAt);
      return aDuration < bDuration ? a : b;
    });
    final slowest = completedOrders.reduce((a, b) {
      final aDuration = a.completedAt!.difference(a.createdAt);
      final bDuration = b.completedAt!.difference(b.createdAt);
      return aDuration > bDuration ? a : b;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: AppTheme.heading2.copyWith(
                color: AppTheme.darkTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildMetricRow(
              'Average Resolution Time',
              '${avgDays.toStringAsFixed(1)} days',
              Icons.timer,
            ),
            _buildMetricRow(
              'Fastest Resolution',
              _formatDuration(
                fastest.completedAt!.difference(fastest.createdAt),
              ),
              Icons.flash_on,
              AppTheme.accentGreen,
            ),
            _buildMetricRow(
              'Slowest Resolution',
              _formatDuration(
                slowest.completedAt!.difference(slowest.createdAt),
              ),
              Icons.hourglass_empty,
              AppTheme.accentOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? const Color(0xFF002911), // Be Electric green
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyText,
              ),
            ),
            Text(
              value,
              style: AppTheme.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? AppTheme.darkTextColor,
              ),
            ),
          ],
        ),
      );

  Widget _buildRecentTrends(List<WorkOrder> workOrders) {
    // Group by month
    final now = DateTime.now();
    final last6Months = <String, int>{};
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      last6Months[monthKey] = workOrders
          .where((wo) =>
              wo.createdAt.year == month.year &&
              wo.createdAt.month == month.month)
          .length;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Trends (Last 6 Months)',
              style: AppTheme.heading2.copyWith(
                color: AppTheme.darkTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (last6Months.values.every((v) => v == 0))
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Text(
                    'No requests in the last 6 months',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ),
              )
            else
              ...last6Months.entries.map((entry) {
                final maxValue = last6Months.values.reduce((a, b) => a > b ? a : b);
                final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatMonth(entry.key),
                            style: AppTheme.smallText,
                          ),
                          Text(
                            entry.value.toString(),
                            style: AppTheme.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppTheme.lightGrey,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF002911), // Be Electric green
                        ),
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

  Widget _buildTopAssets(
    List<WorkOrder> workOrders,
    UnifiedDataProvider provider,
  ) {
    final assetCounts = <String, int>{};
    for (final wo in workOrders) {
      if (wo.assetId != null && wo.assetId!.isNotEmpty) {
        assetCounts[wo.assetId!] = (assetCounts[wo.assetId!] ?? 0) + 1;
      }
    }

    final sortedAssets = assetCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topAssets = sortedAssets.take(5).toList();

    if (topAssets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Requested Assets',
              style: AppTheme.heading2.copyWith(
                color: AppTheme.darkTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...topAssets.map((entry) {
              final asset = provider.assets
                  .where((a) => a.id == entry.key)
                  .firstOrNull;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 20,
                      color: Color(0xFF002911), // Be Electric green
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        asset?.name ?? entry.key,
                        style: AppTheme.bodyText,
                      ),
                    ),
                    Text(
                      '${entry.value} request${entry.value == 1 ? '' : 's'}',
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF002911), // Be Electric green
                      ),
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

  Color _getStatusColor(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.open:
        return AppTheme.accentBlue;
      case WorkOrderStatus.assigned:
        return AppTheme.accentOrange;
      case WorkOrderStatus.inProgress:
        return AppTheme.accentOrange;
      case WorkOrderStatus.completed:
        return AppTheme.accentGreen;
      case WorkOrderStatus.closed:
        return AppTheme.lightGrey;
      case WorkOrderStatus.cancelled:
        return AppTheme.accentRed;
    }
  }

  String _getStatusText(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.open:
        return 'Open';
      case WorkOrderStatus.assigned:
        return 'Assigned';
      case WorkOrderStatus.inProgress:
        return 'In Progress';
      case WorkOrderStatus.completed:
        return 'Completed';
      case WorkOrderStatus.closed:
        return 'Closed';
      case WorkOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getPriorityColor(WorkOrderPriority priority) {
    switch (priority) {
      case WorkOrderPriority.low:
        return AppTheme.accentGreen;
      case WorkOrderPriority.medium:
        return AppTheme.accentOrange;
      case WorkOrderPriority.high:
        return AppTheme.accentRed;
      case WorkOrderPriority.urgent:
        return AppTheme.accentRed;
      case WorkOrderPriority.critical:
        return Colors.purple;
    }
  }

  IconData _getPriorityIcon(WorkOrderPriority priority) {
    switch (priority) {
      case WorkOrderPriority.low:
        return Icons.keyboard_arrow_down;
      case WorkOrderPriority.medium:
        return Icons.remove;
      case WorkOrderPriority.high:
        return Icons.keyboard_arrow_up;
      case WorkOrderPriority.urgent:
        return Icons.error_outline;
      case WorkOrderPriority.critical:
        return Icons.priority_high;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    }
  }

  String _formatMonth(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${monthNames[month - 1]} $year';
  }
}


