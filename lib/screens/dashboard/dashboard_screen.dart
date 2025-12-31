import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/unified_data_provider.dart';
import '../../theme/unified_design_system.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_card.dart';
import '../analytics/consolidated_analytics_dashboard.dart';
import '../demo/enhanced_asset_demo_screen.dart';
import '../demo/professional_asset_demo_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../pm_tasks/create_pm_task_screen.dart';
import '../pm_tasks/pm_task_list_screen.dart';
import '../settings/api_test_screen.dart';
import '../work_orders/create_work_request_screen.dart';
import '../work_orders/work_order_list_screen.dart';
import '../workflows/workflow_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.isTechnicianView = false,
    this.showNavigation = true,
  });
  final bool isTechnicianView;
  final bool showNavigation;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Data is loaded from UnifiedDataProvider automatically via real-time listeners
  }

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return _buildMobileLayout(context, authProvider);
        },
      );

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMobileLayout(BuildContext context, AuthProvider authProvider) =>
      Scaffold(
        appBar: AppBar(
          title: const Text('CMMS Mobile App'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  authProvider.logout();
                } else if (value == 'analytics') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ConsolidatedAnalyticsDashboard(),
                    ),
                  );
                } else if (value == 'notifications') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                } else if (value == 'notification_settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                } else if (value == 'workflows') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkflowListScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text(authProvider.currentUser!.name),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'analytics',
                  child: Row(
                    children: [
                      Icon(Icons.analytics),
                      SizedBox(width: 8),
                      Text('Analytics Dashboard'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'notifications',
                  child: Row(
                    children: [
                      Icon(Icons.notifications),
                      SizedBox(width: 8),
                      Text('Notifications'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'notification_settings',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active),
                      SizedBox(width: 8),
                      Text('Notification Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'workflows',
                  child: Row(
                    children: [
                      Icon(Icons.account_tree),
                      SizedBox(width: 8),
                      Text('Workflows'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: widget.showNavigation
            ? IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildDashboardTab(),
                  const WorkOrderListScreen(),
                  const PMTaskListScreen(),
                ],
              )
            : _buildDashboardTab(),
        bottomNavigationBar: widget.showNavigation
            ? BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.work),
                    label: 'Work Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.schedule),
                    label: 'PM Tasks',
                  ),
                ],
              )
            : null,
        floatingActionButton: widget.showNavigation && _selectedIndex == 1
            ? FloatingActionButton(
                heroTag: 'dashboard_fab',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWorkRequestScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
                child: const Icon(Icons.add),
              )
            : null,
      );

  Widget _buildMenuButton(BuildContext context, AuthProvider authProvider) =>
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'logout') {
            authProvider.logout();
          } else if (value == 'analytics') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConsolidatedAnalyticsDashboard(),
              ),
            );
          } else if (value == 'notifications') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          } else if (value == 'notification_settings') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            );
          } else if (value == 'workflows') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkflowListScreen(),
              ),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Text(authProvider.currentUser!.name),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'analytics',
            child: Row(
              children: [
                Icon(Icons.analytics),
                SizedBox(width: 8),
                Text('Analytics Dashboard'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'notifications',
            child: Row(
              children: [
                Icon(Icons.notifications),
                SizedBox(width: 8),
                Text('Notifications'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'notification_settings',
            child: Row(
              children: [
                Icon(Icons.notifications_active),
                SizedBox(width: 8),
                Text('Notification Settings'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'workflows',
            child: Row(
              children: [
                Icon(Icons.account_tree),
                SizedBox(width: 8),
                Text('Workflows'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
          ),
        ],
      );

  Widget _buildTabletNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).iconTheme.color,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () => _onItemTapped(index),
      ),
    );
  }

  Widget _buildDashboardTab() => Consumer<UnifiedDataProvider>(
        builder: (context, unifiedProvider, child) => RefreshIndicator(
          onRefresh: () async {
            await unifiedProvider.refreshAll();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                CommonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'User'}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Here's your maintenance overview",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Open Work Orders',
                        unifiedProvider.openWorkOrders.toString(),
                        Icons.work,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'In Progress',
                        unifiedProvider.inProgressWorkOrders.toString(),
                        Icons.hourglass_empty,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Due PM Tasks',
                        unifiedProvider.duePMTasks.toString(),
                        Icons.schedule,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Completed Today',
                        unifiedProvider.completedWorkOrdersToday.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Work Orders',
                        unifiedProvider.totalWorkOrders.toString(),
                        Icons.assignment,
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total PM Tasks',
                        unifiedProvider.totalPMTasks.toString(),
                        Icons.build,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Quick Actions
                CommonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateWorkRequestScreen(),
                                  ),
                                );
                                if (result == true && mounted) {
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('New Request'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 1;
                                });
                              },
                              icon: const Icon(Icons.work),
                              label: const Text('Work Orders'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 2;
                                });
                              },
                              icon: const Icon(Icons.schedule),
                              label: const Text('PM Tasks'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WorkflowListScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.account_tree),
                              label: const Text('Workflows'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreatePMTaskScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.schedule),
                              label: const Text('Create PM Task'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ConsolidatedAnalyticsDashboard(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.analytics),
                              label: const Text('Analytics'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.notifications),
                              label: const Text('Notifications'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ApiTestScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.api),
                              label: const Text('API Test'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EnhancedAssetDemoScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.rocket_launch),
                              label: const Text('ðŸš€ Asset Demo'),
                              style: UnifiedDesignSystem.accentButton,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfessionalAssetDemoScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.design_services),
                              label: const Text('âœ¨ Professional Demo'),
                              style: UnifiedDesignSystem.primaryButton,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      CommonCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.secondaryTextColor,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              value,
              style: AppTheme.heading1,
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              title,
              style: AppTheme.secondaryText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}


