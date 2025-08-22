import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Simple script to test current authentication state
void main() async {
  print('🔍 TESTING CURRENT AUTHENTICATION STATE');
  print('======================================');

  try {
    // Check stored tokens
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final idToken = prefs.getString('id_token');
    final refreshToken = prefs.getString('refresh_token');

    print('\n📱 Stored Tokens:');
    print(
        '   Access Token: ${accessToken != null ? "EXISTS (${accessToken.length} chars)" : "MISSING"}');
    print(
        '   ID Token: ${idToken != null ? "EXISTS (${idToken.length} chars)" : "MISSING"}');
    print(
        '   Refresh Token: ${refreshToken != null ? "EXISTS (${refreshToken.length} chars)" : "MISSING"}');

    if (accessToken != null) {
      print('\n🔍 Access Token Analysis:');
      print('   Length: ${accessToken.length}');
      print(
          '   First 50 chars: ${accessToken.substring(0, accessToken.length > 50 ? 50 : accessToken.length)}...');
      print(
          '   Contains newlines: ${accessToken.contains('\n') || accessToken.contains('\r')}');
      print('   Contains spaces: ${accessToken.contains(' ')}');
      print(
          '   Contains invalid chars: ${accessToken.contains(RegExp(r'[^\w\-_.=]'))}');

      // Check JWT format
      final parts = accessToken.split('.');
      print('   JWT parts count: ${parts.length} (should be 3)');

      if (parts.length == 3) {
        print('   Valid JWT format: ✅');
      } else {
        print('   Invalid JWT format: ❌');
      }

      // Test authorization header format
      final authHeader = 'Bearer $accessToken';
      print('\n🔑 Authorization Header Test:');
      print('   Header length: ${authHeader.length}');
      print('   Valid format: ${authHeader.startsWith('Bearer ') ? "✅" : "❌"}');

      // Check for problematic characters in auth header
      final invalidHeaderChars = authHeader.contains(RegExp(r'[\r\n\t=]'));
      print(
          '   Contains invalid header chars: ${invalidHeaderChars ? "❌" : "✅"}');

      // Test actual API call
      print('\n🧪 Testing API Call:');
      try {
        final response = await http.get(
          Uri.parse(
              'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/user-businesses'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
        );

        print('   Response Status: ${response.statusCode}');
        print('   Response Body: ${response.body}');

        if (response.statusCode == 200) {
          print('   API Call: ✅ SUCCESS');
        } else {
          print('   API Call: ❌ FAILED');
          if (response.body.contains('Invalid key=value pair')) {
            print('   🚨 FOUND TOKEN CORRUPTION ISSUE!');
          }
        }
      } catch (e) {
        print('   API Call Exception: $e');
      }
    } else {
      print('\n⚠️ No access token found - user not signed in');
    }
  } catch (e) {
    print('❌ Error during test: $e');
  }

  exit(0);
}
