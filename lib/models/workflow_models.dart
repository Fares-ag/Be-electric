// Workflow-related data models for the CMMS application

// Top-level enums
enum WorkflowStatus {
  draft,
  pending,
  inProgress,
  pendingApproval,
  approved,
  rejected,
  completed,
  cancelled,
  escalated,
  onHold,
}

enum WorkflowType {
  workOrderApproval,
  workOrderCompletion,
  partsRequest,
  purchaseOrder,
  budgetApproval,
  assetLifecycle,
  inventoryRequest,
  qualityInspection,
  scheduling,
  escalation,
  userAccessRequest,
}

// Base workflow
class Workflow {
  const Workflow({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.createdByUserId,
    required this.createdByUserRole,
    this.updatedAt,
    this.assignedTo,
    this.assignedToUserId,
    this.assignedToUserRole,
    this.dueDate,
    this.relatedEntityId,
    this.relatedEntityType,
    this.parentWorkflowId,
    this.priority,
    this.steps = const {},
    this.tags = const [],
    this.approvers = const [],
    this.currentApprover,
    this.approvalHistory = const [],
    this.data = const {},
    this.completedAt,
    this.completedBy,
    this.actualDuration,
    this.completionComments,
    this.rejectionReason,
    this.cancellationReason,
    this.escalationPath = const [],
  });

  final String id;
  final String title;
  final String description;
  final WorkflowType type;
  final WorkflowStatus status;
  final String createdBy;
  final DateTime createdAt;
  final String createdByUserId;
  final String createdByUserRole;
  final DateTime? updatedAt;
  final String? assignedTo;
  final String? assignedToUserId;
  final String? assignedToUserRole;
  final DateTime? dueDate;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final String? parentWorkflowId;
  final String? priority;
  final Map<String, WorkflowStep> steps;
  final List<String> tags;
  final List<String> approvers;
  final String? currentApprover;
  final List<Map<String, dynamic>> approvalHistory;
  final Map<String, dynamic> data;
  final DateTime? completedAt;
  final String? completedBy;
  final int? actualDuration;
  final String? completionComments;
  final String? rejectionReason;
  final String? cancellationReason;
  final List<String> escalationPath;

  bool get isCompleted => status == WorkflowStatus.completed;
  bool get isCancelled => status == WorkflowStatus.cancelled;
  bool get isPending => status == WorkflowStatus.pending;
  bool get isPendingApproval => status == WorkflowStatus.pendingApproval;
  bool get isApproved => status == WorkflowStatus.approved;
  bool get isRejected => status == WorkflowStatus.rejected;
  bool get isInProgress => status == WorkflowStatus.inProgress;
  bool get isEscalated => status == WorkflowStatus.escalated;
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      !isCompleted &&
      !isCancelled;
  bool get isDueToday =>
      dueDate != null && _isSameDay(dueDate!, DateTime.now());

  Workflow copyWith({
    String? id,
    String? title,
    String? description,
    WorkflowType? type,
    WorkflowStatus? status,
    String? createdBy,
    DateTime? createdAt,
    String? createdByUserId,
    String? createdByUserRole,
    DateTime? updatedAt,
    String? assignedTo,
    String? assignedToUserId,
    String? assignedToUserRole,
    DateTime? dueDate,
    String? relatedEntityId,
    String? relatedEntityType,
    String? parentWorkflowId,
    String? priority,
    Map<String, WorkflowStep>? steps,
    List<String>? tags,
    List<String>? approvers,
    String? currentApprover,
    List<Map<String, dynamic>>? approvalHistory,
    Map<String, dynamic>? data,
    DateTime? completedAt,
    String? completedBy,
    int? actualDuration,
    String? completionComments,
    String? rejectionReason,
    String? cancellationReason,
    List<String>? escalationPath,
  }) =>
      Workflow(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        status: status ?? this.status,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        createdByUserRole: createdByUserRole ?? this.createdByUserRole,
        updatedAt: updatedAt ?? this.updatedAt,
        assignedTo: assignedTo ?? this.assignedTo,
        assignedToUserId: assignedToUserId ?? this.assignedToUserId,
        assignedToUserRole: assignedToUserRole ?? this.assignedToUserRole,
        dueDate: dueDate ?? this.dueDate,
        relatedEntityId: relatedEntityId ?? this.relatedEntityId,
        relatedEntityType: relatedEntityType ?? this.relatedEntityType,
        parentWorkflowId: parentWorkflowId ?? this.parentWorkflowId,
        priority: priority ?? this.priority,
        steps: steps ?? this.steps,
        tags: tags ?? this.tags,
        approvers: approvers ?? this.approvers,
        currentApprover: currentApprover ?? this.currentApprover,
        approvalHistory: approvalHistory ?? this.approvalHistory,
        data: data ?? this.data,
        completedAt: completedAt ?? this.completedAt,
        completedBy: completedBy ?? this.completedBy,
        actualDuration: actualDuration ?? this.actualDuration,
        completionComments: completionComments ?? this.completionComments,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        escalationPath: escalationPath ?? this.escalationPath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'status': status.name,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'createdByUserId': createdByUserId,
        'createdByUserRole': createdByUserRole,
        'updatedAt': updatedAt?.toIso8601String(),
        'assignedTo': assignedTo,
        'assignedToUserId': assignedToUserId,
        'assignedToUserRole': assignedToUserRole,
        'dueDate': dueDate?.toIso8601String(),
        'relatedEntityId': relatedEntityId,
        'relatedEntityType': relatedEntityType,
        'parentWorkflowId': parentWorkflowId,
        'data': data,
        'priority': priority,
        'steps': steps.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'tags': tags,
        'approvers': approvers,
        'currentApprover': currentApprover,
        'approvalHistory': approvalHistory,
        'completedAt': completedAt?.toIso8601String(),
        'completedBy': completedBy,
        'actualDuration': actualDuration,
        'completionComments': completionComments,
        'rejectionReason': rejectionReason,
        'cancellationReason': cancellationReason,
        'escalationPath': escalationPath,
      };

  static Workflow fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'];
    final steps = <String, WorkflowStep>{};
    if (stepsJson is Map) {
      stepsJson.forEach((key, value) {
        if (key is String && value is Map) {
          steps[key] =
              WorkflowStep.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }

    return Workflow(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: WorkflowType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WorkflowType.workOrderApproval,
      ),
      status: WorkflowStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WorkflowStatus.pending,
      ),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdByUserId: json['createdByUserId'] as String,
      createdByUserRole: json['createdByUserRole'] as String,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      assignedTo: json['assignedTo'] as String?,
      assignedToUserId: json['assignedToUserId'] as String?,
      assignedToUserRole: json['assignedToUserRole'] as String?,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      relatedEntityId: json['relatedEntityId'] as String?,
      relatedEntityType: json['relatedEntityType'] as String?,
      parentWorkflowId: json['parentWorkflowId'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      priority: json['priority'] as String?,
      steps: steps,
      tags: List<String>.from(json['tags'] as List? ?? []),
      approvers: List<String>.from(json['approvers'] as List? ?? []),
      currentApprover: json['currentApprover'] as String?,
      approvalHistory: List<Map<String, dynamic>>.from(
        (json['approvalHistory'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      completedBy: json['completedBy'] as String?,
      actualDuration: (json['actualDuration'] as num?)?.toInt(),
      completionComments: json['completionComments'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      escalationPath: List<String>.from(json['escalationPath'] as List? ?? []),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// Simple workflow step
class WorkflowStep {

  factory WorkflowStep.fromJson(Map<String, dynamic> json) => WorkflowStep(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        status: WorkflowStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => WorkflowStatus.pending,
        ),
        order: (json['order'] as num?)?.toInt() ?? 0,
        assignedTo: json['assignedTo'] as String?,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        completedBy: json['completedBy'] as String?,
        data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      );
  const WorkflowStep({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.order,
    this.assignedTo,
    this.completedAt,
    this.completedBy,
    this.data = const {},
  });

  final String id;
  final String name;
  final String description;
  final WorkflowStatus status;
  final int order;
  final String? assignedTo;
  final DateTime? completedAt;
  final String? completedBy;
  final Map<String, dynamic> data;

  WorkflowStep copyWith({
    String? id,
    String? name,
    String? description,
    WorkflowStatus? status,
    int? order,
    String? assignedTo,
    DateTime? completedAt,
    String? completedBy,
    Map<String, dynamic>? data,
  }) =>
      WorkflowStep(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        status: status ?? this.status,
        order: order ?? this.order,
        assignedTo: assignedTo ?? this.assignedTo,
        completedAt: completedAt ?? this.completedAt,
        completedBy: completedBy ?? this.completedBy,
        data: data ?? this.data,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'status': status.name,
        'order': order,
        'assignedTo': assignedTo,
        'completedAt': completedAt?.toIso8601String(),
        'completedBy': completedBy,
        'data': data,
      };
}

// Work order approval workflow
class WorkOrderApprovalWorkflow extends Workflow {
  const WorkOrderApprovalWorkflow({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.createdByUserId,
    required super.createdByUserRole,
    this.workOrderId = '',
    this.estimatedCost = 0.0,
    this.justification,
    super.updatedAt,
    super.assignedTo,
    super.assignedToUserId,
    super.assignedToUserRole,
    super.dueDate,
    super.data,
    super.relatedEntityId,
    super.relatedEntityType,
    super.parentWorkflowId,
    super.priority,
    super.steps,
    super.tags,
    super.approvers,
    super.currentApprover,
    super.approvalHistory,
    super.completedAt,
    super.completedBy,
    super.actualDuration,
    super.completionComments,
    super.rejectionReason,
    super.cancellationReason,
    super.escalationPath,
  }) : super(type: WorkflowType.workOrderApproval);

  final String workOrderId;
  final double estimatedCost;
  final String? justification;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'workOrderId': workOrderId,
      'estimatedCost': estimatedCost,
      'justification': justification,
    });
    return json;
  }
}

// Asset lifecycle workflow
class AssetLifecycleWorkflow extends Workflow {
  const AssetLifecycleWorkflow({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.createdByUserId,
    required super.createdByUserRole,
    required this.assetId,
    required this.currentStage,
    required this.targetStage,
    this.requiredActions = const [],
    this.inspectionData = const {},
    super.updatedAt,
    super.assignedTo,
    super.assignedToUserId,
    super.assignedToUserRole,
    super.dueDate,
    super.data,
    super.relatedEntityId,
    super.relatedEntityType,
    super.parentWorkflowId,
    super.priority,
    super.steps,
    super.tags,
    super.approvers,
    super.currentApprover,
    super.approvalHistory,
    super.completedAt,
    super.completedBy,
    super.actualDuration,
    super.completionComments,
    super.rejectionReason,
    super.cancellationReason,
    super.escalationPath,
  }) : super(type: WorkflowType.assetLifecycle);

  final String assetId;
  final String currentStage;
  final String targetStage;
  final List<String> requiredActions;
  final Map<String, dynamic> inspectionData;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'assetId': assetId,
      'currentStage': currentStage,
      'targetStage': targetStage,
      'requiredActions': requiredActions,
      'inspectionData': inspectionData,
    });
    return json;
  }
}

// Escalation workflow
class EscalationWorkflow extends Workflow {
  const EscalationWorkflow({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.createdByUserId,
    required super.createdByUserRole,
    required this.originalWorkflowId,
    required this.escalationReason,
    required this.escalatedBy,
    required this.escalatedAt,
    super.escalationPath,
    super.updatedAt,
    super.assignedTo,
    super.assignedToUserId,
    super.assignedToUserRole,
    super.dueDate,
    super.data,
    super.relatedEntityId,
    super.relatedEntityType,
    super.parentWorkflowId,
    super.priority,
    super.steps,
    super.tags,
    super.approvers,
    super.currentApprover,
    super.approvalHistory,
    super.completedAt,
    super.completedBy,
    super.actualDuration,
    super.completionComments,
    super.rejectionReason,
    super.cancellationReason,
  }) : super(
          type: WorkflowType.escalation,
        );

  final String originalWorkflowId;
  final String escalationReason;
  final String escalatedBy;
  final DateTime escalatedAt;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'originalWorkflowId': originalWorkflowId,
      'escalationReason': escalationReason,
      'escalatedBy': escalatedBy,
      'escalatedAt': escalatedAt.toIso8601String(),
    });
    return json;
  }
}

// Templates
class WorkflowTemplate {
  const WorkflowTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.steps,
    this.defaultData = const {},
    this.category,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final WorkflowType type;
  final List<WorkflowStepTemplate> steps;
  final Map<String, dynamic> defaultData;
  final String? category;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'steps': steps.map((e) => e.toJson()).toList(),
        'defaultData': defaultData,
        'category': category,
        'isActive': isActive,
      };
}

class WorkflowStepTemplate {
  const WorkflowStepTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    this.defaultAssignee,
    this.requiredApprovals = const [],
    this.defaultData = const {},
  });

  final String id;
  final String name;
  final String description;
  final int order;
  final String? defaultAssignee;
  final List<String> requiredApprovals;
  final Map<String, dynamic> defaultData;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'order': order,
        'defaultAssignee': defaultAssignee,
        'requiredApprovals': requiredApprovals,
        'defaultData': defaultData,
      };
}
