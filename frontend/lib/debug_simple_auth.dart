import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/app_auth_service.dart';
import 'config/app_config.dart';

/// Simple debug to check exact authorization header format
class SimpleAuthDebug {
  static Future<void> debugAuthHeader() async {
    print('🔍 SIMPLE AUTH HEADER DEBUG');
    print('============================\n');

    try {
      // Get token using the same method as ProductService
      final token = await AppAuthService.getAccessToken();

      if (token == null) {
        print('❌ No token found');
        return;
      }

      print('✅ Token retrieved successfully');
      print('📏 Token length: ${token.length}');
      print('📝 Token starts with: ${token.substring(0, 20)}...');
      print('📝 Token ends with: ...${token.substring(token.length - 20)}');

      // Check for any whitespace or problematic characters
      print(
          '🔍 Token has leading/trailing whitespace: ${token != token.trim()}');
      print(
          '🔍 Token contains newlines: ${token.contains('\n') || token.contains('\r')}');
      print('🔍 Token contains spaces: ${token.contains(' ')}');

      // Build authorization header exactly as ProductService does
      final authHeader = 'Bearer $token';
      print('\n🔑 Authorization header:');
      print('📏 Header length: ${authHeader.length}');
      print('📝 Header starts with: ${authHeader.substring(0, 30)}...');

      // Check if Bearer prefix is correct
      final hasBearerPrefix = authHeader.startsWith('Bearer ');
      print('✅ Has correct Bearer prefix: $hasBearerPrefix');

      // Get the token part after "Bearer "
      final tokenPart = authHeader.substring(7); // Remove "Bearer "
      print('📝 Token part length: ${tokenPart.length}');
      print('📝 Token part equals original: ${tokenPart == token}');

      // Test with a simple GET request first (products list)
      print('\n🧪 Testing with GET /products request...');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
      );

      print('📤 GET Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('📤 GET Response Headers: ${response.headers}');
        print('📤 GET Response Body: ${response.body}');
      } else {
        print(
            '✅ GET request successful - authorization header is working for GET');

        // Now test with DELETE request to a non-existent product (should give 404, not 403)
        print('\n🧪 Testing DELETE with non-existent product...');
        final deleteResponse = await http.delete(
          Uri.parse('${AppConfig.baseUrl}/products/test-non-existent-id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
        );

        print('📤 DELETE Response Status: ${deleteResponse.statusCode}');
        print('📤 DELETE Response Headers: ${deleteResponse.headers}');
        print('📤 DELETE Response Body: ${deleteResponse.body}');

        if (deleteResponse.statusCode == 403) {
          print('❌ Still getting 403 - authorization issue persists');
        } else {
          print('✅ No 403 error - authorization is working');
        }
      }
    } catch (e, stackTrace) {
      print('💥 Error: $e');
      print('📚 Stack: $stackTrace');
    }
  }

  /// Test token storage and retrieval
  static Future<void> debugTokenStorage() async {
    print('\n💾 TOKEN STORAGE DEBUG');
    print('======================\n');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check what's actually stored
      final storedToken = prefs.getString('access_token');
      print('📱 Token in SharedPreferences: ${storedToken != null}');

      if (storedToken != null) {
        print('📏 Stored token length: ${storedToken.length}');
        print('📝 Stored token starts: ${storedToken.substring(0, 20)}...');
        print(
            '📝 Stored token ends: ...${storedToken.substring(storedToken.length - 20)}');

        // Check if stored token has issues
        print(
            '🔍 Stored token trimmed differs: ${storedToken != storedToken.trim()}');
        if (storedToken != storedToken.trim()) {
          print('⚠️ FOUND WHITESPACE ISSUE!');
          print('📝 Original: "${storedToken}"');
          print('📝 Trimmed: "${storedToken.trim()}"');
        }
      }

      // Get token via AppAuthService
      final serviceToken = await AppAuthService.getAccessToken();
      if (serviceToken != null) {
        print('\n📱 Token from AppAuthService: ${serviceToken.length} chars');

        if (storedToken != null) {
          print(
              '🔍 Service token matches stored: ${serviceToken == storedToken}');
          if (serviceToken != storedToken) {
            print('⚠️ TOKEN MISMATCH DETECTED!');
            print('📝 Stored length: ${storedToken.length}');
            print('📝 Service length: ${serviceToken.length}');
          }
        }
      }
    } catch (e) {
      print('💥 Storage debug error: $e');
    }
  }
}

Future<void> main() async {
  await SimpleAuthDebug.debugAuthHeader();
  await SimpleAuthDebug.debugTokenStorage();
}
