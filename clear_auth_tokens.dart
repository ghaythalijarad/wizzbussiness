import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🧹 Clearing authentication tokens...');

  try {
    final prefs = await SharedPreferences.getInstance();

    // Clear all auth-related tokens
    await prefs.remove('access_token');
    await prefs.remove('id_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');

    print('✅ Authentication tokens cleared successfully');
    print('🔄 Restart the app to see the login page');
  } catch (e) {
    print('❌ Error clearing tokens: $e');
  }

  exit(0);
}
