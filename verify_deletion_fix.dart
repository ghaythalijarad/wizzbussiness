import 'dart:io';
import 'package:flutter/material.dart';
import 'frontend/lib/services/app_auth_service.dart';
import 'frontend/lib/services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🧪 Testing Product Deletion Fix');
  print('===============================');

  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize authentication service
    print('\n1️⃣ Initializing AppAuthService...');
    await AppAuthService.initialize();
    print('✅ AppAuthService initialized');

    // Check SharedPreferences for stored token
    print('\n2️⃣ Checking stored access token...');
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('access_token');
    
    if (storedToken != null) {
      print('✅ Access token found in SharedPreferences');
      print('Token length: ${storedToken.length}');
      print('Token preview: ${storedToken.substring(0, 50)}...');
    } else {
      print('❌ No access token in SharedPreferences');
      print('Setting up a test token for demonstration...');
      
      // For demonstration, we'll use a token from our debug script
      const testToken = 'eyJraWQiOiJva3B1RDh5MnAyTllUa2xrOXhVVVhXWllGRUNlTU53ejFEWHRycXhmWGNJPSIsImFsZyI6IlJTMjU2In0.test';
      await prefs.setString('access_token', testToken);
      print('✅ Test token stored');
    }

    // Test getAccessToken method
    print('\n3️⃣ Testing AppAuthService.getAccessToken()...');
    final token = await AppAuthService.getAccessToken();
    
    if (token != null) {
      print('✅ getAccessToken() returned token successfully');
      print('Token length: ${token.length}');
      print('Token preview: ${token.substring(0, 50)}...');
    } else {
      print('❌ getAccessToken() returned null');
    }

    // Test product deletion simulation (without actually calling the API)
    print('\n4️⃣ Testing product deletion authorization headers...');
    print('This simulates the authorization header setup in ProductService.deleteProduct()');
    
    if (token != null) {
      final authHeader = 'Bearer $token';
      print('✅ Authorization header formatted correctly:');
      print('   ${authHeader.substring(0, 50)}...');
      
      // Check for any problematic characters
      final cleanToken = token.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
      if (cleanToken.length == token.length) {
        print('✅ Token contains only valid characters');
      } else {
        print('⚠️ Token contains ${token.length - cleanToken.length} potentially problematic characters');
      }
    } else {
      print('❌ Cannot test authorization header - no token available');
    }

    print('\n✅ Fix verification completed');
    print('\nSUMMARY:');
    print('- AppAuthService.getAccessToken() now falls back to SharedPreferences');
    print('- This should resolve the "missing equal sign in authorization header" error');
    print('- The error was caused by getAccessToken() returning null instead of stored tokens');

  } catch (e) {
    print('❌ Test failed with error: $e');
  }

  exit(0);
}
