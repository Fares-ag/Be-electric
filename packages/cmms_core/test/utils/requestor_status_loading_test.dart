import 'package:cmms_core/utils/requestor_status_loading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowRequestorStatusInitialLoading', () {
    test('shows loading when work orders are loading and list is empty', () {
      expect(
        shouldShowRequestorStatusInitialLoading(
          isWorkOrdersLoading: true,
          requestCount: 0,
        ),
        isTrue,
      );
    });

    test('hides loading when cached work orders exist', () {
      expect(
        shouldShowRequestorStatusInitialLoading(
          isWorkOrdersLoading: true,
          requestCount: 3,
        ),
        isFalse,
      );
    });

    test('hides loading when fetch finished with empty list', () {
      expect(
        shouldShowRequestorStatusInitialLoading(
          isWorkOrdersLoading: false,
          requestCount: 0,
        ),
        isFalse,
      );
    });

    test('hides loading when fetch finished with data', () {
      expect(
        shouldShowRequestorStatusInitialLoading(
          isWorkOrdersLoading: false,
          requestCount: 2,
        ),
        isFalse,
      );
    });
  });
}
