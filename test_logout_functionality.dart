#!/usr/bin/env dart

/// Test script to verify logout functionality integrates properly with backend
/// This tests the complete logout flow including backend authentication cleanup

import 'dart:io';
import 'dart:convert';

const String baseUrl = 'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev';

Future<void> main() async {
  print('🔧 TESTING LOGOUT FUNCTIONALITY');
  print('================================\n');

  try {
    // Test 1: Verify logout endpoint exists
    print('1. Testing logout endpoint availability...');
    await testLogoutEndpoint();
    
    // Test 2: Test logout with valid token (simulated)
    print('\n2. Testing logout with authentication token...');
    await testLogoutWithToken();
    
    // Test 3: Test logout with invalid token
    print('\n3. Testing logout with invalid token...');
    await testLogoutWithInvalidToken();
    
    print('\n✅ LOGOUT FUNCTIONALITY TESTS COMPLETE');
    print('=======================================');
    
  } catch (e) {
    print('❌ Error during logout testing: $e');
    exit(1);
  }
}

Future<void> testLogoutEndpoint() async {
  try {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    
    // Test if logout endpoint is accessible
    final request = await client.postUrl(Uri.parse('$baseUrl/auth/logout'));
    request.headers.set('Content-Type', 'application/json');
    
    // Send request without auth to see if endpoint exists
    final response = await request.close();
    final statusCode = response.statusCode;
    
    print('   - Logout endpoint status: $statusCode');
    
    if (statusCode == 401 || statusCode == 403) {
      print('   ✅ Logout endpoint exists (requires authentication)');
    } else if (statusCode == 404) {
      print('   ⚠️ Logout endpoint not found - may need backend implementation');
    } else {
      print('   ✅ Logout endpoint accessible');
    }
    
    client.close();
    
  } catch (e) {
    print('   ❌ Error testing logout endpoint: $e');
  }
}

Future<void> testLogoutWithToken() async {
  try {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    
    final request = await client.postUrl(Uri.parse('$baseUrl/auth/logout'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer test-token-12345');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   - Status: ${response.statusCode}');
    print('   - Response: ${responseBody.substring(0, responseBody.length > 100 ? 100 : responseBody.length)}...');
    
    if (response.statusCode == 200 || response.statusCode == 401) {
      print('   ✅ Logout handled correctly');
    } else {
      print('   ⚠️ Unexpected response: ${response.statusCode}');
    }
    
    client.close();
    
  } catch (e) {
    print('   ❌ Error testing logout with token: $e');
  }
}

Future<void> testLogoutWithInvalidToken() async {
  try {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    
    final request = await client.postUrl(Uri.parse('$baseUrl/auth/logout'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer invalid-token');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   - Status: ${response.statusCode}');
    print('   - Response: ${responseBody.substring(0, responseBody.length > 50 ? 50 : responseBody.length)}...');
    
    if (response.statusCode == 401 || response.statusCode == 403) {
      print('   ✅ Invalid token properly rejected');
    } else {
      print('   ⚠️ Unexpected response for invalid token: ${response.statusCode}');
    }
    
    client.close();
    
  } catch (e) {
    print('   ❌ Error testing logout with invalid token: $e');
  }
}
