import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Test current POST request behavior to verify sanitization
Future<void> main() async {
  print('🧪 Testing POST Request Token Sanitization');
  print('=========================================\n');

  try {
    // Initialize AppAuthService
    await AppAuthService.initialize();

    print('🔑 Checking authentication...');
    final accessToken = await AppAuthService.getAccessToken();
    final idToken = await AppAuthService.getIdToken();

    if (accessToken == null && idToken == null) {
      print('❌ No tokens found. Please sign in first.');
      return;
    }

    print(
      '✅ Access token: ${accessToken != null ? "${accessToken.length} chars" : "none"}',
    );
    print(
      '✅ ID token: ${idToken != null ? "${idToken.length} chars" : "none"}',
    );

    // Test product creation POST request using ApiService
    print('\n🛒 Testing Product Creation POST Request...');

    final apiService = ApiService();

    final testProductData = {
      'name': 'Test Product - Sanitization Check',
      'description': 'Testing if POST requests use sanitized tokens',
      'price': 15.99,
      'categoryId': 'test-category-id',
      'isAvailable': true,
    };

    print('📤 Making POST request to /products...');
    print('📋 Request data: ${jsonEncode(testProductData)}');

    final response = await apiService.makeAuthenticatedRequest(
      method: 'POST',
      path: '/products',
      body: jsonEncode(testProductData),
      preferIdToken: true,
    );

    print('\n📤 Response Status: ${response.statusCode}');
    print('📤 Response Headers: ${response.headers}');
    print('📤 Response Body: ${response.body}');

    // Check for the specific corruption error
    if (response.body.contains('Invalid key=value pair')) {
      print('\n❌ CORRUPTION ERROR DETECTED!');
      print('❌ The "Invalid key=value pair" error is still occurring');
      print(
        '❌ This means POST requests are NOT using the enhanced sanitization',
      );
    } else if (response.statusCode == 401) {
      print('\n⚠️ Authorization error (401) - but NOT the corruption error');
      print(
        '⚠️ This suggests tokens are properly formatted but may be expired/invalid',
      );
    } else if (response.statusCode == 201) {
      print('\n✅ SUCCESS! Product created successfully');
      print('✅ Token sanitization is working for POST requests');
    } else {
      print('\n⚠️ Unexpected response: ${response.statusCode}');
      print('⚠️ But no corruption error, so token format is probably OK');
    }
  } catch (e, stackTrace) {
    print('\n💥 Error during test: $e');
    if (e.toString().contains('Invalid key=value pair')) {
      print('❌ CORRUPTION ERROR in exception!');
      print('❌ The token sanitization is NOT working for POST requests');
    }
    print('📚 Stack trace: $stackTrace');
  }
}
