import 'package:flutter_test/flutter_test.dart';

import 'package:qauto_cmms/models/asset.dart';
import 'package:qauto_cmms/models/pm_task.dart';
import 'package:qauto_cmms/models/work_order.dart';
import 'package:qauto_cmms/services/analytics/analytics_calculator.dart';

void main() {
  group('AnalyticsCalculator', () {
    test('calculates MTTR and completion KPIs with simple data', () async {
      final now = DateTime.now();
      final woCompleted = WorkOrder(
        id: 'wo1',
        ticketNumber: 'T-1',
        problemDescription: 'Fix leak',
        status: WorkOrderStatus.completed,
        createdAt: now.subtract(const Duration(hours: 10)),
        updatedAt: now,
        completedAt: now,
        requestorId: 'u1',
        assetId: 'a1',
      );
      final woOpen = WorkOrder(
        id: 'wo2',
        ticketNumber: 'T-2',
        problemDescription: 'Inspect pump',
        priority: WorkOrderPriority.low,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now,
        requestorId: 'u2',
        assetId: 'a1',
      );

      final assets = <Asset>[
        Asset(
          id: 'a1',
          name: 'Pump-1',
          location: 'Plant A',
          category: 'equipment',
          createdAt: now.subtract(const Duration(days: 100)),
          updatedAt: now,
        ),
      ];

      final pmTasks = <PMTask>[];

      final calculator = AnalyticsCalculator();
      final kpis = await calculator.calculateKPIs(
        workOrders: [woCompleted, woOpen],
        assets: assets,
        pmTasks: pmTasks,
      );

      // MTTR should be close to 10.0 hours for single completed WO
      expect(kpis.mttr, greaterThan(9.0));
      expect(kpis.mttr, lessThan(11.0));

      // Completion rate should be 50%
      expect(kpis.completionRate, closeTo(50.0, 0.001));

      // Uptime for 1 active asset is 100%
      expect(kpis.assetUptime, closeTo(100.0, 0.001));
    });
  });
}


