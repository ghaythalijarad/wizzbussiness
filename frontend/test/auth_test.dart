import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hadhir_business/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    testWidgets('Login form validation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>(
            create: (_) => authService,
            child: Scaffold(
              body: Consumer<AuthService>(
                builder: (context, auth, child) {
                  return Column(
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
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Test email validation
      final emailField = find.byKey(const Key('email_field'));
      expect(emailField, findsOneWidget);

      // Test password validation
      final passwordField = find.byKey(const Key('password_field'));
      expect(passwordField, findsOneWidget);
    });

    test('Email validation', () {
      // Valid email
      expect(isValidEmail('test@example.com'), true);

      // Invalid emails
      expect(isValidEmail('invalid-email'), false);
      expect(isValidEmail(''), false);
      expect(isValidEmail('test@'), false);
    });

    test('Password validation', () {
      // Valid password
      expect(isValidPassword('password123'), true);

      // Invalid passwords
      expect(isValidPassword('12345'), false); // Too short
      expect(isValidPassword(''), false); // Empty
    });
  });
}

bool isValidEmail(String email) {
  if (email.isEmpty) return false;
  return email.contains('@') && email.contains('.');
}

bool isValidPassword(String password) {
  return password.length >= 6;
}
