import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'services/app_auth_service.dart';

/// Debug script to test Flutter app's delete request vs working Node.js request
class FlutterDeleteDebugger {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<void> debugDeleteRequest() async {
    print('🔧 FLUTTER DELETE DEBUGGER');
    print('==========================\n');

    try {
      // Step 1: Get the token using the same method as the app
      print('1. Getting access token...');
      final token = await AppAuthService.getAccessToken();
      
      if (token == null) {
        print('❌ No access token found');
        return;
      }

      print('✅ Token retrieved');
      print('📝 Token length: ${token.length}');
      print('📝 Token first 50 chars: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
      
      // Check SharedPreferences directly too
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('access_token');
      print('📱 SharedPreferences token exists: ${storedToken != null}');
      if (storedToken != null) {
        print('📱 SP token matches retrieved: ${storedToken == token}');
      }

      // Check for problematic characters
      final invalidChars = token.contains(RegExp(r'[^A-Za-z0-9._-]'));
      print('🔍 Token has non-standard chars: $invalidChars');
      
      // Check for common problematic characters
      final hasNewlines = token.contains('\n') || token.contains('\r');
      final hasSpaces = token.contains(' ');
      final hasQuotes = token.contains('"') || token.contains("'");
      print('🔍 Token has newlines: $hasNewlines');
      print('🔍 Token has spaces: $hasSpaces');
      print('🔍 Token has quotes: $hasQuotes');

      // Step 2: Get products to find one to test delete
      print('\n2. Getting products to find test subject...');
      final productsResponse = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📤 Products request status: ${productsResponse.statusCode}');
      
      if (productsResponse.statusCode == 200) {
        final data = jsonDecode(productsResponse.body);
        final products = data['products'] as List?;
        
        if (products != null && products.isNotEmpty) {
          final testProduct = products.first;
          final productId = testProduct['productId'];
          print('✅ Found test product: ${testProduct['name']} (ID: $productId)');

          // Step 3: Attempt delete with detailed logging
          print('\n3. Attempting DELETE request...');
          
          final deleteUrl = '$baseUrl/products/$productId';
          final authHeader = 'Bearer $token';
          
          print('🌐 URL: $deleteUrl');
          print('🔑 Auth header length: ${authHeader.length}');
          print('🔑 Auth header: ${authHeader.substring(0, authHeader.length > 70 ? 70 : authHeader.length)}...');
          
          // Create headers map
          final headers = {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          };
          
          print('📋 All headers:');
          headers.forEach((key, value) {
            if (key == 'Authorization') {
              print('  $key: ${value.substring(0, value.length > 70 ? 70 : value.length)}...');
            } else {
              print('  $key: $value');
            }
          });

          // Make the request
          final deleteResponse = await http.delete(
            Uri.parse(deleteUrl),
            headers: headers,
          );

          print('\n📤 DELETE RESPONSE:');
          print('📤 Status: ${deleteResponse.statusCode}');
          print('📤 Body: ${deleteResponse.body}');
          print('📤 Response headers: ${deleteResponse.headers}');

          if (deleteResponse.statusCode != 200) {
            print('\n❌ DELETE FAILED - Analyzing error...');
            
            // Try to parse error response
            try {
              final errorData = jsonDecode(deleteResponse.body);
              print('📝 Error message: ${errorData['message']}');
              print('📝 Full error data: $errorData');
            } catch (e) {
              print('📝 Could not parse error response: $e');
            }

            // Let's also try a different approach - manual header construction
            print('\n🔄 Trying alternative header construction...');
            final altHeaders = <String, String>{};
            altHeaders['Content-Type'] = 'application/json';
            altHeaders['Authorization'] = 'Bearer $token';
            
            final altResponse = await http.delete(
              Uri.parse(deleteUrl),
              headers: altHeaders,
            );
            
            print('📤 Alternative response status: ${altResponse.statusCode}');
            print('📤 Alternative response body: ${altResponse.body}');

          } else {
            print('✅ DELETE SUCCESSFUL!');
          }

        } else {
          print('❌ No products found for testing');
        }
      } else {
        print('❌ Failed to get products: ${productsResponse.statusCode}');
        print('📤 Response: ${productsResponse.body}');
      }

    } catch (e, stackTrace) {
      print('💥 Exception during debug: $e');
      print('📚 Stack trace: $stackTrace');
    }
  }

  /// Compare token between different retrieval methods
  static Future<void> compareTokenSources() async {
    print('\n🔄 COMPARING TOKEN SOURCES');
    print('==========================');

    try {
      // Method 1: AppAuthService
      final tokenFromService = await AppAuthService.getAccessToken();
      print('📱 AppAuthService token exists: ${tokenFromService != null}');
      if (tokenFromService != null) {
        print('📱 Service token length: ${tokenFromService.length}');
      }

      // Method 2: Direct SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final tokenFromPrefs = prefs.getString('access_token');
      print('💾 SharedPreferences token exists: ${tokenFromPrefs != null}');
      if (tokenFromPrefs != null) {
        print('💾 Prefs token length: ${tokenFromPrefs.length}');
      }

      // Compare
      if (tokenFromService != null && tokenFromPrefs != null) {
        print('🔍 Tokens match: ${tokenFromService == tokenFromPrefs}');
        if (tokenFromService != tokenFromPrefs) {
          print('⚠️ TOKEN MISMATCH DETECTED!');
          print('📱 Service first 30: ${tokenFromService.substring(0, 30)}...');
          print('💾 Prefs first 30: ${tokenFromPrefs.substring(0, 30)}...');
        }
      }

    } catch (e) {
      print('💥 Error comparing tokens: $e');
    }
  }
}

/// Run the debug
Future<void> main() async {
  await FlutterDeleteDebugger.debugDeleteRequest();
  await FlutterDeleteDebugger.compareTokenSources();
}
