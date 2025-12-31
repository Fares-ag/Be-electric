// Workflow Provider - State management for workflow operations

import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/workflow_models.dart';
import '../models/work_order.dart';
import '../services/workflow_permission_service.dart';
import '../services/workflow_routing_service.dart';
import '../services/workflow_automation_service.dart';
import '../services/enhanced_notification_service.dart';
import '../services/unified_data_service.dart';

/// Provider for managing workflow state and operations
class WorkflowProvider with ChangeNotifier {
  final WorkflowPermissionService _permissionService =
      WorkflowPermissionService();
  final WorkflowRoutingService _routingService = WorkflowRoutingService();
  final WorkflowAutomationService _automationService =
      WorkflowAutomationService();
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();
  final UnifiedDataService _dataService = UnifiedDataService.instance;

  bool _isLoading = false;
  String? _error;

  List<Workflow> get workflows => _dataService.workflows;
  bool get isLoading => _isLoading || _dataService.isWorkflowsLoading;
  String? get error => _error;

  /// Initialize workflow provider
  Future<void> initialize() async {
    await _automationService.initialize();
    await loadWorkflows();
  }

  /// Load all workflows
  Future<void> loadWorkflows() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dataService.refreshWorkflows();
      debugPrint('Loaded ${workflows.length} workflows');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading workflows: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new workflow
  Future<Workflow?> createWorkflow({
    required User creator,
    required WorkflowType type,
    required String title,
    required String description,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? data,
    String? priority,
    DateTime? dueDate,
  }) async {
    try {
      // Check permissions
      if (!_permissionService.canCreateWorkflow(creator, type)) {
        throw Exception(
          'User does not have permission to create this workflow type',
        );
      }

      // Create workflow
      final workflow = Workflow(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        type: type,
        status: WorkflowStatus.pending,
        createdBy: creator.name,
        createdAt: DateTime.now(),
        createdByUserId: creator.id,
        createdByUserRole: creator.role,
        relatedEntityId: relatedEntityId,
        relatedEntityType: relatedEntityType,
        data: data ?? {},
        priority: priority,
        dueDate: dueDate,
        steps: {},
      );

      // Route workflow to approvers
      final approvers = await _routingService.routeWorkflow(workflow);
      final workflowWithApprovers = workflow.copyWith(
        approvers: approvers,
        currentApprover: approvers.isNotEmpty ? approvers.first : null,
        status: approvers.isNotEmpty
            ? WorkflowStatus.pendingApproval
            : WorkflowStatus.pending,
      );

      // Save to database
      await _dataService.createWorkflow(workflowWithApprovers);
      notifyListeners();

      // Send notifications
      await _notifyWorkflowCreated(workflowWithApprovers);

      // Execute automation rules
      await _automationService.executeAutomation(
        trigger: AutomationTrigger.workOrderCreated,
        itemId: workflowWithApprovers.id,
        itemType: 'workflow',
        context: {
          'type': type.name,
          'priority': priority,
          'estimatedCost': data?['estimatedCost'] ?? 0,
        },
      );

      debugPrint('Created workflow: ${workflowWithApprovers.id}');
      return workflowWithApprovers;
    } catch (e) {
      debugPrint('Error creating workflow: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Approve a workflow by ID
  Future<bool> approveWorkflow(
    String workflowId,
    User approver,
    String? comments,
  ) async {
    final workflow = _dataService.getWorkflowById(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found');
    }
    return _approveWorkflow(
      approver: approver,
      workflow: workflow,
      comments: comments,
    );
  }

  /// Approve a workflow
  Future<bool> _approveWorkflow({
    required User approver,
    required Workflow workflow,
    String? comments,
  }) async {
    try {
      // Check permissions
      if (!_permissionService.canApproveWorkflow(approver, workflow)) {
        throw Exception(
          'User does not have permission to approve this workflow',
        );
      }

      // Use UnifiedDataService to approve
      await _dataService.approveWorkflow(
        workflowId: workflow.id,
        approverId: approver.id,
        approverName: approver.name,
        approverRole: approver.role,
        comments: comments,
      );

      // Send notifications
      final updatedWorkflow = _dataService.getWorkflowById(workflow.id);
      if (updatedWorkflow != null) {
        await _notifyWorkflowApproved(updatedWorkflow, approver);
      }

      notifyListeners();
      debugPrint('Workflow approved: ${workflow.id} by ${approver.name}');
      return true;
    } catch (e) {
      debugPrint('Error approving workflow: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reject a workflow by ID
  Future<bool> rejectWorkflow(
    String workflowId,
    User rejector,
    String reason,
  ) async {
    final workflow = _dataService.getWorkflowById(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found');
    }
    return _rejectWorkflow(
      rejector: rejector,
      workflow: workflow,
      reason: reason,
    );
  }

  /// Reject a workflow
  Future<bool> _rejectWorkflow({
    required User rejector,
    required Workflow workflow,
    required String reason,
  }) async {
    try {
      // Check permissions
      if (!_permissionService.canRejectWorkflow(rejector, workflow)) {
        throw Exception(
          'User does not have permission to reject this workflow',
        );
      }

      // Use UnifiedDataService to reject
      await _dataService.rejectWorkflow(
        workflowId: workflow.id,
        rejectorId: rejector.id,
        rejectorName: rejector.name,
        rejectorRole: rejector.role,
        reason: reason,
      );

      // Send notifications
      final updatedWorkflow = _dataService.getWorkflowById(workflow.id);
      if (updatedWorkflow != null) {
        await _notifyWorkflowRejected(updatedWorkflow, rejector, reason);
      }

      notifyListeners();
      debugPrint('Workflow rejected: ${workflow.id} by ${rejector.name}');
      return true;
    } catch (e) {
      debugPrint('Error rejecting workflow: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cancel a workflow by ID
  Future<bool> cancelWorkflow(
    String workflowId,
    User user,
    String reason,
  ) async {
    final workflow = _dataService.getWorkflowById(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found');
    }
    return _cancelWorkflow(user: user, workflow: workflow, reason: reason);
  }

  /// Cancel a workflow
  Future<bool> _cancelWorkflow({
    required User user,
    required Workflow workflow,
    required String reason,
  }) async {
    try {
      // Check permissions
      if (!_permissionService.canCancelWorkflow(user, workflow)) {
        throw Exception(
          'User does not have permission to cancel this workflow',
        );
      }

      // Use UnifiedDataService to cancel
      await _dataService.cancelWorkflow(
        workflowId: workflow.id,
        cancelledBy: user.name,
        reason: reason,
      );

      notifyListeners();
      debugPrint('Workflow cancelled: ${workflow.id}');
      return true;
    } catch (e) {
      debugPrint('Error cancelling workflow: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Complete a workflow
  Future<bool> completeWorkflow({
    required User user,
    required Workflow workflow,
    String? comments,
  }) async {
    try {
      // Use UnifiedDataService to complete
      await _dataService.completeWorkflow(
        workflowId: workflow.id,
        completedBy: user.name,
        comments: comments,
      );

      // Send notifications
      final updatedWorkflow = _dataService.getWorkflowById(workflow.id);
      if (updatedWorkflow != null) {
        await _notifyWorkflowCompleted(updatedWorkflow);
      }

      notifyListeners();
      debugPrint('Workflow completed: ${workflow.id}');
      return true;
    } catch (e) {
      debugPrint('Error completing workflow: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get workflows for a specific user
  List<Workflow> getWorkflowsForUser(User user) => workflows
      .where((workflow) => _permissionService.canViewWorkflow(user, workflow))
      .toList();

  /// Get pending approvals for a user
  List<Workflow> getPendingApprovalsForUser(User user) => workflows
      .where(
        (workflow) =>
            workflow.status == WorkflowStatus.pendingApproval &&
            _permissionService.canApproveWorkflow(user, workflow),
      )
      .toList();

  /// Get workflows by status
  List<Workflow> getWorkflowsByStatus(WorkflowStatus status) =>
      _dataService.getWorkflowsByStatus(status);

  /// Get workflows by type
  List<Workflow> getWorkflowsByType(WorkflowType type) =>
      _dataService.getWorkflowsByType(type);

  /// Get overdue workflows
  List<Workflow> getOverdueWorkflows() => _dataService.getOverdueWorkflows();

  /// Check if user can perform action on workflow
  Map<String, bool> getWorkflowPermissions(User user, Workflow workflow) =>
      _permissionService.getWorkflowPermissions(user, workflow);

  /// Check if user can approve a workflow
  bool canApprove(User user, Workflow workflow) =>
      _permissionService.canApproveWorkflow(user, workflow);

  /// Check if user can reject a workflow (alias for canApprove)
  bool canReject(User user, Workflow workflow) =>
      _permissionService.canApproveWorkflow(user, workflow);

  /// Escalate a workflow
  Future<bool> escalateWorkflow(
    String workflowId,
    User user,
  ) async {
    try {
      final workflow = _dataService.getWorkflowById(workflowId);
      if (workflow == null) {
        throw Exception('Workflow not found');
      }

      // Check permissions
      if (!_permissionService.canEscalateWorkflow(user, workflow)) {
        throw Exception(
          'User does not have permission to escalate this workflow',
        );
      }

      // Use UnifiedDataService to escalate
      await _dataService.escalateWorkflow(
        workflowId: workflow.id,
        escalatedBy: user.name,
        reason: 'Manually escalated',
      );

      // Send notifications
      await _notificationService.createNotification(
        title: 'Workflow Escalated',
        message: '${workflow.title} has been escalated',
        type: NotificationType.escalation,
        priority: NotificationPriority.critical,
        userId: workflow.createdByUserId,
        relatedId: workflow.id,
        relatedType: 'workflow',
      );

      notifyListeners();
      debugPrint('Workflow escalated: ${workflow.id}');
      return true;
    } catch (e) {
      debugPrint('Error escalating workflow: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get approval chain for a workflow
  Future<List<Map<String, dynamic>>> getApprovalChain(
          Workflow workflow,) async =>
      _routingService.getApprovalChain(workflow);

  /// Create workflow for high-cost work order
  Future<Workflow?> createWorkOrderApprovalWorkflow({
    required User creator,
    required WorkOrder workOrder,
  }) async =>
      createWorkflow(
        creator: creator,
        type: WorkflowType.workOrderApproval,
        title: 'Work Order Approval: ${workOrder.ticketNumber}',
        description: 'Approval required for ${workOrder.problemDescription}',
        relatedEntityId: workOrder.id,
        relatedEntityType: 'work_order',
        data: {
          'estimatedCost': workOrder.estimatedCost ?? 0,
          'priority': workOrder.priority.name,
          'assetId': workOrder.assetId,
        },
        priority: workOrder.priority.name,
        dueDate: DateTime.now().add(const Duration(hours: 24)),
      );

  /// Send workflow created notifications
  Future<void> _notifyWorkflowCreated(Workflow workflow) async {
    // Notify approvers
    for (final approverId in workflow.approvers) {
      await _notificationService.createNotification(
        title: 'Workflow Approval Required',
        message: workflow.title,
        type: NotificationType.workflowApproval,
        priority: NotificationPriority.high,
        userId: approverId,
        relatedId: workflow.id,
        relatedType: 'workflow',
        data: {'workflowType': workflow.type.name},
      );
    }
  }

  /// Send workflow approved notifications
  Future<void> _notifyWorkflowApproved(
    Workflow workflow,
    User approver,
  ) async {
    // Notify creator
    await _notificationService.createNotification(
      title: 'Workflow Approved',
      message: '${workflow.title} was approved by ${approver.name}',
      type: NotificationType.workflowApproval,
      userId: workflow.createdByUserId,
      relatedId: workflow.id,
      relatedType: 'workflow',
    );
  }

  /// Send workflow rejected notifications
  Future<void> _notifyWorkflowRejected(
    Workflow workflow,
    User rejector,
    String reason,
  ) async {
    // Notify creator
    await _notificationService.createNotification(
      title: 'Workflow Rejected',
      message: '${workflow.title} was rejected by ${rejector.name}: $reason',
      type: NotificationType.workflowApproval,
      priority: NotificationPriority.high,
      userId: workflow.createdByUserId,
      relatedId: workflow.id,
      relatedType: 'workflow',
      data: {'reason': reason},
    );
  }

  /// Send workflow completed notifications
  Future<void> _notifyWorkflowCompleted(Workflow workflow) async {
    // Notify all stakeholders
    final stakeholders = {
      workflow.createdByUserId,
      if (workflow.assignedToUserId != null) workflow.assignedToUserId!,
      ...workflow.approvers,
    };

    for (final stakeholderId in stakeholders) {
      await _notificationService.createNotification(
        title: 'Workflow Completed',
        message: workflow.title,
        type: NotificationType.workOrderCompleted,
        priority: NotificationPriority.low,
        userId: stakeholderId,
        relatedId: workflow.id,
        relatedType: 'workflow',
      );
    }
  }

  /// Get workflow statistics
  Map<String, dynamic> getStatistics() {
    final total = workflows.length;
    final pending = workflows.where((w) => w.isPending).length;
    final inProgress = workflows.where((w) => w.isInProgress).length;
    final pendingApproval = workflows.where((w) => w.isPendingApproval).length;
    final approved = workflows.where((w) => w.isApproved).length;
    final rejected = workflows.where((w) => w.isRejected).length;
    final completed = workflows.where((w) => w.isCompleted).length;
    final overdue = workflows.where((w) => w.isOverdue).length;

    return {
      'total': total,
      'pending': pending,
      'inProgress': inProgress,
      'pendingApproval': pendingApproval,
      'approved': approved,
      'rejected': rejected,
      'completed': completed,
      'overdue': overdue,
      'completionRate': total > 0 ? (completed / total) * 100 : 0,
      'approvalRate': (pending + approved) > 0
          ? (approved / (pending + approved)) * 100
          : 0,
    };
  }
}
