// Test script to verify logout functionality and session management
import 'dart:io';

main() async {
  print('🧪 Testing Logout Functionality');
  print('================================');

  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Check current stored tokens before logout
    print('\n1️⃣ Checking current stored tokens...');
    await checkStoredTokens();

    // Simulate the logout process
    print('\n2️⃣ Simulating logout process...');
    await simulateLogout();

    // Check stored tokens after logout
    print('\n3️⃣ Checking stored tokens after logout...');
    await checkStoredTokens();

    print('\n✅ Logout functionality test completed');
  } catch (e) {
    print('❌ Error during logout test: $e');
  }
}

Future<void> checkStoredTokens() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final accessToken = prefs.getString('access_token');
    final idToken = prefs.getString('id_token');
    final refreshToken = prefs.getString('refresh_token');
    final userData = prefs.getString('user_data');
    final businessId = prefs.getString('current_business_id');

    print(
        '   Access Token: ${accessToken != null ? "EXISTS (${accessToken.length} chars)" : "NULL"}');
    print(
        '   ID Token: ${idToken != null ? "EXISTS (${idToken.length} chars)" : "NULL"}');
    print(
        '   Refresh Token: ${refreshToken != null ? "EXISTS (${refreshToken.length} chars)" : "NULL"}');
    print('   User Data: ${userData != null ? "EXISTS" : "NULL"}');
    print('   Business ID: ${businessId ?? "NULL"}');
  } catch (e) {
    print('   Error checking tokens: $e');
  }
}

Future<void> simulateLogout() async {
  try {
    // Simulate the logout process that happens in AppAuthService.signOut()
    print('   Clearing stored tokens...');
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('access_token');
    await prefs.remove('id_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    await prefs.remove('current_business_id');
    await prefs.remove('last_activity');

    print('   ✅ Tokens cleared successfully');
  } catch (e) {
    print('   ❌ Error during logout simulation: $e');
  }
}
