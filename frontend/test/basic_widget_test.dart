import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('Simple app smoke test', (WidgetTester tester) async {
      // Build a simple app and verify it renders
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Test App')),
          body: const Center(
            child: Text('Hello World'),
          ),
        ),
      ));

      // Verify the app rendered without errors
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('Button tap test', (WidgetTester tester) async {
      int counter = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Text('Count: $counter'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        counter++;
                      });
                    },
                    child: const Text('Increment'),
                  ),
                ],
              );
            },
          ),
        ),
      ));

      // Initial state
      expect(find.text('Count: 0'), findsOneWidget);

      // Tap the button
      await tester.tap(find.text('Increment'));
      await tester.pump();

      // Verify counter incremented
      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Count: 0'), findsNothing);
    });

    testWidgets('Form validation test', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('email_field'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: const Key('password_field'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password too short';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    formKey.currentState?.validate();
                  },
                  child: const Text('Validate'),
                ),
              ],
            ),
          ),
        ),
      ));

      // Test form validation without input
      await tester.tap(find.text('Validate'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Test with invalid email
      await tester.enterText(
          find.byKey(const Key('email_field')), 'invalid-email');
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.tap(find.text('Validate'));
      await tester.pump();

      expect(find.text('Invalid email format'), findsOneWidget);
      expect(find.text('Password too short'), findsOneWidget);

      // Test with valid input
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Validate'));
      await tester.pump();

      expect(find.text('Invalid email format'), findsNothing);
      expect(find.text('Password too short'), findsNothing);
    });
  });

  group('Email Validation Tests', () {
    test('Email validation helper', () {
      bool isValidEmail(String email) {
        if (email.isEmpty) return false;
        if (!email.contains('@')) return false;
        final parts = email.split('@');
        if (parts.length != 2) return false;
        if (parts[0].isEmpty || parts[1].isEmpty) return false;
        if (!parts[1].contains('.')) return false;
        return true;
      }

      // Valid emails
      expect(isValidEmail('test@example.com'), true);
      expect(isValidEmail('user@domain.org'), true);
      expect(isValidEmail('admin@company.co.uk'), true);

      // Invalid emails
      expect(isValidEmail(''), false);
      expect(isValidEmail('invalid'), false);
      expect(isValidEmail('@domain.com'), false);
      expect(isValidEmail('user@'), false);
      expect(isValidEmail('user.domain.com'), false);
      expect(isValidEmail('user@@domain.com'), false);
    });
  });
}
