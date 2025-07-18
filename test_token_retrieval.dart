import 'dart:io';
import 'package:flutter/material.dart';
import 'frontend/lib/services/app_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🔍 Testing Token Retrieval');
  print('=========================');

  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize authentication service
    print('\n1️⃣ Initializing AppAuthService...');
    await AppAuthService.initialize();
    print('✅ AppAuthService initialized');

    // Check if user is signed in
    print('\n2️⃣ Checking sign-in status...');
    final isSignedIn = await AppAuthService.isSignedIn();
    print('Is signed in: $isSignedIn');

    // Try to get access token
    print('\n3️⃣ Attempting to get access token...');
    final accessToken = await AppAuthService.getAccessToken();
    if (accessToken != null) {
      print('✅ Access token retrieved successfully');
      print('Token length: ${accessToken.length}');
      print('Token preview: ${accessToken.substring(0, 50)}...');
    } else {
      print('❌ No access token found');
    }

    // Check SharedPreferences directly
    print('\n4️⃣ Checking SharedPreferences directly...');
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('access_token');
    if (storedToken != null) {
      print('✅ Token found in SharedPreferences');
      print('Stored token length: ${storedToken.length}');
      print('Stored token preview: ${storedToken.substring(0, 50)}...');
    } else {
      print('❌ No token in SharedPreferences');
    }

    // List all keys in SharedPreferences
    print('\n5️⃣ All SharedPreferences keys:');
    final keys = prefs.getKeys();
    for (final key in keys) {
      print('  - $key: ${prefs.get(key)?.toString().length ?? 0} chars');
    }

    print('\n✅ Test completed');
  } catch (e) {
    print('❌ Test failed with error: $e');
  }

  exit(0);
}
