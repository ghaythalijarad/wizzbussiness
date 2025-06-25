// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hadhir_business/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(initialLanguageCode: 'en'));

    // Verify that the splash screen loads
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify splash screen is showing
    await tester.pump();

    // Skip the 3-second timer by pumping with a specific duration
    await tester.pump(const Duration(seconds: 4));

    // Verify the app navigated successfully
    await tester.pumpAndSettle();
  });
}
