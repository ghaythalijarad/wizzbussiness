// Session Management Fix - Clear and restart session
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'services/app_auth_service.dart';
import 'services/api_service.dart';

class SessionFixer {
  static Future<void> clearAllSessionData() async {
    print('🧹 CLEARING ALL SESSION DATA');
    print('============================');

    try {
      // 1. Clear SharedPreferences tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('id_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');
      await prefs.remove('current_business_id');
      await prefs.remove('last_activity');
      print('✅ SharedPreferences cleared');

      // 2. Sign out from Cognito/Amplify
      try {
        await Amplify.Auth.signOut();
        print('✅ Amplify/Cognito signed out');
      } catch (e) {
        print('⚠️ Amplify signout error (may not be signed in): $e');
      }

      // 3. Clear any other cached data
      await prefs.clear(); // Nuclear option - clears everything
      print('✅ All cached data cleared');

      print('🎉 Session cleared successfully! Please restart the app.');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  static Future<void> validateCurrentSession() async {
    print('🔍 VALIDATING CURRENT SESSION');
    print('=============================');

    try {
      // Check what's stored
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      print('📦 Stored keys: $keys');

      for (String key in keys) {
        if (key.contains('token') ||
            key.contains('user') ||
            key.contains('business')) {
          final value = prefs.getString(key);
          print('   $key: ${value != null ? "${value.length} chars" : "null"}');
        }
      }

      // Check authentication state
      final isSignedIn = await AppAuthService.isSignedIn();
      print('🔐 Is signed in: $isSignedIn');

      // Try to get current user
      final currentUser = await AppAuthService.getCurrentUser();
      print('👤 Current user: ${currentUser != null ? "Found" : "Not found"}');

      if (currentUser != null) {
        print('   Email: ${currentUser['email']}');
        print('   User ID: ${currentUser['userId']}');
      }

      // Try to get businesses
      try {
        final businesses = await ApiService().getUserBusinesses();
        print('🏢 Businesses: ${businesses.length} found');

        for (var business in businesses) {
          print(
              '   - ${business['businessName']} (ID: ${business['businessId']})');
          print('   - Email: ${business['email']}');
          print('   - Status: ${business['status']}');
        }
      } catch (e) {
        print('❌ Error getting businesses: $e');
      }
    } catch (e) {
      print('❌ Validation error: $e');
    }
  }

  static Future<void> performFreshLogin(String email, String password) async {
    print('🔄 PERFORMING FRESH LOGIN');
    print('=========================');
    print('📧 Email: $email');

    try {
      // First clear everything
      await clearAllSessionData();

      // Wait a bit for cleanup
      await Future.delayed(Duration(seconds: 1));

      // Attempt fresh login
      final result = await AppAuthService.signIn(
        email: email,
        password: password,
      );

      if (result.success) {
        print('✅ Fresh login successful!');
        print('👤 User: ${result.user}');
        print('🏢 Businesses: ${result.businesses.length}');

        // Validate the new session
        await validateCurrentSession();
      } else {
        print('❌ Fresh login failed: ${result.message}');
      }
    } catch (e) {
      print('❌ Fresh login error: $e');
    }
  }
}
