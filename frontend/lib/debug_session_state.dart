import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/app_auth_service.dart';
import 'services/api_service.dart';

Future<void> debugCurrentSession() async {
  print('🔍 DEBUGGING CURRENT SESSION STATE');
  print('==================================');

  try {
    // Check stored tokens
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final idToken = prefs.getString('id_token');
    final refreshToken = prefs.getString('refresh_token');

    print('🔍 Stored tokens:');
    print(
        '   - Access token: ${accessToken != null ? "EXISTS (${accessToken.length} chars)" : "MISSING"}');
    print(
        '   - ID token: ${idToken != null ? "EXISTS (${idToken.length} chars)" : "MISSING"}');
    print(
        '   - Refresh token: ${refreshToken != null ? "EXISTS (${refreshToken.length} chars)" : "MISSING"}');

    if (accessToken != null) {
      print('   - Access token preview: ${accessToken.substring(0, 50)}...');
    }

    // Check if user is signed in
    print('\n🔍 Checking authentication state...');
    final isSignedIn = await AppAuthService.isSignedIn();
    print('   - Is signed in: $isSignedIn');

    // Try to get current user
    print('\n🔍 Getting current user...');
    final currentUser = await AppAuthService.getCurrentUser();
    print('   - Current user: ${currentUser != null ? "FOUND" : "NULL"}');

    if (currentUser != null) {
      print('   - User data: $currentUser');
    }

    // Try to get businesses
    print('\n🔍 Getting user businesses...');
    try {
      final apiService = ApiService();
      final businesses = await apiService.getUserBusinesses();
      print('   - Businesses found: ${businesses.length}');

      for (int i = 0; i < businesses.length; i++) {
        final business = businesses[i];
        print(
            '   - Business $i: ${business['businessName']} (ID: ${business['businessId']})');
        print('   - Business email: ${business['email']}');
      }
    } catch (e) {
      print('   - Error getting businesses: $e');
    }

    print('\n✅ Session debug complete');
  } catch (e) {
    print('❌ Error during session debug: $e');
  }
}

void main() async {
  await debugCurrentSession();
  exit(0);
}
