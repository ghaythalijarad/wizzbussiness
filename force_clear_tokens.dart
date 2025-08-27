#!/usr/bin/env dart

// Force clear all corrupted tokens and session data
import 'dart:io';

import 'frontend/lib/utils/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  print('🧹 FORCE CLEAR ALL TOKENS AND SESSION DATA');
  print('=' * 50);

  try {
    // Clear via TokenManager
    await TokenManager.clearAccessToken();
    print('✅ TokenManager cleared');

    // Clear via SharedPreferences directly
    final prefs = await SharedPreferences.getInstance();
    
    // Remove all auth-related keys
    final keysToRemove = [
      'access_token',
      'id_token', 
      'refresh_token',
      'user_data',
      'user',
      'current_business_id',
      'last_activity',
      'auth_token',
      'bearer_token',
    ];

    for (String key in keysToRemove) {
      await prefs.remove(key);
      print('✅ Removed $key');
    }

    // Nuclear option - clear everything
    await prefs.clear();
    print('✅ Cleared all SharedPreferences');

    print('\n🎉 COMPLETE TOKEN CLEANUP FINISHED');
    print('📱 Please restart the Flutter app and sign in again');
    print('🔐 This will generate a fresh, clean token');

  } catch (e) {
    print('❌ Error during cleanup: $e');
  }
}
