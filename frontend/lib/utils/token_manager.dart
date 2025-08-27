import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _accessTokenKey = 'access_token';

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
      print('🚨 [TokenManager] SEVERE TOKEN CORRUPTION DETECTED:');
      print('   - Has newlines: $hasNewlines');
      print('   - Has Cyrillic: $hasCyrillic');
      print('   - Has spaces: $hasSpaces');
      print('   - Has forward slash: $hasSlash');
      print('   - Has equals signs: $hasEquals');
      print('   - Has pipe chars: $hasPipe');
      print('   - Has corruption markers: $hasCorruptionMarkers');
      print('   - Preview: ${cleaned.substring(0, cleaned.length > 50 ? 50 : cleaned.length)}');
      
      // For severely corrupted tokens, reject completely
      if (hasCorruptionMarkers || hasPipe || (hasEquals && !_isValidJwtFormat(cleaned))) {
        print('❌ [TokenManager] Token too corrupted, rejecting completely');
        return '';
      }
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

    // STEP 7: Keep ONLY valid JWT characters: A-Z, a-z, 0-9, -, _, and .
    // Note: JWT tokens use base64url encoding, which uses A-Za-z0-9-_ (no + or /)
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9\-_.]'), '');

    // STEP 8: Validate JWT format after cleaning
    if (cleaned.isNotEmpty && !_isValidJwtFormat(cleaned)) {
      print(
          '⚠️ [TokenManager] Token does not match JWT format after sanitization, rejecting');
      return '';
    }

    // STEP 9: Final length check
    if (cleaned.length < 100) {
      print('⚠️ [TokenManager] Token too short after cleaning, likely corrupted');
      return '';
    }

    print('🧹 [TokenManager] Token sanitized successfully (new length: ${cleaned.length})');
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

  static Future<void> setAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanedToken = _sanitizeTokenForStorage(token);

    if (cleanedToken.isEmpty) {
      print('❌ Refusing to store empty token');
      return;
    }

    print('💾 Storing access token (length: ${cleanedToken.length})');
    await prefs.setString(_accessTokenKey, cleanedToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_accessTokenKey);

    if (storedToken == null || storedToken.isEmpty) {
      return null;
    }

    // Apply the same comprehensive sanitization on retrieval
    String cleanedToken = _sanitizeTokenForStorage(storedToken);

    // Update storage if we had to clean something significant
    if (storedToken != cleanedToken && cleanedToken.isNotEmpty) {
      print(
          '🔧 [TokenManager] Token was corrupted in storage, updating with clean version');
      await prefs.setString(_accessTokenKey, cleanedToken);
    } else if (cleanedToken.isEmpty) {
      print(
          '❌ [TokenManager] Token became empty after sanitization, removing from storage');
      await prefs.remove(_accessTokenKey);
      return null;
    }

    return cleanedToken;
  }

  static Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
  }
}
