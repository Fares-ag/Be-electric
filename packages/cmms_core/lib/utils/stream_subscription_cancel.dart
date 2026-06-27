import 'dart:async';

/// Cancels [subscription] if active. Safe to call with null.
Future<void> cancelStreamSubscription(StreamSubscription<dynamic>? subscription) async {
  await subscription?.cancel();
}

/// Cancels multiple subscriptions in sequence.
Future<void> cancelStreamSubscriptions(
  List<StreamSubscription<dynamic>?> subscriptions,
) async {
  for (final subscription in subscriptions) {
    await cancelStreamSubscription(subscription);
  }
}
