// Common helpers for unit tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Mock navigation observer for testing navigation
class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> routes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.remove(route);
  }
}

/// Pump a widget with providers for testing
Future<void> pumpWidgetWithProviders(
  WidgetTester tester,
  Widget child, {
  List<ChangeNotifierProvider>? providers,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: providers ?? [],
      child: MaterialApp(
        home: child,
      ),
    ),
  );
}

/// Wait for async operations to complete
Future<void> pumpAndSettleWithTimeout(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(timeout);
}

/// Create a simple test MaterialApp wrapper
Widget createTestApp(Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );

/// Tap a widget by key
Future<void> tapByKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Tap a widget by text
Future<void> tapByText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Enter text into a TextField
Future<void> enterText(WidgetTester tester, Key key, String text) async {
  await tester.enterText(find.byKey(key), text);
  await tester.pumpAndSettle();
}

/// Verify a widget exists
void expectWidgetExists(Finder finder) {
  expect(finder, findsOneWidget);
}

/// Verify a widget does not exist
void expectWidgetNotExists(Finder finder) {
  expect(finder, findsNothing);
}

/// Verify text exists
void expectTextExists(String text) {
  expect(find.text(text), findsOneWidget);
}

/// Verify text does not exist
void expectTextNotExists(String text) {
  expect(find.text(text), findsNothing);
}
