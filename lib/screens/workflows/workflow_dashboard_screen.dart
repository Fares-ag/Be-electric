// Workflow Dashboard Screen - High-level overview of workflows

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/workflow_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workflow_provider.dart';
import '../../utils/app_theme.dart';
import 'create_workflow_screen.dart';
import 'workflow_detail_screen.dart';

class WorkflowDashboardScreen extends StatefulWidget {
  const WorkflowDashboardScreen({super.key});

  @override
  State<WorkflowDashboardScreen> createState() =>
      _WorkflowDashboardScreenState();
}

class _WorkflowDashboardScreenState extends State<WorkflowDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkflowProvider>(context, listen: false).loadWorkflows();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final workflowProvider = Provider.of<WorkflowProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Workflow Dashboard'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.white,
        ),
        body: const Center(
          child: Text('Please login to view workflows'),
        ),
      );
    }

    final statistics = workflowProvider.getStatistics();
    final pendingApprovals =
        workflowProvider.getPendingApprovalsForUser(currentUser);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Workflow Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: workflowProvider.loadWorkflows,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.white,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.white.withValues(alpha: 0.7),
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Pending (${pendingApprovals.length})'),
            const Tab(text: 'Active'),
            const Tab(text: 'All'),
          ],
        ),
      ),
      body: workflowProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(
                  context,
                  currentUser,
                  statistics,
                  pendingApprovals,
                  workflowProvider,
                ),
                _buildPendingApprovalsTab(
                  context,
                  currentUser,
                  pendingApprovals,
                ),
                _buildActiveWorkflowsTab(
                  context,
                  currentUser,
                  workflowProvider,
                ),
                _buildAllWorkflowsTab(context, currentUser, workflowProvider),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateWorkflow(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white,
        icon: const Icon(Icons.add),
        label: const Text('New Workflow'),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    dynamic currentUser,
    Map<String, dynamic> statistics,
    List<Workflow> pendingApprovals,
    WorkflowProvider workflowProvider,
  ) {
    final overdueWorkflows = workflowProvider.getOverdueWorkflows();

    return RefreshIndicator(
      onRefresh: () => workflowProvider.loadWorkflows(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    statistics['total'].toString(),
                    Icons.layers,
                    AppTheme.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pending Approval',
                    statistics['pendingApproval'].toString(),
                    Icons.pending_actions,
                    AppTheme.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    statistics['completed'].toString(),
                    Icons.check_circle,
                    AppTheme.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Overdue',
                    overdueWorkflows.length.toString(),
                    Icons.warning,
                    AppTheme.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Approvals Section
            _buildSectionHeader('Your Pending Approvals', Icons.approval),
            const SizedBox(height: 12),
            if (pendingApprovals.isEmpty)
              _buildEmptyState(
                'No pending approvals',
                Icons.check_circle_outline,
              )
            else
              ...pendingApprovals.take(5).map(
                    (workflow) => _buildWorkflowCard(
                      context,
                      workflow,
                      currentUser,
                      showActions: true,
                    ),
                  ),

            const SizedBox(height: 24),

            // Overdue Workflows Section
            if (overdueWorkflows.isNotEmpty) ...[
              _buildSectionHeader('Overdue Workflows', Icons.warning_amber),
              const SizedBox(height: 12),
              ...overdueWorkflows.take(5).map(
                    (workflow) => _buildWorkflowCard(
                      context,
                      workflow,
                      currentUser,
                      showUrgent: true,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalsTab(
    BuildContext context,
    dynamic currentUser,
    List<Workflow> pendingApprovals,
  ) =>
      RefreshIndicator(
        onRefresh: () => Provider.of<WorkflowProvider>(context, listen: false)
            .loadWorkflows(),
        child: pendingApprovals.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppTheme.green.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No pending approvals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All caught up!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.lightGrey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pendingApprovals.length,
                itemBuilder: (context, index) => _buildWorkflowCard(
                  context,
                  pendingApprovals[index],
                  currentUser,
                  showActions: true,
                ),
              ),
      );

  Widget _buildActiveWorkflowsTab(
    BuildContext context,
    dynamic currentUser,
    WorkflowProvider workflowProvider,
  ) {
    final activeWorkflows = workflowProvider.workflows
        .where(
          (w) =>
              w.status == WorkflowStatus.inProgress ||
              w.status == WorkflowStatus.pendingApproval,
        )
        .toList();

    return RefreshIndicator(
      onRefresh: () => workflowProvider.loadWorkflows(),
      child: activeWorkflows.isEmpty
          ? _buildEmptyState('No active workflows', Icons.work_outline)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeWorkflows.length,
              itemBuilder: (context, index) => _buildWorkflowCard(
                context,
                activeWorkflows[index],
                currentUser,
              ),
            ),
    );
  }

  Widget _buildAllWorkflowsTab(
    BuildContext context,
    dynamic currentUser,
    WorkflowProvider workflowProvider,
  ) {
    var workflows = workflowProvider.workflows;

    // Apply filter
    if (_selectedFilter != 'all') {
      final status =
          WorkflowStatus.values.firstWhere((s) => s.name == _selectedFilter);
      workflows = workflowProvider.getWorkflowsByStatus(status);
    }

    return RefreshIndicator(
      onRefresh: () => workflowProvider.loadWorkflows(),
      child: workflows.isEmpty
          ? _buildEmptyState('No workflows found', Icons.search_off)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workflows.length,
              itemBuilder: (context, index) => _buildWorkflowCard(
                context,
                workflows[index],
                currentUser,
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
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
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
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
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSectionHeader(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
        ],
      );

  Widget _buildWorkflowCard(
    BuildContext context,
    Workflow workflow,
    dynamic currentUser, {
    bool showActions = false,
    bool showUrgent = false,
  }) {
    final workflowProvider =
        Provider.of<WorkflowProvider>(context, listen: false);
    final permissions =
        workflowProvider.getWorkflowPermissions(currentUser, workflow);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToWorkflowDetail(context, workflow),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(workflow.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      workflow.status.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(workflow.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (showUrgent || workflow.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 12, color: AppTheme.red),
                          SizedBox(width: 4),
                          Text(
                            'OVERDUE',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    _getWorkflowTypeIcon(workflow.type),
                    size: 20,
                    color: AppTheme.lightGrey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                workflow.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workflow.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.lightGrey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppTheme.lightGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workflow.createdBy,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightGrey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.lightGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, y').format(workflow.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightGrey,
                    ),
                  ),
                ],
              ),
              if (showActions && (permissions['canApprove'] ?? false)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _approveWorkflow(context, workflow, currentUser),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          foregroundColor: AppTheme.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _rejectWorkflow(context, workflow, currentUser),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.red,
                          side: const BorderSide(color: AppTheme.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.lightGrey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.lightGrey,
              ),
            ),
          ],
        ),
      );

  Color _getStatusColor(WorkflowStatus status) {
    switch (status) {
      case WorkflowStatus.draft:
        return AppTheme.lightGrey;
      case WorkflowStatus.pending:
        return AppTheme.blue;
      case WorkflowStatus.inProgress:
        return AppTheme.blue;
      case WorkflowStatus.pendingApproval:
        return AppTheme.orange;
      case WorkflowStatus.approved:
        return AppTheme.green;
      case WorkflowStatus.rejected:
        return AppTheme.red;
      case WorkflowStatus.completed:
        return AppTheme.green;
      case WorkflowStatus.cancelled:
        return AppTheme.lightGrey;
      case WorkflowStatus.escalated:
        return AppTheme.red;
      case WorkflowStatus.onHold:
        return AppTheme.orange;
    }
  }

  IconData _getWorkflowTypeIcon(WorkflowType type) {
    switch (type) {
      case WorkflowType.workOrderApproval:
        return Icons.assignment;
      case WorkflowType.workOrderCompletion:
        return Icons.check_circle;
      case WorkflowType.partsRequest:
        return Icons.shopping_cart;
      case WorkflowType.purchaseOrder:
        return Icons.receipt;
      case WorkflowType.budgetApproval:
        return Icons.attach_money;
      case WorkflowType.assetLifecycle:
        return Icons.build;
      case WorkflowType.inventoryRequest:
        return Icons.inventory;
      case WorkflowType.qualityInspection:
        return Icons.verified;
      case WorkflowType.escalation:
        return Icons.priority_high;
      case WorkflowType.scheduling:
        return Icons.schedule;
      case WorkflowType.userAccessRequest:
        return Icons.person_add;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Workflows'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: WorkflowStatus.values
              .map(
                (status) => RadioListTile<String>(
                  title: Text(status.name),
                  value: status.name,
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? 'all';
                    });
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveWorkflow(
    BuildContext context,
    Workflow workflow,
    dynamic currentUser,
  ) async {
    final workflowProvider =
        Provider.of<WorkflowProvider>(context, listen: false);

    final success = await workflowProvider.approveWorkflow(
      workflow.id,
      currentUser,
      null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Workflow approved successfully'
                : 'Failed to approve workflow',
          ),
          backgroundColor: success ? AppTheme.green : AppTheme.red,
        ),
      );
    }
  }

  Future<void> _rejectWorkflow(
    BuildContext context,
    Workflow workflow,
    dynamic currentUser,
  ) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Workflow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final workflowProvider =
          Provider.of<WorkflowProvider>(context, listen: false);

      final success = await workflowProvider.rejectWorkflow(
        workflow.id,
        currentUser,
        result,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Workflow rejected' : 'Failed to reject workflow',
            ),
            backgroundColor: success ? AppTheme.orange : AppTheme.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToCreateWorkflow(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateWorkflowScreen(),
      ),
    );

    if (result == true && mounted) {
      Provider.of<WorkflowProvider>(context, listen: false).loadWorkflows();
    }
  }

  void _navigateToWorkflowDetail(BuildContext context, Workflow workflow) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowDetailScreen(workflow: workflow),
      ),
    );
  }
}
