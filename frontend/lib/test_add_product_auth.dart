import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/app_auth_service.dart';
import 'config/app_config.dart';

/// Test script to identify the authentication header issue when adding products
class TestAddProductAuth {
  static Future<void> testAddProductAuthentication() async {
    print('🧪 TESTING ADD PRODUCT AUTHENTICATION');
    print('=====================================\n');

    try {
      // Step 1: Get the access token
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        print('❌ No access token found');
        return;
      }

      print('✅ Token retrieved successfully');
      print('📏 Token length: ${token.length}');
      print('📝 Token preview: ${token.substring(0, 50)}...');

      // Step 2: Prepare test product data
      final testProductData = {
        'name': 'Test Product Auth',
        'description': 'Testing authentication for product creation',
        'price': 9.99,
        'categoryId': 'test-category',
        'isAvailable': true,
      };

      // Step 3: Test the authorization header format
      final authHeader = 'Bearer $token';
      print('\n🔑 Authorization header:');
      print('📏 Header length: ${authHeader.length}');
      print('📝 Header format: Bearer ${token.substring(0, 30)}...');

      // Check for common issues
      print('\n🔍 Token validation:');
      print('✅ Token is not empty: ${token.isNotEmpty}');
      print('✅ Token has no leading/trailing spaces: ${token == token.trim()}');
      print('✅ Token contains no newlines: ${!token.contains('\n') && !token.contains('\r')}');
      print('✅ Header starts with "Bearer ": ${authHeader.startsWith('Bearer ')}');

      // Step 4: Make the POST request to create product
      print('\n📤 Making POST request to create product...');
      final url = Uri.parse('${AppConfig.baseUrl}/products');
      print('🌐 URL: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      };

      print('\n📋 Request headers:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          print('  $key: Bearer ${value.substring(7, 37)}...[token]');
        } else {
          print('  $key: $value');
        }
      });

      print('\n📦 Request body:');
      print(jsonEncode(testProductData));

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(testProductData),
      );

      print('\n📥 RESPONSE:');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 401) {
        print('\n❌ AUTHENTICATION FAILED');
        print('This indicates an issue with the authorization header format');
        
        // Try to decode the response to get more details
        try {
          final errorData = jsonDecode(response.body);
          print('Error details: $errorData');
        } catch (e) {
          print('Could not decode error response: $e');
        }
      } else if (response.statusCode == 400) {
        print('\n⚠️  BAD REQUEST');
        print('This might indicate a missing equal sign or header parsing issue');
        
        try {
          final errorData = jsonDecode(response.body);
          print('Error details: $errorData');
        } catch (e) {
          print('Could not decode error response: $e');
        }
      } else if (response.statusCode == 201) {
        print('\n✅ SUCCESS: Product created successfully');
        // Clean up - delete the test product
        try {
          final responseData = jsonDecode(response.body);
          final productId = responseData['product']['id'] ?? responseData['product']['productId'];
          if (productId != null) {
            print('🧹 Cleaning up test product: $productId');
            await http.delete(
              Uri.parse('${AppConfig.baseUrl}/products/$productId'),
              headers: headers,
            );
          }
        } catch (e) {
          print('Could not clean up test product: $e');
        }
      } else {
        print('\n⚠️  UNEXPECTED RESPONSE: ${response.statusCode}');
      }

    } catch (e, stackTrace) {
      print('❌ ERROR: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Test just the headers without actually creating a product
  static Future<void> testHeadersOnly() async {
    print('🧪 TESTING HEADERS ONLY');
    print('=======================\n');

    try {
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        print('❌ No access token found');
        return;
      }

      // Test with GET /products first (should work)
      print('📤 Testing GET /products...');
      final getResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET Status: ${getResponse.statusCode}');
      if (getResponse.statusCode != 200) {
        print('GET Response: ${getResponse.body}');
      } else {
        print('✅ GET request works - token is valid');
      }

    } catch (e) {
      print('❌ ERROR: $e');
    }
  }
}
