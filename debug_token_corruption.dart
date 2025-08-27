#!/usr/bin/env dart

// Debug script to identify and fix token corruption in location settings
import 'dart:io';

import 'frontend/lib/services/app_auth_service.dart';
import 'frontend/lib/utils/token_manager.dart';
import 'frontend/lib/services/auth_header_builder.dart';
import 'frontend/lib/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  print('🔍 TOKEN CORRUPTION DEBUG - LOCATION SETTINGS');
  print('=' * 60);

  try {
    // Step 1: Check all token storage locations
    print('\n📱 STEP 1: Checking All Token Storage Locations');
    print('-' * 50);

    final prefs = await SharedPreferences.getInstance();
    
    // Check direct SharedPreferences storage
    final rawToken = prefs.getString('access_token');
    print('📦 Raw SharedPreferences token: ${rawToken != null ? "EXISTS" : "NULL"}');
    if (rawToken != null) {
      print('   Length: ${rawToken.length}');
      print('   First 20 chars: "${rawToken.substring(0, rawToken.length > 20 ? 20 : rawToken.length)}"');
      print('   Last 20 chars: "...${rawToken.substring(rawToken.length > 20 ? rawToken.length - 20 : 0)}"');
      
      // Check for corruption markers
      final hasLeadingEquals = rawToken.startsWith('=');
      final hasPipes = rawToken.contains('|');
      final hasNewlines = rawToken.contains('\n') || rawToken.contains('\r');
      
      print('   🚨 Corruption detected:');
      print('      - Leading equals: $hasLeadingEquals');
      print('      - Contains pipes: $hasPipes');
      print('      - Contains newlines: $hasNewlines');
      
      if (hasLeadingEquals || hasPipes || hasNewlines) {
        print('   ⚠️ CORRUPTED TOKEN FOUND - This is the source of the error!');
      }
    }

    // Step 2: Check TokenManager retrieval
    print('\n🔧 STEP 2: Testing TokenManager Retrieval');
    print('-' * 50);

    final tokenManagerToken = await TokenManager.getAccessToken();
    print('🛠️ TokenManager token: ${tokenManagerToken != null ? "EXISTS" : "NULL"}');
    if (tokenManagerToken != null) {
      print('   Length: ${tokenManagerToken.length}');
      print('   First 20 chars: "${tokenManagerToken.substring(0, tokenManagerToken.length > 20 ? 20 : tokenManagerToken.length)}"');
      
      if (rawToken != null && rawToken != tokenManagerToken) {
        print('   ✅ TokenManager successfully cleaned the token!');
        print('   📊 Original length: ${rawToken.length}');
        print('   📊 Cleaned length: ${tokenManagerToken.length}');
      }
    }

    // Step 3: Check AppAuthService retrieval
    print('\n🔐 STEP 3: Testing AppAuthService Token Retrieval');
    print('-' * 50);

    final appAuthToken = await AppAuthService.getAccessToken();
    print('🔑 AppAuthService token: ${appAuthToken != null ? "EXISTS" : "NULL"}');
    if (appAuthToken != null) {
      print('   Length: ${appAuthToken.length}');
      print('   Matches TokenManager: ${appAuthToken == tokenManagerToken}');
    }

    // Step 4: Check AuthHeaderBuilder
    print('\n📋 STEP 4: Testing AuthHeaderBuilder');
    print('-' * 50);

    try {
      final headers = await AuthHeaderBuilder.build();
      final authHeader = headers['Authorization'];
      print('🔗 Authorization header: ${authHeader != null ? "EXISTS" : "NULL"}');
      if (authHeader != null) {
        print('   Full header: "$authHeader"');
        
        // Extract token from "Bearer TOKEN" format
        if (authHeader.startsWith('Bearer ')) {
          final extractedToken = authHeader.substring(7);
          print('   Extracted token length: ${extractedToken.length}');
          print('   First 20 chars: "${extractedToken.substring(0, extractedToken.length > 20 ? 20 : extractedToken.length)}"');
          
          // Check if this matches what we expect
          print('   Matches TokenManager: ${extractedToken == tokenManagerToken}');
          print('   Matches AppAuthService: ${extractedToken == appAuthToken}');
        }
      }
    } catch (e) {
      print('❌ AuthHeaderBuilder error: $e');
    }

    // Step 5: Attempt to fix by clearing and re-storing clean token
    print('\n🔧 STEP 5: Attempting Complete Token Cleanup');
    print('-' * 50);

    if (rawToken != null && (rawToken.startsWith('=') || rawToken.contains('|'))) {
      print('🧹 Corrupted token detected - performing complete cleanup...');
      
      // Clear everything
      await TokenManager.clearAccessToken();
      await prefs.remove('access_token');
      await prefs.remove('id_token');
      await prefs.remove('refresh_token');
      
      print('✅ Cleared all stored tokens');
      
      // Try to get a fresh token from Cognito if available
      print('🔄 Attempting to get fresh token from Cognito...');
      try {
        // This will force AppAuthService to get a fresh token from Cognito
        final freshToken = await AppAuthService.getAccessToken();
        if (freshToken != null && freshToken.isNotEmpty) {
          print('✅ Fresh token obtained from Cognito');
          print('   Length: ${freshToken.length}');
          print('   Clean: ${!freshToken.startsWith('=') && !freshToken.contains('|')}');
        } else {
          print('❌ Could not get fresh token - user may need to re-login');
        }
      } catch (e) {
        print('❌ Error getting fresh token: $e');
        print('💡 User will need to sign out and sign back in');
      }
    } else {
      print('✅ Token appears clean - no cleanup needed');
    }

    // Step 6: Test location settings API call
    print('\n🌍 STEP 6: Testing Location Settings API Call');
    print('-' * 50);

    try {
      final apiService = ApiService();
      print('🔍 Attempting to get business location settings...');
      
      final locationSettings = await apiService.getBusinessLocationSettings();
      print('✅ Location settings retrieved successfully!');
      print('📍 Settings: $locationSettings');
    } catch (e) {
      print('❌ Location settings API call failed: $e');
      
      if (e.toString().contains('Invalid key=value pair')) {
        print('🚨 CONFIRMATION: This is the authorization header corruption issue');
        print('💡 Solution: User needs to sign out and sign back in to get a clean token');
      }
    }

    print('\n📋 SUMMARY AND RECOMMENDATIONS');
    print('=' * 60);
    
    if (rawToken != null && (rawToken.startsWith('=') || rawToken.contains('|'))) {
      print('🚨 ISSUE CONFIRMED: Corrupted token found in SharedPreferences');
      print('🔧 ACTION REQUIRED: Complete session cleanup and re-login');
      print('');
      print('📱 IMMEDIATE FIX STEPS:');
      print('1. User should sign out completely');
      print('2. Clear all app data/cache');
      print('3. Sign back in to get a fresh, clean token');
      print('4. Try location settings save again');
    } else {
      print('✅ No obvious token corruption detected');
      print('🔍 If issue persists, check backend response format');
    }

  } catch (e, stackTrace) {
    print('💥 Debug script error: $e');
    print('📚 Stack trace: $stackTrace');
  }
}
