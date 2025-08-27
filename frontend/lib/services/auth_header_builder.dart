import '../utils/token_manager.dart';

/// Central helper to construct Authorization headers using the raw access token
/// stored in SharedPreferences. Adds temporary integrity logging.
class AuthHeaderBuilder {
  static Future<Map<String, String>> build() async {
    final token = await TokenManager.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    // TokenManager already sanitizes the token, so we can use it directly
    final masked = token.length > 12
        ? '${token.substring(0, 6)}...${token.substring(token.length - 6)} (len=${token.length})'
        : 'len=${token.length}';
    // ignore: avoid_print
    print('🔐 AuthHeaderBuilder using sanitized token $masked');

    // Ensure Bearer token format is exact
    final authValue = 'Bearer $token';

    return {
      'Content-Type': 'application/json',
      'Authorization': authValue,
    };
  }

  /// Alternative header format for products API that has parsing issues
  static Future<Map<String, String>> buildAlternative() async {
    final token = await TokenManager.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    print('🔐 AuthHeaderBuilder using alternative format');
    return {
      'Content-Type': 'application/json',
      'Access-Token': token,
    };
  }

  /// Try multiple header formats until one works
  static Future<Map<String, String>> buildWithFallback() async {
    final token = await TokenManager.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    // Start with standard Bearer format
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Access-Token': token, // Include both for maximum compatibility
    };
  }
}
