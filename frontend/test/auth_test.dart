import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/services/app_auth_service.dart';
import '../lib/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Authentication Tests', () {
    setUp(() {
      // Set up shared preferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    test('isSignedIn should return true when access token is stored', () async {
      // Set up mock token in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', 'mock_access_token');

      final isSignedIn = await AppAuthService.isSignedIn();
      expect(isSignedIn, true);
    });

    test('isSignedIn should return false when no token is stored', () async {
      final isSignedIn = await AppAuthService.isSignedIn();
      expect(isSignedIn, false);
    });

    test('getCurrentUser should return stored user data', () async {
      // Set up mock user data in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'user_data', '{"email": "test@example.com", "success": true}');

      final currentUser = await AppAuthService.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!['email'], 'test@example.com');
    });
  });
}
