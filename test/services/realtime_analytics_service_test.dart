import 'package:flutter_test/flutter_test.dart';

import 'package:qauto_cmms/models/analytics_models.dart';

void main() {
  group('RealtimeAnalyticsService mapping compatibility', () {
    test('MaintenanceDataPoint.fromJson maps Firestore-like payload', () {
      final map = <String, dynamic>{
        'date': DateTime(2025, 1, 2, 3, 4, 5).toIso8601String(),
        'workOrders': 5,
        'completed': 3,
        'mttr': 7.5,
      };

      final dp = MaintenanceDataPoint.fromJson(map);
      expect(dp.date.year, 2025);
      expect(dp.workOrders, 5);
      expect(dp.completed, 3);
      expect(dp.mttr, 7.5);
    });

    test('KPIMetrics.fromJson maps numeric fields', () {
      final map = <String, dynamic>{
        'mttr': 4.2,
        'mtbf': 120.0,
        'assetUptime': 99.5,
        'completionRate': 75.0,
        'averageResponseTime': 2.1,
        'averageTAT': 1.7,
        'complianceRate': 88.0,
      };

      final kpis = KPIMetrics.fromJson(map);
      expect(kpis.mttr, 4.2);
      expect(kpis.mtbf, 120.0);
      expect(kpis.assetUptime, 99.5);
      expect(kpis.completionRate, 75.0);
      expect(kpis.averageResponseTime, 2.1);
      expect(kpis.averageTAT, 1.7);
      expect(kpis.complianceRate, 88.0);
    });
  });
}


