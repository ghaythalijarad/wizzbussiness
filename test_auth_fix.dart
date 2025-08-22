import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to verify authentication fix
/// This will test the complete flow without the aggressive token sanitization
Future<void> main() async {
  const String baseUrl =
      'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev';

  print('🧪 TESTING AUTHENTICATION FIX');
  print('==============================\n');

  // Test credentials (replace with actual test account)
  const String testEmail = 'ghaythal.laheebi@gmail.com';
  const String testPassword = 'TestPassword123!';

  try {
    // Step 1: Sign in to get tokens
    print('1. Signing in...');
    final signInResponse = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': testEmail, 'password': testPassword}),
    );

    print('📡 Sign-in status: ${signInResponse.statusCode}');
    print('📄 Sign-in response: ${signInResponse.body}');

    if (signInResponse.statusCode != 200) {
      print('❌ Sign-in failed');
      return;
    }

    final signInData = jsonDecode(signInResponse.body);
    if (signInData['success'] != true) {
      print('❌ Sign-in response indicates failure');
      return;
    }

    // Extract tokens
    final authData = signInData['data'];
    final accessToken = authData['AccessToken'];
    final idToken = authData['IdToken'];

    print('✅ Sign-in successful');
    print('📏 Access token length: ${accessToken?.length}');
    print('📏 ID token length: ${idToken?.length}');
    print('🔑 ID token preview: ${idToken?.substring(0, 50)}...');

    // Step 2: Test API calls with tokens
    print('\n2. Testing API calls with tokens...');

    // Test with ID token (should work for Cognito User Pool authorizers)
    final productsResponse = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    print('📡 Products API status: ${productsResponse.statusCode}');
    print('📄 Products API response: ${productsResponse.body}');

    if (productsResponse.statusCode == 200) {
      print('✅ Products API call successful with ID token');
    } else {
      print('❌ Products API call failed');

      // Try with access token as fallback
      print('\n   Trying with access token...');
      final fallbackResponse = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('📡 Fallback status: ${fallbackResponse.statusCode}');
      print('📄 Fallback response: ${fallbackResponse.body}');

      if (fallbackResponse.statusCode == 200) {
        print('✅ Products API call successful with access token');
      } else {
        print('❌ Both token types failed');
      }
    }

    // Step 3: Test merchant orders endpoint
    print('\n3. Testing merchant orders endpoint...');

    final ordersResponse = await http.get(
      Uri.parse('$baseUrl/auth/user-businesses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    print('📡 User businesses status: ${ordersResponse.statusCode}');
    print('📄 User businesses response: ${ordersResponse.body}');

    if (ordersResponse.statusCode == 200) {
      final businessData = jsonDecode(ordersResponse.body);
      if (businessData['success'] == true &&
          businessData['businesses'] != null) {
        final businesses = businessData['businesses'] as List;
        print('✅ Found ${businesses.length} business(es)');

        if (businesses.isNotEmpty) {
          final businessId = businesses[0]['businessId'];
          print('🏢 Testing with business ID: $businessId');

          // Test merchant orders
          final merchantOrdersResponse = await http.get(
            Uri.parse('$baseUrl/merchant/orders/$businessId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          );

          print(
            '📡 Merchant orders status: ${merchantOrdersResponse.statusCode}',
          );
          print('📄 Merchant orders response: ${merchantOrdersResponse.body}');

          if (merchantOrdersResponse.statusCode == 200) {
            print('✅ Merchant orders endpoint working');
          } else {
            print('❌ Merchant orders endpoint failed');
          }
        }
      }
    } else {
      print('❌ User businesses call failed');
    }

    print('\n🎉 Authentication fix test completed!');
  } catch (e, stackTrace) {
    print('💥 Test failed with error: $e');
    print('📚 Stack trace: $stackTrace');
  }
}
