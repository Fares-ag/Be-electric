// Requestor Status Screen - Track maintenance request status and history

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/work_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/unified_data_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/custom_app_bar.dart';
import '../work_orders/work_order_detail_screen.dart';
import 'asset_selection_screen.dart';
import 'edit_request_screen.dart';

class RequestorStatusScreen extends StatefulWidget {
  const RequestorStatusScreen({super.key});

  @override
  State<RequestorStatusScreen> createState() => _RequestorStatusScreenState();
}

class _RequestorStatusScreenState extends State<RequestorStatusScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  WorkOrderStatus? _statusFilter;
  WorkOrderPriority? _priorityFilter;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    return Selector<UnifiedDataProvider, List<WorkOrder>>(
      selector: (_, provider) => provider.workOrders,
      builder: (context, allWorkOrders, child) {
        // Get user's work orders in real-time!
        final myRequests = user != null
            ? (allWorkOrders
                .where((wo) => wo.requestorId == user.id)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
            : <WorkOrder>[];

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(120), // AppBar + TabBar height
            child: Column(
              children: [
                CustomAppBar(
                  title: 'My Requests (${myRequests.length})',
                  showMenu: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                      tooltip: 'Filter',
                    ),
                  ],
                ),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF002911), // Be Electric green
                    unselectedLabelColor: AppTheme.secondaryTextColor,
                    indicatorColor: const Color(0xFF002911), // Be Electric green
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.pending_actions),
                        text: 'Active',
                      ),
                      Tab(
                        icon: Icon(Icons.history),
                        text: 'History',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search bar
              if (_searchQuery.isNotEmpty ||
                  _statusFilter != null ||
                  _priorityFilter != null)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  color: AppTheme.accentBlue.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      if (_searchQuery.isNotEmpty)
                        Chip(
                          label: Text('Search: $_searchQuery'),
                          onDeleted: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                      if (_statusFilter != null)
                        Chip(
                          label: Text('Status: ${_statusFilter!.name}'),
                          onDeleted: () {
                            setState(() {
                              _statusFilter = null;
                            });
                          },
                        ),
                      if (_priorityFilter != null)
                        Chip(
                          label: Text('Priority: ${_priorityFilter!.name}'),
                          onDeleted: () {
                            setState(() {
                              _priorityFilter = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveRequestsTab(myRequests),
                    _buildHistoryTab(myRequests),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssetSelectionScreen(),
                ),
              );
              // No need to reload - Consumer auto-updates!
            },
            icon: const Icon(Icons.add),
            label: const Text('New Request'),
            backgroundColor: const Color(0xFF002911), // Be Electric green
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  List<WorkOrder> _filterRequests(List<WorkOrder> requests) {
    // Optimized: combine all filters in single where clause
    final query = _searchQuery.toLowerCase();
    final hasSearchQuery = _searchQuery.isNotEmpty;
    
    return requests.where((r) {
      // Status filter
      if (_statusFilter != null && r.status != _statusFilter) {
        return false;
      }
      // Priority filter
      if (_priorityFilter != null && r.priority != _priorityFilter) {
        return false;
      }
      // Search query
      if (hasSearchQuery) {
        final matchesSearch = 
            r.ticketNumber.toLowerCase().contains(query) ||
            r.problemDescription.toLowerCase().contains(query) ||
            (r.assetId?.toLowerCase().contains(query) ?? false) ||
            (r.assetName?.toLowerCase().contains(query) ?? false);
        if (!matchesSearch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildActiveRequestsTab(List<WorkOrder> myRequests) {
    var activeRequests = myRequests
        .where(
          (request) =>
              request.status != WorkOrderStatus.completed &&
              request.status != WorkOrderStatus.closed,
        )
        .toList();

    activeRequests = _filterRequests(activeRequests);

    if (activeRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Active Requests',
        message: 'You have no pending maintenance requests.',
        actionText: 'Create New Request',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AssetSelectionScreen(),
            ),
          );
          // No need to reload - Consumer auto-updates!
        },
      );
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final padding = ResponsiveLayout.getResponsivePadding(context);
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);

    if (isDesktop || isTablet) {
      // Use grid layout for desktop/tablet
      final columns = isDesktop ? 2 : 1;
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: GridView.builder(
            padding: EdgeInsets.only(
              left: padding.horizontal / 2,
              right: padding.horizontal / 2,
              top: padding.vertical,
              bottom: padding.vertical + 80,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: padding.horizontal / 2,
              mainAxisSpacing: padding.vertical / 2,
              childAspectRatio: 1.2,
            ),
            itemCount: activeRequests.length,
            itemBuilder: (context, index) {
              final request = activeRequests[index];
              return _buildRequestCard(request);
            },
          ),
        ),
      );
    }

    // Mobile: use list view
    return ListView.builder(
      padding: EdgeInsets.only(
        left: padding.horizontal / 2,
        right: padding.horizontal / 2,
        top: padding.vertical,
        bottom: padding.vertical + 80, // Extra padding for floating action button
      ),
      itemCount: activeRequests.length,
      itemBuilder: (context, index) {
        final request = activeRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildHistoryTab(List<WorkOrder> myRequests) {
    // Show all past requests: completed, closed, and cancelled
    var pastRequests = myRequests
        .where(
          (request) =>
              request.status == WorkOrderStatus.completed ||
              request.status == WorkOrderStatus.closed ||
              request.status == WorkOrderStatus.cancelled,
        )
        .toList();

    pastRequests = _filterRequests(pastRequests);

    if (pastRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Request History',
        message: 'You have no past maintenance requests.',
        actionText: 'Create New Request',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AssetSelectionScreen(),
            ),
          );
          // No need to reload - Consumer auto-updates!
        },
      );
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final padding = ResponsiveLayout.getResponsivePadding(context);
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);

    if (isDesktop || isTablet) {
      // Use grid layout for desktop/tablet
      final columns = isDesktop ? 2 : 1;
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: GridView.builder(
            padding: EdgeInsets.only(
              left: padding.horizontal / 2,
              right: padding.horizontal / 2,
              top: padding.vertical,
              bottom: padding.vertical + 80,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: padding.horizontal / 2,
              mainAxisSpacing: padding.vertical / 2,
              childAspectRatio: 1.2,
            ),
            itemCount: pastRequests.length,
            itemBuilder: (context, index) {
              final request = pastRequests[index];
              return _buildRequestCard(request);
            },
          ),
        ),
      );
    }

    // Mobile: use list view
    return ListView.builder(
      padding: EdgeInsets.only(
        left: padding.horizontal / 2,
        right: padding.horizontal / 2,
        top: padding.vertical,
        bottom: padding.vertical + 80, // Extra padding for floating action button
      ),
      itemCount: pastRequests.length,
      itemBuilder: (context, index) {
        final request = pastRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(WorkOrder request) => Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        elevation: 2,
        child: InkWell(
          onTap: () => _viewFullWorkOrder(request),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        request.ticketNumber,
                        style: AppTheme.heading2.copyWith(
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(
                          color: _getStatusColor(request.status)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusText(request.status),
                        style: AppTheme.smallText.copyWith(
                          color: _getStatusColor(request.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingS),

                // Problem description
                Text(
                  request.problemDescription,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.darkTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Show additional notes/details if available
                if (request.notes != null && request.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    request.notes!,
                    style: AppTheme.smallText.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Show customer contact info if available
                if (request.customerName != null || request.customerPhone != null || request.customerEmail != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Wrap(
                    spacing: AppTheme.spacingS,
                    children: [
                      if (request.customerName != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person,
                              size: 12,
                              color: AppTheme.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.customerName!,
                              style: AppTheme.smallText.copyWith(
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      if (request.customerPhone != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 12,
                              color: AppTheme.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.customerPhone!,
                              style: AppTheme.smallText.copyWith(
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: AppTheme.spacingS),

                // Asset and priority info
                Row(
                  children: [
                    const Icon(
                      Icons.build,
                      size: 16,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      'Asset: ${request.assetId}',
                      style: AppTheme.smallText.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Icon(
                      _getPriorityIcon(request.priority),
                      size: 16,
                      color: _getPriorityColor(request.priority),
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      _getPriorityText(request.priority),
                      style: AppTheme.smallText.copyWith(
                        color: _getPriorityColor(request.priority),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingS),

                // Dates and assigned technician
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      'Created: ${_formatDate(request.createdAt)}',
                      style: AppTheme.smallText.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),

                if (request.assignedTechnicianIds.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        'Assigned to: ${request.assignedTechnicians?.map((t) => t.name).join(', ') ?? request.assignedTechnicianIds.join(', ')}',
                        style: AppTheme.smallText.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],

                // Action buttons for editable requests
                if (request.status == WorkOrderStatus.open ||
                    request.status == WorkOrderStatus.assigned) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _editRequest(request),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      TextButton.icon(
                        onPressed: () => _cancelRequest(request),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ],

                if (request.completedAt != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        'Completed: ${_formatDate(request.completedAt!)}',
                        style: AppTheme.smallText.copyWith(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Cost information (if available)
                if (request.totalCost != null ||
                    request.actualCost != null ||
                    request.laborCost != null ||
                    request.partsCost != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: AppTheme.accentBlue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 16,
                          color: AppTheme.accentBlue,
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (request.totalCost != null)
                                Text(
                                  'Total Cost: QAR ${request.totalCost!.toStringAsFixed(2)}',
                                  style: AppTheme.smallText.copyWith(
                                    color: AppTheme.accentBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else if (request.actualCost != null)
                                Text(
                                  'Actual Cost: QAR ${request.actualCost!.toStringAsFixed(2)}',
                                  style: AppTheme.smallText.copyWith(
                                    color: AppTheme.accentBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (request.laborCost != null || request.partsCost != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (request.laborCost != null)
                                      Expanded(
                                        child: Text(
                                          'Labor: QAR ${request.laborCost!.toStringAsFixed(2)}',
                                          style: AppTheme.smallText.copyWith(
                                            color: AppTheme.secondaryTextColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    if (request.partsCost != null)
                                      Expanded(
                                        child: Text(
                                          'Parts: QAR ${request.partsCost!.toStringAsFixed(2)}',
                                          style: AppTheme.smallText.copyWith(
                                            color: AppTheme.secondaryTextColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                title,
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                message,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingL),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

  void _viewFullWorkOrder(WorkOrder request) {
    // Navigate to full work order detail screen so requestors can see
    // all completion details including photos, corrective actions, etc.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkOrderDetailScreen(workOrder: request),
      ),
    );
  }


  Color _getStatusColor(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.open:
        return Colors.blue;
      case WorkOrderStatus.assigned:
        return Colors.orange;
      case WorkOrderStatus.inProgress:
        return Colors.purple;
      case WorkOrderStatus.completed:
        return Colors.green;
      case WorkOrderStatus.closed:
        return Colors.grey;
      case WorkOrderStatus.cancelled:
        return Colors.red;
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
        return Colors.green;
      case WorkOrderPriority.medium:
        return Colors.orange;
      case WorkOrderPriority.high:
        return Colors.red;
      case WorkOrderPriority.urgent:
        return Colors.deepOrange;
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

  String _getPriorityText(WorkOrderPriority priority) {
    switch (priority) {
      case WorkOrderPriority.low:
        return 'Low';
      case WorkOrderPriority.medium:
        return 'Medium';
      case WorkOrderPriority.high:
        return 'High';
      case WorkOrderPriority.urgent:
        return 'Urgent';
      case WorkOrderPriority.critical:
        return 'Critical';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Requests'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search field
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'Search by ticket, description, or asset...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // Debounce search input
                    _searchDebounceTimer?.cancel();
                    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                      setDialogState(() {
                        _searchQuery = value;
                      });
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Status filter
                DropdownButtonFormField<WorkOrderStatus?>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<WorkOrderStatus?>(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ...WorkOrderStatus.values.map(
                      (status) => DropdownMenuItem<WorkOrderStatus?>(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _statusFilter = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Priority filter
                DropdownButtonFormField<WorkOrderPriority?>(
                  initialValue: _priorityFilter,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<WorkOrderPriority?>(
                      value: null,
                      child: Text('All Priorities'),
                    ),
                    ...WorkOrderPriority.values.map(
                      (priority) => DropdownMenuItem<WorkOrderPriority?>(
                        value: priority,
                        child: Text(priority.name.toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _priorityFilter = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _searchQuery = '';
                  _statusFilter = null;
                  _priorityFilter = null;
                });
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
    setState(() {}); // Refresh the UI after dialog closes
  }

  Future<void> _editRequest(WorkOrder request) async {
    if (!mounted) return;
    final unifiedProvider =
        Provider.of<UnifiedDataProvider>(context, listen: false);
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRequestScreen(workOrder: request),
      ),
    );

    if (result == true && mounted) {
      // Refresh the data
      await unifiedProvider.refreshAll();
    }
  }

  Future<void> _cancelRequest(WorkOrder request) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this request? This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'Please provide a reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      if (!mounted) return;
      final unifiedProvider =
          Provider.of<UnifiedDataProvider>(context, listen: false);

      try {
        final updatedWorkOrder = request.copyWith(
          status: WorkOrderStatus.cancelled,
          notes: 'Cancelled by requestor. Reason: ${reasonController.text.trim()}',
          updatedAt: DateTime.now(),
        );

        await unifiedProvider.updateWorkOrder(updatedWorkOrder);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled successfully'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling request: $e'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    }
  }
}
