import 'package:shared_preferences/shared_preferences.dart';

/// Central helper to construct Authorization headers using the raw access token
/// stored in SharedPreferences. Adds temporary integrity logging.
class AuthHeaderBuilder {
  static Future<Map<String, String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    // Clean the token to prevent encoding issues
    final cleanToken = token.trim().replaceAll('\n', '').replaceAll('\r', '');

    final masked = cleanToken.length > 12
        ? '${cleanToken.substring(0, 6)}...${cleanToken.substring(cleanToken.length - 6)} (len=${cleanToken.length})'
        : 'len=${cleanToken.length}';
    // ignore: avoid_print
    print('🔐 AuthHeaderBuilder using token $masked');

    // Ensure Bearer token format is exact
    final authValue = 'Bearer $cleanToken';

    return {
      'Content-Type': 'application/json',
      'Authorization': authValue,
    };
  }

  /// Alternative header format for products API that has parsing issues
  static Future<Map<String, String>> buildAlternative() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    // Clean the token to prevent encoding issues
    final cleanToken = token.trim().replaceAll('\n', '').replaceAll('\r', '');

    print('🔐 AuthHeaderBuilder using alternative format');
    return {
      'Content-Type': 'application/json',
      'Access-Token': cleanToken,
    };
  }

  /// Try multiple header formats until one works
  static Future<Map<String, String>> buildWithFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    // Clean the token to prevent encoding issues
    final cleanToken = token.trim().replaceAll('\n', '').replaceAll('\r', '');

    // Start with standard Bearer format
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $cleanToken',
      'Access-Token': cleanToken, // Include both for maximum compatibility
    };
  }
}
