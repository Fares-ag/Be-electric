import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/unified_data_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/mobile_qr_scanner_widget.dart';
import '../admin/seed_general_assets_screen.dart';
import '../analytics/consolidated_analytics_dashboard.dart';
import '../inventory/parts_request_screen.dart';
import '../pm_tasks/create_pm_task_screen.dart';
import '../pm_tasks/pm_task_list_screen.dart';
import '../work_orders/create_work_request_screen.dart';
import '../work_orders/work_order_list_screen.dart';

class TechnicianMainScreen extends StatefulWidget {
  const TechnicianMainScreen({super.key});

  @override
  State<TechnicianMainScreen> createState() => _TechnicianMainScreenState();
}

class _TechnicianMainScreenState extends State<TechnicianMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTechnicianData();
  }

  void _loadTechnicianData() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      // Data is now loaded from unified provider automatically
      print(
        '🔧 Technician Dashboard: Loading data for ${user.name} (${user.id})',
      );
    }
  }

  Future<void> _scanQRCode() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MobileQRScannerWidget(),
        ),
      );

      if (result != null && mounted) {
        // Show asset information and related maintenance tasks
        _showAssetMaintenanceInfo(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning QR code: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _navigateToPartsRequest() async {
    // Show work order selection dialog first
    final workOrder = await _showWorkOrderSelectionDialog();
    if (workOrder != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PartsRequestScreen(workOrder: workOrder),
        ),
      );
    }
  }

  Future<dynamic> _showWorkOrderSelectionDialog() async {
    final unifiedProvider =
        Provider.of<UnifiedDataProvider>(context, listen: false);
    final currentTechId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
    final workOrders = unifiedProvider.workOrders
        .where((wo) => wo.hasTechnician(currentTechId))
        .toList();

    if (workOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assigned work orders found'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return null;
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Work Order'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: workOrders.length,
            itemBuilder: (context, index) {
              final workOrder = workOrders[index];
              return ListTile(
                title: Text(workOrder.ticketNumber),
                subtitle: Text(workOrder.problemDescription),
                onTap: () => Navigator.of(context).pop(workOrder),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showQuickCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: Text(
                'Quick Create',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkTextColor,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.build_circle, color: AppTheme.accentBlue),
              title: const Text('Create Work Order'),
              subtitle: const Text('Report a new issue or maintenance need'),
              onTap: () async {
                // Get provider and messenger references BEFORE closing bottom sheet
                final unifiedProvider =
                    Provider.of<UnifiedDataProvider>(context, listen: false);
                final messenger = ScaffoldMessenger.of(context);

                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateWorkRequestScreen(),
                  ),
                );
                if (result == true && mounted) {
                  // Refresh data from unified provider
                  await unifiedProvider.refreshAll();

                  if (mounted) {
                    setState(() {}); // Trigger rebuild

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Work order created successfully!'),
                        backgroundColor: AppTheme.accentGreen,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppTheme.accentOrange),
              title: const Text('Create PM Task'),
              subtitle: const Text('Schedule preventive maintenance'),
              onTap: () async {
                // Get provider and messenger references BEFORE closing bottom sheet
                final unifiedProvider =
                    Provider.of<UnifiedDataProvider>(context, listen: false);
                final messenger = ScaffoldMessenger.of(context);

                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePMTaskScreen(),
                  ),
                );
                if (result == true && mounted) {
                  // Refresh data from unified provider
                  await unifiedProvider.refreshAll();

                  if (mounted) {
                    setState(() {}); // Trigger rebuild

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('PM task created successfully!'),
                        backgroundColor: AppTheme.accentGreen,
                      ),
                    );
                  }
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  Icon(Icons.qr_code_scanner, color: Colors.purple.shade600),
              title: const Text('Scan QR Code'),
              subtitle: const Text('Scan asset QR to create task'),
              onTap: () {
                Navigator.pop(context);
                _scanQRCode();
              },
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],
        ),
      ),
    );
  }

  void _showAssetMaintenanceInfo(Map<String, dynamic> assetData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asset: ${assetData['assetName'] ?? 'Unknown'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (assetData['location'] != null)
                _buildInfoRow('Location', assetData['location']),
              if (assetData['description'] != null)
                _buildInfoRow('Description', assetData['description']),
              if (assetData['category'] != null)
                _buildInfoRow('Category', assetData['category']),
              if (assetData['manufacturer'] != null)
                _buildInfoRow('Manufacturer', assetData['manufacturer']),
              if (assetData['model'] != null)
                _buildInfoRow('Model', assetData['model']),
              if (assetData['serialNumber'] != null)
                _buildInfoRow('Serial Number', assetData['serialNumber']),
              if (assetData['status'] != null)
                _buildInfoRow('Status', assetData['status']),
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                'Related Maintenance:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              // Show related work orders and PM tasks
              _buildMaintenanceTasks(assetData['assetId']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to work orders for this asset
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkOrderListScreen(
                    isTechnicianView: true,
                    assetId: assetData['assetId'],
                  ),
                ),
              );
            },
            child: const Text('View Tasks'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(value),
            ),
          ],
        ),
      );

  Widget _buildMaintenanceTasks(String? assetId) {
    if (assetId == null) {
      return const Text('No asset ID available');
    }

    // Get work orders and PM tasks for this asset
    final unifiedProvider =
        Provider.of<UnifiedDataProvider>(context, listen: false);
    final workOrders = unifiedProvider.workOrders
        .where((wo) => wo.assetId == assetId)
        .toList();

    final pmTasks =
        unifiedProvider.pmTasks.where((pm) => pm.assetId == assetId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Work Orders: ${workOrders.length}'),
        Text('PM Tasks: ${pmTasks.length}'),
        if (workOrders.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingS),
          const Text('Recent Work Orders:'),
          ...workOrders.take(3).map(
                (wo) => Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spacingS),
                  child: Text('• ${wo.problemDescription} (${wo.status})'),
                ),
              ),
        ],
        if (pmTasks.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingS),
          const Text('PM Tasks:'),
          ...pmTasks.take(3).map(
                (pm) => Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spacingS),
                  child: Text('• ${pm.taskName} (${pm.status})'),
                ),
              ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Technician Dashboard'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.darkTextColor,
        elevation: AppTheme.elevationS,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Quick Create',
            onPressed: _showQuickCreateMenu,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).logout();
              } else if (value == 'seed_assets') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SeedGeneralAssetsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'seed_assets',
                child: Row(
                  children: [
                    Icon(Icons.construction, color: AppTheme.accentGreen),
                    SizedBox(width: AppTheme.spacingS),
                    Text('Setup General Assets'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.accentRed),
                    SizedBox(width: AppTheme.spacingS),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(user),
          _buildWorkOrdersTab(),
          _buildPMTasksTab(),
          _buildAnalyticsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.accentBlue,
        unselectedItemColor: AppTheme.secondaryTextColor,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(user) => Consumer<UnifiedDataProvider>(
        builder: (context, unifiedProvider, child) {
          // Get technician-specific data
          final workOrders = unifiedProvider.getWorkOrdersByTechnician(user.id);
          final pmTasks = unifiedProvider.getPMTasksByTechnician(user.id);

          // Mobile responsive check
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;
          final padding = isMobile ? AppTheme.spacingM : AppTheme.spacingL;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    isMobile ? AppTheme.spacingM : AppTheme.spacingL,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.name ?? 'Technician'}!',
                        style:
                            (isMobile ? AppTheme.heading2 : AppTheme.heading1)
                                .copyWith(
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                      SizedBox(
                        height:
                            isMobile ? AppTheme.spacingXS : AppTheme.spacingS,
                      ),
                      Text(
                        'Here are your assigned tasks and analytics',
                        style:
                            (isMobile ? AppTheme.smallText : AppTheme.bodyText)
                                .copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: isMobile ? AppTheme.spacingM : AppTheme.spacingL,
                ),

                // QR Scanner Button
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    bottom: isMobile ? AppTheme.spacingM : AppTheme.spacingL,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _scanQRCode,
                    icon: Icon(Icons.qr_code_scanner, size: isMobile ? 20 : 24),
                    label: Text(
                      'Scan Asset QR Code',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical:
                            isMobile ? AppTheme.spacingS : AppTheme.spacingM,
                        horizontal:
                            isMobile ? AppTheme.spacingM : AppTheme.spacingL,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),

                // Quick Stats - Responsive layout
                if (isMobile)
                  Column(
                    children: [
                      _buildStatCard(
                        'Assigned Work Orders',
                        workOrders.length.toString(),
                        Icons.work,
                        AppTheme.accentBlue,
                        isMobile,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildStatCard(
                        'PM Tasks',
                        pmTasks.length.toString(),
                        Icons.schedule,
                        AppTheme.accentGreen,
                        isMobile,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Assigned Work Orders',
                          workOrders.length.toString(),
                          Icons.work,
                          AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _buildStatCard(
                          'PM Tasks',
                          pmTasks.length.toString(),
                          Icons.schedule,
                          AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),

                SizedBox(
                  height: isMobile ? AppTheme.spacingM : AppTheme.spacingL,
                ),

                // Action Buttons - Responsive layout
                if (isMobile)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _scanQRCode,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan QR Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToPartsRequest,
                          icon: const Icon(Icons.inventory),
                          label: const Text('Request Parts'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _scanQRCode,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan QR Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToPartsRequest,
                          icon: const Icon(Icons.inventory),
                          label: const Text('Request Parts'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: AppTheme.spacingL),

                // Recent Tasks
                Text(
                  'Recent Tasks',
                  style: AppTheme.heading2.copyWith(
                    color: AppTheme.darkTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your assigned tasks will appear here',
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 1; // Switch to work orders tab
                            });
                          },
                          icon: const Icon(Icons.work),
                          label: const Text('View Work Orders'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildWorkOrdersTab() =>
      const WorkOrderListScreen(isTechnicianView: true);

  Widget _buildPMTasksTab() => const PMTaskListScreen(isTechnicianView: true);

  Widget _buildAnalyticsTab() =>
      const ConsolidatedAnalyticsDashboard(isTechnicianView: true);

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, [
    bool isMobile = false,
  ]) =>
      Container(
        width: isMobile ? double.infinity : null,
        padding:
            EdgeInsets.all(isMobile ? AppTheme.spacingM : AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isMobile
            ? Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.smallText.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          value,
                          style: AppTheme.heading2.copyWith(
                            color: AppTheme.darkTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    value,
                    style: AppTheme.heading1.copyWith(
                      color: AppTheme.darkTextColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
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
}
