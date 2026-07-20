import 'package:cmms_core/utils/supabase_write_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ensureRowsUpdated', () {
    test('passes when response has rows', () {
      expect(
        () => ensureRowsUpdated(
          [
            {'id': 'wo-1'},
          ],
          entityLabel: 'Work order',
        ),
        returnsNormally,
      );
    });

    test('throws when response is empty list', () {
      expect(
        () => ensureRowsUpdated([], entityLabel: 'Work order'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('no row updated'),
          ),
        ),
      );
    });

    test('throws when response is null', () {
      expect(
        () => ensureRowsUpdated(null, entityLabel: 'Work order'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
