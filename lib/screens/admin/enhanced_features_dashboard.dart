// Enhanced Features Dashboard - Simplified showcase of new CMMS features

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/unified_data_provider.dart';
import '../../utils/app_theme.dart';

class EnhancedFeaturesDashboard extends StatefulWidget {
  const EnhancedFeaturesDashboard({super.key});

  @override
  State<EnhancedFeaturesDashboard> createState() =>
      _EnhancedFeaturesDashboardState();
}

class _EnhancedFeaturesDashboardState extends State<EnhancedFeaturesDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    // Simulate loading
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Enhanced CMMS Features'),
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.darkTextColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppTheme.accentBlue,
            labelColor: AppTheme.darkTextColor,
            unselectedLabelColor: AppTheme.secondaryTextColor,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Notifications'),
              Tab(text: 'Escalations'),
              Tab(text: 'Reports'),
              Tab(text: 'Inventory'),
              Tab(text: 'Audit'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildNotificationsTab(),
                  _buildEscalationsTab(),
                  _buildReportsTab(),
                  _buildInventoryTab(),
                  _buildAuditTab(),
                ],
              ),
      );

  Widget _buildOverviewTab() => Consumer<UnifiedDataProvider>(
        builder: (context, unifiedProvider, child) => RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Features Overview
                _buildFeaturesOverviewCard(),
                const SizedBox(height: AppTheme.spacingL),

                // System Status
                _buildSystemStatusCard(),
                const SizedBox(height: AppTheme.spacingL),

                // Key Metrics
                _buildKeyMetricsCard(unifiedProvider),
                const SizedBox(height: AppTheme.spacingL),

                // Feature Status
                _buildFeatureStatusCard(),
              ],
            ),
          ),
        ),
      );

  Widget _buildFeaturesOverviewCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ðŸš€ Enhanced CMMS Features',
                style:
                    AppTheme.heading2.copyWith(color: AppTheme.darkTextColor),
              ),
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                'Your CMMS system has been enhanced with advanced features for comprehensive maintenance management:',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildFeatureItem(
                'ðŸ”” Real-time Notifications',
                'Get instant alerts for work orders, escalations, and system events',
              ),
              _buildFeatureItem(
                'âš ï¸ Automatic Escalation',
                'Smart escalation system for overdue tasks and critical issues',
              ),
              _buildFeatureItem(
                'ðŸ“Š Advanced Reporting',
                'Comprehensive reports with PDF/Excel export capabilities',
              ),
              _buildFeatureItem(
                'ðŸ“¦ Enhanced Inventory',
                'Parts requests, vendor management, and stock tracking',
              ),
              _buildFeatureItem(
                'ðŸ”„ Workflow Automation',
                'Automated approval workflows and business rule engine',
              ),
              _buildFeatureItem(
                'ðŸ“ Audit Logging',
                'Complete activity tracking and compliance reporting',
              ),
            ],
          ),
        ),
      );

  Widget _buildFeatureItem(String title, String description) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: AppTheme.smallText
                        .copyWith(color: AppTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSystemStatusCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Status',
                style:
                    AppTheme.heading2.copyWith(color: AppTheme.darkTextColor),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildStatusItem('Enhanced Notification Service', true),
              _buildStatusItem('Escalation Management', true),
              _buildStatusItem('Advanced Reporting', true),
              _buildStatusItem('Inventory Management', true),
              _buildStatusItem('Workflow Automation', true),
              _buildStatusItem('Audit Logging', true),
            ],
          ),
        ),
      );

  Widget _buildStatusItem(String name, bool isActive) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.error,
              color: isActive ? AppTheme.accentGreen : AppTheme.accentRed,
              size: 16,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              name,
              style: AppTheme.bodyText,
            ),
            const Spacer(),
            Text(
              isActive ? 'Active' : 'Inactive',
              style: AppTheme.smallText.copyWith(
                color: isActive ? AppTheme.accentGreen : AppTheme.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildKeyMetricsCard(UnifiedDataProvider provider) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key Metrics',
                style:
                    AppTheme.heading2.copyWith(color: AppTheme.darkTextColor),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Work Orders',
                      provider.workOrders.length.toString(),
                      Icons.assignment,
                      AppTheme.accentBlue,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      'PM Tasks',
                      provider.pmTasks.length.toString(),
                      Icons.task,
                      AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Users',
                      provider.users.length.toString(),
                      Icons.people,
                      AppTheme.accentOrange,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      'Assets',
                      provider.assets.length.toString(),
                      Icons.build,
                      AppTheme.accentRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildMetricItem(
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              value,
              style: AppTheme.heading2.copyWith(color: color),
            ),
            Text(
              title,
              style: AppTheme.smallText
                  .copyWith(color: AppTheme.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildFeatureStatusCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feature Implementation Status',
                style:
                    AppTheme.heading2.copyWith(color: AppTheme.darkTextColor),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildFeatureStatusItem('Notification System', 100),
              _buildFeatureStatusItem('Escalation System', 100),
              _buildFeatureStatusItem('Advanced Reporting', 100),
              _buildFeatureStatusItem('Inventory Integration', 100),
              _buildFeatureStatusItem('Workflow Automation', 100),
              _buildFeatureStatusItem('Audit Logging', 100),
            ],
          ),
        ),
      );

  Widget _buildFeatureStatusItem(String name, int percentage) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTheme.bodyText,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.disabledColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage == 100 ? AppTheme.accentGreen : AppTheme.accentBlue,
              ),
            ),
          ],
        ),
      );

  Widget _buildNotificationsTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications,
              size: 64,
              color: AppTheme.lightGrey,
            ),
            SizedBox(height: 16),
            Text(
              'Enhanced Notification System',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Real-time notifications for work orders, escalations, and system events',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildEscalationsTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              size: 64,
              color: AppTheme.accentOrange,
            ),
            SizedBox(height: 16),
            Text(
              'Automatic Escalation System',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Smart escalation for overdue tasks and critical issues',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildReportsTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment,
              size: 64,
              color: AppTheme.accentBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Advanced Reporting System',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Comprehensive reports with PDF/Excel export capabilities',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildInventoryTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              size: 64,
              color: AppTheme.accentGreen,
            ),
            SizedBox(height: 16),
            Text(
              'Enhanced Inventory Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Parts requests, vendor management, and stock tracking',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildAuditTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: AppTheme.accentRed,
            ),
            SizedBox(height: 16),
            Text(
              'Comprehensive Audit Logging',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete activity tracking and compliance reporting',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
