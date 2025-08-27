import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced TokenManager that uses ID tokens for API Gateway authorization
/// to fix the "missing audience field" issue with access tokens
class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _idTokenKey = 'id_token';

  /// ENHANCED token sanitization for storage - fix "Invalid key=value pair" errors
  static String _sanitizeTokenForStorage(String token) {
    print(
        '🧹 [TokenManager] Sanitizing token for storage (length: ${token.length})');

    // Start with the raw token
    String cleaned = token.trim();

    // EMERGENCY CORRUPTION DETECTION - log details for debugging
    final hasNewlines = cleaned.contains('\n') || cleaned.contains('\r');
    final hasCyrillic = RegExp(r'[\u0400-\u04FF]').hasMatch(cleaned);
    final hasSpaces = cleaned.contains(' ');
    final hasSlash = cleaned.contains('/');
    final hasEquals = cleaned.contains('=');
    final hasPipe = cleaned.contains('|');
    final hasCorruptionMarkers = cleaned.startsWith('=') || cleaned.contains('|=');
    
    if (hasNewlines || hasCyrillic || hasSpaces || hasCorruptionMarkers) {
      print('🚨 [TokenManager] CORRUPTION DETECTED in incoming token:');
      print('   - Has newlines: $hasNewlines');
      print('   - Has Cyrillic: $hasCyrillic');
      print('   - Has spaces: $hasSpaces');
      print('   - Has corruption markers: $hasCorruptionMarkers');
      print('   - Raw token: "${token.substring(0, token.length.clamp(0, 50))}..."');
    }

    // STEP 1: Remove ALL non-printable ASCII characters
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x1F\x7F-\xFF]'), '');

    // STEP 2: Remove ALL Unicode characters (Cyrillic, etc.)
    cleaned = cleaned.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

    // STEP 3: Remove ALL whitespace characters
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');

    // STEP 4: Remove specific problematic characters that break HTTP headers
    cleaned = cleaned.replaceAll('\r', '');
    cleaned = cleaned.replaceAll('\n', '');
    cleaned = cleaned.replaceAll('\t', '');
    cleaned = cleaned.replaceAll("'", '');
    cleaned = cleaned.replaceAll('"', '');
    cleaned = cleaned.replaceAll('|', ''); // Pipe characters break headers

    // STEP 5: Remove Bearer prefix if mistakenly included
    if (cleaned.toLowerCase().startsWith('bearer')) {
      cleaned = cleaned.substring(6);
    }

    // STEP 6: Remove leading equals signs that break key=value parsing
    while (cleaned.startsWith('=')) {
      cleaned = cleaned.substring(1);
    }

    // STEP 7: Keep ONLY valid JWT characters (base64url + . separators)
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9\-_.+=\/]'), '');

    // STEP 8: Validate final token format
    if (cleaned.isNotEmpty && !_isValidJwtFormat(cleaned)) {
      print(
          '⚠️ [TokenManager] Token does not match JWT format after sanitization');
      print(
          '   Cleaned token: ${cleaned.substring(0, cleaned.length.clamp(0, 20))}... (showing first 20 chars)');
    }

    print('🧹 [TokenManager] Token sanitized (new length: ${cleaned.length})');
    return cleaned;
  }

  /// Validate JWT format
  static bool _isValidJwtFormat(String token) {
    if (token.isEmpty) return false;

    // JWT should have exactly 3 parts separated by dots
    final parts = token.split('.');
    if (parts.length != 3) return false;

    // Each part should contain only base64url characters
    for (final part in parts) {
      if (part.isEmpty || !RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(part)) {
        return false;
      }
    }

    return true;
  }

  /// Store access token (legacy method)
  static Future<void> setAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanedToken = _sanitizeTokenForStorage(token);

    if (cleanedToken.isEmpty) {
      print('❌ Refusing to store empty access token');
      return;
    }

    print('💾 Storing access token (length: ${cleanedToken.length})');
    await prefs.setString(_accessTokenKey, cleanedToken);
  }

  /// Store ID token (for API Gateway authorization)
  static Future<void> setIdToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanedToken = _sanitizeTokenForStorage(token);

    if (cleanedToken.isEmpty) {
      print('❌ Refusing to store empty ID token');
      return;
    }

    print('💾 Storing ID token (length: ${cleanedToken.length})');
    await prefs.setString(_idTokenKey, cleanedToken);
  }

  /// Get the token that should be used for API Gateway authorization
  /// Returns ID token (which has aud field) instead of access token for better compatibility
  static Future<String?> getAuthorizationToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First try ID token (preferred for API Gateway - contains aud field)
    final idToken = prefs.getString(_idTokenKey);
    if (idToken != null && idToken.isNotEmpty) {
      final cleanedIdToken = _sanitizeTokenForStorage(idToken);
      if (cleanedIdToken.isNotEmpty && _isValidJwtFormat(cleanedIdToken)) {
        print('🎫 [TokenManager] Using ID token for authorization (length: ${cleanedIdToken.length})');
        return cleanedIdToken;
      }
    }
    
    // Fallback to access token
    final accessToken = prefs.getString(_accessTokenKey);
    if (accessToken != null && accessToken.isNotEmpty) {
      final cleanedAccessToken = _sanitizeTokenForStorage(accessToken);
      if (cleanedAccessToken.isNotEmpty && _isValidJwtFormat(cleanedAccessToken)) {
        print('🔑 [TokenManager] Falling back to access token for authorization (length: ${cleanedAccessToken.length})');
        return cleanedAccessToken;
      }
    }
    
    print('❌ [TokenManager] No valid authorization token found');
    return null;
  }

  /// Legacy method for backward compatibility - now calls getAuthorizationToken()
  static Future<String?> getAccessToken() async {
    return await getAuthorizationToken();
  }

  /// Clear all stored tokens
  static Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_idTokenKey);
    print('🧹 [TokenManager] Cleared all stored tokens');
  }
}
