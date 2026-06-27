import 'package:cmms_core/models/asset.dart';
import 'package:cmms_core/utils/requestor_work_order_asset.dart';
import 'package:flutter_test/flutter_test.dart';

Asset _asset({required String id}) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: id,
    name: 'Test Charger',
    location: 'Bay 1',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('isRequestorPlaceholderChargerAsset', () {
    test('detects siemens and kostad placeholder ids', () {
      expect(isRequestorPlaceholderChargerAsset(_asset(id: 'siemens')), isTrue);
      expect(isRequestorPlaceholderChargerAsset(_asset(id: 'kostad')), isTrue);
      expect(isRequestorPlaceholderChargerAsset(_asset(id: 'SIEMENS')), isTrue);
    });

    test('returns false for real database asset ids', () {
      expect(
        isRequestorPlaceholderChargerAsset(_asset(id: 'AST-001')),
        isFalse,
      );
    });
  });

  group('validateRequestorReviewAsset', () {
    test('allows real asset', () {
      expect(
        validateRequestorReviewAsset(
          asset: _asset(id: 'AST-001'),
          isChargerTypeFlow: true,
          isLoadingChargers: false,
          chargersLoadAttempted: true,
          companyChargerCount: 3,
        ),
        isNull,
      );
    });

    test('blocks placeholder while chargers are loading', () {
      expect(
        validateRequestorReviewAsset(
          asset: _asset(id: 'siemens'),
          isChargerTypeFlow: true,
          isLoadingChargers: true,
          chargersLoadAttempted: false,
          companyChargerCount: 0,
        ),
        contains('loading'),
      );
    });

    test('blocks placeholder when company has no chargers', () {
      expect(
        validateRequestorReviewAsset(
          asset: _asset(id: 'kostad'),
          isChargerTypeFlow: true,
          isLoadingChargers: false,
          chargersLoadAttempted: true,
          companyChargerCount: 0,
        ),
        contains('No chargers'),
      );
    });

    test('blocks placeholder when chargers exist but none selected', () {
      expect(
        validateRequestorReviewAsset(
          asset: _asset(id: 'siemens'),
          isChargerTypeFlow: true,
          isLoadingChargers: false,
          chargersLoadAttempted: true,
          companyChargerCount: 2,
        ),
        contains('select a registered charger'),
      );
    });
  });

  group('resolveRequestorWorkOrderAssetSubmission', () {
    test('returns asset id for registered asset', () {
      final result = resolveRequestorWorkOrderAssetSubmission(
        _asset(id: 'AST-001'),
      );
      expect(result?.assetId, 'AST-001');
      expect(result?.asset.id, 'AST-001');
    });

    test('returns null for placeholder asset', () {
      expect(
        resolveRequestorWorkOrderAssetSubmission(_asset(id: 'siemens')),
        isNull,
      );
    });
  });
}
