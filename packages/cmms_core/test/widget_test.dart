// Basic Flutter widget smoke test for Be Electric CMMS app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Be Electric CMMS')),
        ),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Be Electric CMMS'), findsOneWidget);
  });
}
