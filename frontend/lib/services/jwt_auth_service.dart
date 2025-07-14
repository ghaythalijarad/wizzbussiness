import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// JWT Authentication Service for working with the deployed API
class JwtAuthService {
  static const String _tokenKey = 'jwt_access_token';
  static const String _userKey = 'jwt_user_data';

  /// Sign in with JWT authentication
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/auth/jwt/login');
      print('🔐 JWT Auth: Attempting login to $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 JWT Auth: Response status ${response.statusCode}');
      print('📄 JWT Auth: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Store the JWT token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, data['access_token']);

          // Create user data from email
          final userData = {
            'email': email,
            'sub': email,
            'name': email.split('@')[0], // Use email prefix as name
          };
          await prefs.setString(_userKey, jsonEncode(userData));

          return {
            'success': true,
            'message': 'Sign in successful',
            'accessToken': data['access_token'],
            'user': userData,
          };
        }
      }

      return {
        'success': false,
        'message': 'Authentication failed',
      };
    } catch (e) {
      print('❌ JWT Auth error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get stored access token
  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('❌ Error getting JWT token: $e');
      return null;
    }
  }

  /// Get current user data
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userKey);
      if (userDataString != null) {
        return jsonDecode(userDataString);
      }
      return null;
    } catch (e) {
      print('❌ Error getting JWT user data: $e');
      return null;
    }
  }

  /// Check if user is signed in
  static Future<bool> isSignedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Sign out user
  static Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      print('❌ Error during JWT sign out: $e');
    }
  }

  /// Create a mock business list for the user
  static Future<List<Map<String, dynamic>>> getUserBusinesses() async {
    final user = await getCurrentUser();
    if (user == null) return [];

    // Create a mock business for the authenticated user
    return [
      {
        'id': 'jwt-business-1',
        'name': 'My Restaurant',
        'type': 'restaurant',
        'address': 'Business Address',
        'owner_email': user['email'],
        'status': 'active',
      }
    ];
  }
}
