import '../models/work_order.dart';

/// Priority and repair category derived from the requestor create-form selection.
class RequestorSubmissionFields {
  const RequestorSubmissionFields({
    required this.priority,
    required this.category,
  });

  final WorkOrderPriority priority;
  final RepairCategory category;
}

/// Maps requestor "Category Issue" dropdown values to work-order fields.
///
/// Form options: Electrical, Mechanical, Software, Hardware, Other
RequestorSubmissionFields mapRequestorCategoryIssue(String categoryIssue) {
  switch (categoryIssue.trim().toLowerCase()) {
    case 'electrical':
      return const RequestorSubmissionFields(
        priority: WorkOrderPriority.high,
        category: RepairCategory.electrical,
      );
    case 'mechanical':
      return const RequestorSubmissionFields(
        priority: WorkOrderPriority.medium,
        category: RepairCategory.mechanicalHvac,
      );
    case 'software':
      return const RequestorSubmissionFields(
        priority: WorkOrderPriority.medium,
        category: RepairCategory.itLowVoltage,
      );
    case 'hardware':
      return const RequestorSubmissionFields(
        priority: WorkOrderPriority.medium,
        category: RepairCategory.specializedEquipment,
      );
    case 'other':
      return const RequestorSubmissionFields(
        priority: WorkOrderPriority.medium,
        category: RepairCategory.reactive,
      );
    default:
      return const RequestorSubmissionFields(
        priority: WorkOrderPriority.medium,
        category: RepairCategory.reactive,
      );
  }
}
