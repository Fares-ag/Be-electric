import 'package:cmms_core/models/parts_request.dart';
import 'package:cmms_core/utils/parts_request_supabase_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPartsRequestInsertPayload', () {
    test('maps to live columns requestedBy + requestedParts', () {
      final now = DateTime.utc(2026, 7, 20, 10);
      final request = PartsRequest(
        id: 'pr-1',
        workOrderId: 'wo-1',
        technicianId: 'should-not-be-used-as-column',
        inventoryItemId: 'inv-1',
        quantity: 3,
        reason: 'Need filter',
        priority: PartsRequestPriority.high,
        status: PartsRequestStatus.pending,
        requestedAt: now,
        updatedAt: now,
        notes: 'urgent',
      );

      final row = buildPartsRequestInsertPayload(
        request: request,
        requestedBy: 'b099a876-1d50-468c-bd7f-6960eecc74da',
        inventoryItemName: 'Air Filter',
      );

      expect(row.containsKey('technicianId'), isFalse);
      expect(row.containsKey('inventoryItemId'), isFalse);
      expect(row.containsKey('quantity'), isFalse);
      expect(row['requestedBy'], 'b099a876-1d50-468c-bd7f-6960eecc74da');
      expect(row['workOrderId'], 'wo-1');
      expect(row['status'], 'pending');
      expect(row['requestedParts'], isA<List>());
      final parts = row['requestedParts'] as List;
      expect(parts, hasLength(1));
      expect(parts.first['name'], 'Air Filter');
      expect(parts.first['quantity'], 3);
      expect(parts.first['inventoryItemId'], 'inv-1');
    });
  });

  group('buildPartsRequestUpdatePayload', () {
    test('uses live columns only (no technicianId / isOffline)', () {
      final now = DateTime.utc(2026, 7, 20, 11);
      final request = PartsRequest(
        id: 'pr-1',
        workOrderId: 'wo-1',
        technicianId: 'tech-1',
        inventoryItemId: 'inv-1',
        quantity: 3,
        reason: 'Need filter',
        priority: PartsRequestPriority.high,
        status: PartsRequestStatus.approved,
        requestedAt: now,
        approvedAt: now,
        approvedBy: 'admin-1',
        updatedAt: now,
        notes: 'ok',
      );

      final row = buildPartsRequestUpdatePayload(
        request: request,
        inventoryItemName: 'Air Filter',
      );

      expect(row.containsKey('technicianId'), isFalse);
      expect(row.containsKey('inventoryItemId'), isFalse);
      expect(row.containsKey('quantity'), isFalse);
      expect(row.containsKey('isOffline'), isFalse);
      expect(row['status'], 'approved');
      expect(row['approvedBy'], 'admin-1');
      expect(row['requestedParts'], isA<List>());
    });
  });

  group('parsePartsRequestFields / fromMap', () {
    test('reads requestedBy and requestedParts from live row', () {
      final parsed = parsePartsRequestFields({
        'requestedBy': 'tech-1',
        'requestedParts': [
          {
            'inventoryItemId': 'inv-9',
            'name': 'Bolt',
            'quantity': 2,
            'reason': 'replace',
            'priority': 'urgent',
          },
        ],
      });

      expect(parsed.technicianId, 'tech-1');
      expect(parsed.inventoryItemId, 'inv-9');
      expect(parsed.quantity, 2);
      expect(parsed.reason, 'replace');
      expect(parsed.priorityName, 'urgent');

      final model = PartsRequest.fromMap({
        'id': 'pr-2',
        'workOrderId': 'wo-2',
        'requestedBy': 'tech-1',
        'requestedParts': [
          {
            'inventoryItemId': 'inv-9',
            'quantity': 2,
            'reason': 'replace',
            'priority': 'urgent',
          },
        ],
        'status': 'pending',
        'requestedAt': '2026-07-20T10:00:00.000Z',
        'createdAt': '2026-07-20T10:00:00.000Z',
        'updatedAt': '2026-07-20T10:00:00.000Z',
      });
      expect(model.technicianId, 'tech-1');
      expect(model.inventoryItemId, 'inv-9');
      expect(model.quantity, 2);
    });
  });
}
