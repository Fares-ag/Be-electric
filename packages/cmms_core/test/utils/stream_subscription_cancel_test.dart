import 'dart:async';

import 'package:cmms_core/utils/stream_subscription_cancel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cancelStreamSubscription', () {
    test('cancelled subscription stops receiving events', () async {
      final events = <int>[];
      final controller = StreamController<int>();
      StreamSubscription<int>? subscription = controller.stream.listen(events.add);

      await cancelStreamSubscription(subscription);
      subscription = null;

      controller.add(1);
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });
  });

  group('cancelStreamSubscriptions', () {
    test('cancels all subscriptions before re-subscribe pattern', () async {
      final events = <int>[];
      final controller = StreamController<int>.broadcast();

      StreamSubscription<int>? first = controller.stream.listen(events.add);
      StreamSubscription<int>? second = controller.stream.listen(events.add);

      await cancelStreamSubscriptions([first, second]);
      first = null;
      second = null;

      final third = controller.stream.listen(events.add);
      controller.add(1);
      await Future<void>.delayed(Duration.zero);

      expect(events, [1]);
      await cancelStreamSubscription(third);
      await controller.close();
    });

    test('handles null subscriptions safely', () async {
      await expectLater(
        cancelStreamSubscriptions([null, null]),
        completes,
      );
    });
  });
}
