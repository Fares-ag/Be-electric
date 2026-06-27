import 'package:cmms_core/models/work_order.dart';
import 'package:cmms_core/utils/requestor_category_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapRequestorCategoryIssue', () {
    test('Electrical maps to electrical category and high priority', () {
      final fields = mapRequestorCategoryIssue('Electrical');

      expect(fields.category, RepairCategory.electrical);
      expect(fields.priority, WorkOrderPriority.high);
    });

    test('Mechanical maps to mechanicalHvac and medium priority', () {
      final fields = mapRequestorCategoryIssue('Mechanical');

      expect(fields.category, RepairCategory.mechanicalHvac);
      expect(fields.priority, WorkOrderPriority.medium);
    });

    test('Software maps to itLowVoltage and medium priority', () {
      final fields = mapRequestorCategoryIssue('Software');

      expect(fields.category, RepairCategory.itLowVoltage);
      expect(fields.priority, WorkOrderPriority.medium);
    });

    test('Hardware maps to specializedEquipment and medium priority', () {
      final fields = mapRequestorCategoryIssue('Hardware');

      expect(fields.category, RepairCategory.specializedEquipment);
      expect(fields.priority, WorkOrderPriority.medium);
    });

    test('Other maps to reactive and medium priority', () {
      final fields = mapRequestorCategoryIssue('Other');

      expect(fields.category, RepairCategory.reactive);
      expect(fields.priority, WorkOrderPriority.medium);
    });

    test('empty or unknown value falls back to reactive and medium', () {
      for (final value in ['', '  ', 'Unknown']) {
        final fields = mapRequestorCategoryIssue(value);

        expect(fields.category, RepairCategory.reactive);
        expect(fields.priority, WorkOrderPriority.medium);
      }
    });

    test('matching is case-insensitive', () {
      final fields = mapRequestorCategoryIssue('electrical');

      expect(fields.category, RepairCategory.electrical);
      expect(fields.priority, WorkOrderPriority.high);
    });
  });
}
