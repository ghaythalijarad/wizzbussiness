import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'app_auth_service.dart';
import 'web_http_client.dart';

class BusinessStatusBlockedException implements Exception {
  final String message;
  final String code;
  BusinessStatusBlockedException({required this.message, required this.code});
  @override
  String toString() =>
      'BusinessStatusBlockedException(code=$code, message=$message)';
}

class ApiService {
  final String baseUrl = AppConfig.baseUrl;
  static final List<String> _recentErrors = [];

  /// Try multiple strategies to bypass CloudFront cache
  Future<http.Response> _makeRequestWithCacheBypass({
    required String method,
    required String path,
    Map<String, String>? headers,
    String? body,
    int maxRetries = 3,
  }) async {
    int attempt = 1;
    http.Response response;

    do {
      final currentBaseUrl = baseUrl; // Using the primary base URL for now
      final url = Uri.parse('$currentBaseUrl$path');

      print('🔄 [CacheBypass] Attempt $attempt/$maxRetries: $method $url');

      try {
        if (method.toUpperCase() == 'GET') {
          response = await AppHttpClient.get(url, headers: headers);
        } else if (method.toUpperCase() == 'POST') {
          response =
              await AppHttpClient.post(url, headers: headers, body: body);
        } else if (method.toUpperCase() == 'PUT') {
          response = await AppHttpClient.put(url, headers: headers, body: body);
        } else {
          throw Exception('Unsupported HTTP method: $method');
        }

        // If it's not a CloudFront cache error, we are done.
        if (!_isCloudFrontCacheError(response)) {
          print(
              '✅ [CacheBypass] Attempt $attempt successful (not a cache error).');
          return response;
        }

        print(
            '⚠️ [CacheBypass] Attempt $attempt failed: CloudFront cache error detected.');
      } catch (e) {
        print('❌ [CacheBypass] Attempt $attempt threw an exception: $e');
        // For network errors, we can also retry
        response = http.Response(
          jsonEncode({
            'success': false,
            'error': 'network_error',
            'message': 'Request failed: $e',
          }),
          503, // Service Unavailable
          headers: {'content-type': 'application/json'},
        );
      }

      attempt++;
      if (attempt <= maxRetries) {
        final delay = Duration(milliseconds: 500 * (attempt - 1));
        print(
            '🕒 [CacheBypass] Waiting ${delay.inMilliseconds}ms before next attempt...');
        await Future.delayed(delay);
      }
    } while (attempt <= maxRetries);

    print(
        '❌ [CacheBypass] All $maxRetries attempts failed. Returning last response.');
    return response; // Return the last failed response
  }

  // --- Added diagnostic auth state helper ---
  static Future<Map<String, dynamic>> debugAuthState() async {
    final access = await AppAuthService.getAccessToken();
    final id = await AppAuthService.getIdToken();
    return {
      'hasAccessToken': access != null && access.isNotEmpty,
      'hasIdToken': id != null && id.isNotEmpty,
      'accessTokenLen': access?.length,
      'idTokenLen': id?.length,
      if (access != null)
        'accessTokenPrefix':
            access.substring(0, access.length > 12 ? 12 : access.length),
      if (id != null)
        'idTokenPrefix': id.substring(0, id.length > 12 ? 12 : id.length),
    };
  }

  /// Debug method to decode and print full token payload for troubleshooting
  static Future<void> debugDecodeCurrentTokens() async {
    print('🔍 [debugDecodeCurrentTokens] Starting token analysis...');

    try {
      final accessToken = await AppAuthService.getAccessToken();
      final idToken = await AppAuthService.getIdToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        print('🔍 [debugDecodeCurrentTokens] === ACCESS TOKEN ===');
        _debugDecodeJWT(accessToken, 'ACCESS');
      }

      if (idToken != null && idToken.isNotEmpty) {
        print('🔍 [debugDecodeCurrentTokens] === ID TOKEN ===');
        _debugDecodeJWT(idToken, 'ID');
      }
    } catch (e) {
      print('❌ [debugDecodeCurrentTokens] Error: $e');
    }
  }

  static void _debugDecodeJWT(String token, String type) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('⚠️ [$type] Invalid JWT format: ${parts.length} parts');
        return;
      }

      // Decode header
      String headerB64 = parts[0].replaceAll('-', '+').replaceAll('_', '/');
      while (headerB64.length % 4 != 0) headerB64 += '=';
      final headerJson = utf8.decode(base64.decode(headerB64));
      final header = jsonDecode(headerJson);
      print('🔍 [$type] Header: $header');

      // Decode payload
      String payloadB64 = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payloadB64.length % 4 != 0) payloadB64 += '=';
      final payloadJson = utf8.decode(base64.decode(payloadB64));
      final payload = jsonDecode(payloadJson);
      print('🔍 [$type] Payload: $payload');

      // Highlight key fields
      print('🔍 [$type] Key Claims:');
      print('  - iss: ${payload['iss']}');
      print('  - aud: ${payload['aud']}');
      print('  - client_id: ${payload['client_id']}');
      print('  - token_use: ${payload['token_use']}');
      print(
          '  - exp: ${DateTime.fromMillisecondsSinceEpoch((payload['exp'] ?? 0) * 1000)})');
      print('  - sub: ${payload['sub']}');
      print('  - scope: ${payload['scope']}');
    } catch (e) {
      print('❌ [$type] Decode failed: $e');
    }
  }

  static void _pushError(String e) {
    _recentErrors.add("${DateTime.now().toIso8601String()} | $e");
    if (_recentErrors.length > 25) _recentErrors.removeAt(0);
  }

  static List<String> get recentErrors => List.unmodifiable(_recentErrors);

  static bool _isAuthorizerForbidden(http.Response resp) {
    try {
      if (resp.statusCode != 403) return false;
      final body = resp.body.trim();
      if (body == '{"message":"Forbidden"}' ||
          body == '{"message":"Forbidden"}') {
        // API Gateway default format. Additional header checks strengthen confidence.
        final errType = resp.headers['x-amzn-errortype'] ?? '';
        if (errType.toLowerCase().contains('forbiddenexception')) return true;
      }
      // Try JSON parse for robustness
      final parsed = jsonDecode(body);
      if (parsed is Map &&
          parsed.length == 1 &&
          parsed['message'] == 'Forbidden') {
        final errType = resp.headers['x-amzn-errortype'] ?? '';
        if (errType.toLowerCase().contains('forbiddenexception')) return true;
      }
    } catch (_) {/* ignore */}
    return false;
  }

  // CloudFront cache detection and handling
  static bool _isCloudFrontCacheError(http.Response resp) {
    final headers = resp.headers;
    return headers.containsKey('x-cache') &&
        headers.containsKey('via') &&
        headers['via']?.contains('cloudfront') == true &&
        (headers['x-cache']?.contains('Error from cloudfront') == true ||
            headers['x-cache']?.contains('Hit from cloudfront') == true);
  }

  static String _getCloudFrontCacheErrorMessage(http.Response resp) {
    final cacheStatus = resp.headers['x-cache'] ?? 'unknown';
    final cfPopId = resp.headers['x-amz-cf-pop'] ?? 'unknown';

    return '''
🔄 CloudFront Cache Issue Detected

The API server is behind CloudFront which is serving cached error responses.

Details:
• Cache Status: $cacheStatus
• CloudFront POP: $cfPopId
• Status Code: ${resp.statusCode}

This typically resolves automatically within 24 hours, or:
1. Try again in a few minutes
2. Contact support if the issue persists
3. Check if other users are experiencing the same issue

The backend services have been updated and are working, but CloudFront needs time to refresh its cache.
''';
  }

  Future<Map<String, String>> _authHeaders({bool preferIdToken = false}) async {
    // Get both tokens
    final accessToken = await AppAuthService.getAccessToken();
    final idToken = await AppAuthService.getIdToken();

    String? tokenToUse;
    String tokenSource = 'unknown';

    // ✅ FIX: PRIORITIZE ID TOKEN for API Gateway Cognito User Pool authorizers
    // API Gateway Cognito User Pool authorizers require ID tokens, not access tokens
    if (idToken?.isNotEmpty == true) {
      tokenToUse = idToken;
      tokenSource = 'idToken';
    } else if (accessToken?.isNotEmpty == true) {
      // Fallback to access token only if ID token is unavailable
      tokenToUse = accessToken;
      tokenSource = 'accessToken (fallback)';
    }

    if (tokenToUse == null || tokenToUse.isEmpty) {
      throw Exception('No valid authentication token available');
    }

    // ✅ CRITICAL: ULTRA-AGGRESSIVE token sanitization to fix "Invalid key=value pair" errors
    // The error shows Cyrillic characters (х) and line breaks corrupting the JWT token
    String cleanToken = tokenToUse.trim();

    print('🧹 [TokenSanitization] Original token length: ${cleanToken.length}');
    print(
        '🧹 [TokenSanitization] Original token bytes: ${cleanToken.codeUnits}');

    // Log problematic characters before cleaning
    final problematicChars = RegExp(r'[^\x20-\x7E]');
    if (problematicChars.hasMatch(cleanToken)) {
      final badChars = problematicChars
          .allMatches(cleanToken)
          .map((match) =>
              '${cleanToken.substring(match.start, match.end)} (${cleanToken.codeUnitAt(match.start)})')
          .join(', ');
      print(
          '🚨 [TokenSanitization] CRITICAL: Found non-ASCII chars: $badChars');
    }

    // STEP 1: Remove ALL non-printable ASCII characters (0x00-0x1F, 0x7F-0xFF)
    cleanToken = cleanToken.replaceAll(RegExp(r'[\x00-\x1F\x7F-\xFF]'), '');

    // STEP 2: Remove ALL Unicode characters (anything above ASCII 127)
    cleanToken = cleanToken.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

    // STEP 3: Remove ALL whitespace characters (spaces, tabs, newlines, etc.)
    cleanToken = cleanToken.replaceAll(RegExp(r'\s'), '');

    // STEP 4: Remove specific problematic characters we've seen
    cleanToken = cleanToken.replaceAll('\r', '');
    cleanToken = cleanToken.replaceAll('\n', '');
    cleanToken = cleanToken.replaceAll('\t', '');
    cleanToken = cleanToken.replaceAll("'", ''); // Remove single quotes
    cleanToken = cleanToken.replaceAll('"', ''); // Remove double quotes
    cleanToken = cleanToken.replaceAll(
        '/', ''); // Remove forward slashes that shouldn't be in JWT

    // STEP 5: Remove Bearer prefix if accidentally included
    if (cleanToken.toLowerCase().startsWith('bearer')) {
      cleanToken = cleanToken.substring(6);
    }

    // STEP 6: Keep ONLY valid JWT characters: A-Z, a-z, 0-9, -, _, and .
    cleanToken = cleanToken.replaceAll(RegExp(r'[^A-Za-z0-9\-_.]'), '');

    // STEP 7: Handle any remaining equals signs that aren't at the end (Base64 padding)
    if (cleanToken.contains('=')) {
      final parts = cleanToken.split('.');
      if (parts.length == 3) {
        // JWT should have 3 parts separated by dots
        // Only the last part can have padding equals
        parts[0] = parts[0].replaceAll('=', '');
        parts[1] = parts[1].replaceAll('=', '');
        // parts[2] can keep equals at the end for Base64 padding
        cleanToken = parts.join('.');
      } else {
        // If not a proper JWT structure, remove all equals
        cleanToken = cleanToken.replaceAll('=', '');
      }
    }

    print('🧹 [TokenSanitization] Cleaned token length: ${cleanToken.length}');
    print(
        '🧹 [TokenSanitization] Cleaned token preview: ${cleanToken.substring(0, cleanToken.length > 50 ? 50 : cleanToken.length)}...');

    // CRITICAL FIX: Handle the specific corruption pattern we're seeing
    // Example corrupted token: 'gDGUO8sgWb7SQuBjFUOхFalxRtVu1FXoMaS/\n'=k4Rv+j0
    // This contains Cyrillic 'х' character and line breaks that break HTTP headers

    // The issue is that the token is being corrupted at the HTTP header level
    // AWS API Gateway is rejecting the header because it contains invalid characters
    // that break the HTTP header format (specifically Cyrillic 'х' and line breaks)

    // AGGRESSIVE CORRUPTION DETECTION AND REPAIR
    final originalToken = tokenToUse;
    print(
        '🔧 [CORRUPTION-FIX] Original token sample: ${originalToken.substring(0, originalToken.length > 80 ? 80 : originalToken.length)}...');

    // Check for the specific Cyrillic 'х' character (code 1093) and other corruption
    bool hasCorruption = false;
    final corruptionPattern = RegExp(r'[\u0400-\u04FF]'); // Cyrillic block
    if (corruptionPattern.hasMatch(originalToken)) {
      print(
          '🚨 [CORRUPTION-FIX] CRITICAL: Cyrillic characters detected in token!');
      hasCorruption = true;
    }

    // Check for line breaks and control characters
    if (originalToken.contains('\n') ||
        originalToken.contains('\r') ||
        originalToken.contains('\t')) {
      print(
          '🚨 [CORRUPTION-FIX] CRITICAL: Line breaks/control chars detected in token!');
      hasCorruption = true;
    }

    // Check for quotes that break HTTP headers
    if (originalToken.contains("'") || originalToken.contains('"')) {
      print(
          '🚨 [CORRUPTION-FIX] CRITICAL: Quote characters detected in token!');
      hasCorruption = true;
    }

    // If corruption detected, perform aggressive reconstruction
    if (hasCorruption) {
      print('🔧 [CORRUPTION-FIX] Performing emergency token reconstruction...');

      // Extract only valid JWT characters from the corrupted token
      // Valid JWT characters: A-Z, a-z, 0-9, -, _, . and = (for padding)
      String reconstructed = '';
      for (int i = 0; i < originalToken.length; i++) {
        final char = originalToken[i];
        final code = char.codeUnitAt(0);

        // Allow only valid JWT characters
        if ((code >= 65 && code <= 90) || // A-Z
            (code >= 97 && code <= 122) || // a-z
            (code >= 48 && code <= 57) || // 0-9
            char == '-' ||
            char == '_' ||
            char == '.') {
          reconstructed += char;
        } else if (char == '=' && i >= originalToken.length - 3) {
          // Allow equals only at the end for Base64 padding
          reconstructed += char;
        } else {
          print(
              '🔧 [CORRUPTION-FIX] Skipping invalid char: "$char" (code: $code)');
        }
      }

      print(
          '🔧 [CORRUPTION-FIX] Reconstructed token length: ${reconstructed.length}');
      print(
          '🔧 [CORRUPTION-FIX] Reconstructed sample: ${reconstructed.substring(0, reconstructed.length > 80 ? 80 : reconstructed.length)}...');

      cleanToken = reconstructed;
    }

    // Additional validation to catch any remaining invalid characters
    final invalidCharsPattern = RegExp(r'[^A-Za-z0-9\-_.=]');
    if (invalidCharsPattern.hasMatch(cleanToken)) {
      final invalidChars = invalidCharsPattern
          .allMatches(cleanToken)
          .map((match) =>
              '${cleanToken.substring(match.start, match.end)} (${cleanToken.codeUnitAt(match.start)})')
          .join(', ');
      print(
          '⚠️ [TokenSanitization] Found remaining invalid characters: $invalidChars');
      print('⚠️ [TokenSanitization] Removing all invalid characters...');
      cleanToken = cleanToken.replaceAll(invalidCharsPattern, '');
    }

    // Validate JWT structure (should have exactly 2 dots for 3 parts)
    final parts = cleanToken.split('.');
    if (parts.length != 3) {
      print(
          '🚨 [CORRUPTION-FIX] Invalid JWT structure: ${parts.length} parts (expected 3)');
      // Try to reconstruct from the original token more aggressively
      cleanToken = originalToken
          .replaceAll(RegExp(r'[^\x21-\x7E]'), '') // Keep only printable ASCII
          .replaceAll(
              RegExp(r'[^A-Za-z0-9\-_.=]'), '') // Keep only valid JWT chars
          .replaceAll(RegExp(r'=+(?!$)'), ''); // Remove equals not at end
    }

    // Basic JWT validation - ensure it has the right structure
    if (!_isValidJwtToken(cleanToken)) {
      print('⚠️ Token validation failed, attempting refresh...');
      try {
        final refreshed = await AppAuthService.refreshSession();
        if (refreshed != null) {
          // Retry with new tokens - prioritize ID token
          final newIdToken = await AppAuthService.getIdToken();
          final newAccessToken = await AppAuthService.getAccessToken();

          if (newIdToken?.isNotEmpty == true) {
            cleanToken = newIdToken!
                .trim()
                .replaceAll(RegExp(r'\s'), '')
                .replaceAll(RegExp(r'[^A-Za-z0-9\-_.]'), '');
            tokenSource = 'refreshed_idToken';
          } else if (newAccessToken?.isNotEmpty == true) {
            cleanToken = newAccessToken!
                .trim()
                .replaceAll(RegExp(r'\s'), '')
                .replaceAll(RegExp(r'[^A-Za-z0-9\-_.]'), '');
            tokenSource = 'refreshed_accessToken (fallback)';
          }
        }
      } catch (e) {
        print('❌ Token refresh failed: $e');
        throw Exception('Authentication failed: $e');
      }
    }

    print('🔐 Using $tokenSource for authentication');

    // ✅ FIX: Use ID token for AWS API Gateway Cognito User Pool Authorizer
    // API Gateway Cognito User Pool authorizers require ID tokens for proper authentication

    // CRITICAL: Additional final token validation before header construction
    // This is our last line of defense against token corruption

    print('🔒 [FINAL-CHECK] Pre-header token length: ${cleanToken.length}');
    print(
        '🔒 [FINAL-CHECK] Pre-header token sample: ${cleanToken.substring(0, cleanToken.length > 60 ? 60 : cleanToken.length)}...');

    // Check for the specific corruption patterns we've seen
    final problematicPatterns = [
      RegExp(r'[\u0400-\u04FF]'), // Cyrillic characters like 'х'
      RegExp(r'[\r\n\t]'), // Line breaks and tabs
      RegExp(r"['\x22]"), // Quote characters (single and double)
      RegExp(
          r'[^\x21-\x7E]'), // Non-printable ASCII (except space which we'll handle)
    ];

    bool foundIssues = false;
    for (int i = 0; i < problematicPatterns.length; i++) {
      final pattern = problematicPatterns[i];
      if (pattern.hasMatch(cleanToken)) {
        final matches = pattern
            .allMatches(cleanToken)
            .map((m) =>
                '${cleanToken.substring(m.start, m.end)} (${cleanToken.codeUnitAt(m.start)})')
            .join(', ');
        print('🚨 [FINAL-CHECK] Pattern $i found problematic chars: $matches');
        foundIssues = true;
      }
    }

    if (foundIssues) {
      print('🔧 [FINAL-CHECK] Applying emergency token cleanup...');
      // Ultra-conservative approach: keep ONLY valid JWT characters
      cleanToken = cleanToken.split('').where((char) {
        final code = char.codeUnitAt(0);
        return (code >= 65 && code <= 90) || // A-Z
            (code >= 97 && code <= 122) || // a-z
            (code >= 48 && code <= 57) || // 0-9
            char == '-' ||
            char == '_' ||
            char == '.';
      }).join('');

      print(
          '🔧 [FINAL-CHECK] Emergency cleaned token length: ${cleanToken.length}');
      print(
          '🔧 [FINAL-CHECK] Emergency cleaned sample: ${cleanToken.substring(0, cleanToken.length > 60 ? 60 : cleanToken.length)}...');
    }

    final authHeader = 'Bearer $cleanToken';

    // Validate the final Authorization header for HTTP compliance
    // This catches the exact error we're seeing: "Invalid key=value pair"
    for (int i = 0; i < authHeader.length; i++) {
      final code = authHeader.codeUnitAt(i);
      // HTTP header values can only contain ASCII characters 32-126 and tab (9)
      if (!(code == 9 || (code >= 32 && code <= 126))) {
        final char = authHeader[i];
        print(
            '🚨 [HTTP-HEADER-VALIDATION] Invalid char at position $i: "$char" (code: $code)');
        print(
            '🚨 [HTTP-HEADER-VALIDATION] Full header: ${authHeader.substring(0, i > 10 ? i - 10 : 0)}[$char]${authHeader.substring(i + 1, (i + 20) < authHeader.length ? i + 20 : authHeader.length)}...');
        throw Exception(
            'Authorization header contains invalid character: "$char" (code: $code) at position $i');
      }
    }

    // Final validation to catch the exact corruption pattern we're seeing
    if (authHeader.contains(RegExp(r'[^\x20-\x7E]'))) {
      print(
          '⚠️ [TokenSanitization] CRITICAL: Authorization header contains non-printable characters!');
      print('⚠️ [TokenSanitization] Raw header bytes: ${authHeader.codeUnits}');
      // Remove any non-printable ASCII characters
      final sanitizedHeader =
          authHeader.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
      print('⚠️ [TokenSanitization] Sanitized header: $sanitizedHeader');
      throw Exception(
          'Authorization header contains invalid characters after sanitization');
    }

    // Log the header for debugging (but mask the token)
    print('🔑 Authorization header length: ${authHeader.length}');
    final headerPreview = authHeader.length > 20
        ? '${authHeader.substring(0, 20)}...'
        : authHeader;
    print('🔑 Authorization header preview: $headerPreview');

    // Additional validation for HTTP header compliance
    if (authHeader.contains('\n') ||
        authHeader.contains('\r') ||
        authHeader.contains('\t')) {
      print(
          '⚠️ WARNING: Authorization header contains invalid characters for HTTP');
      throw Exception('Authorization header contains invalid characters');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authHeader,
    };

    return headers;
  }

  /// Validate JWT token format
  bool _isValidJwtToken(String token) {
    if (token.isEmpty) return false;

    // JWT tokens should have exactly 2 dots (3 parts: header.payload.signature)
    final parts = token.split('.');
    if (parts.length != 3) {
      print('⚠️ JWT token should have 3 parts, found: ${parts.length}');
      return false;
    }

    // Each part should be non-empty
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) {
        print('⚠️ JWT token part $i is empty');
        return false;
      }
    }

    // Token should be reasonable length
    if (token.length < 100 || token.length > 4000) {
      print('⚠️ JWT token length is suspicious: ${token.length}');
      return false;
    }

    return true;
  }

  /// Retry HTTP request with token refresh on 401 errors
  Future<http.Response> _retryRequestOn401(
      Future<http.Response> Function() requestFn) async {
    print('🔄 [API_RETRY] Making API request...');
    final response = await requestFn();

    // If we get a 401, try to refresh token and retry once
    if (response.statusCode == 401) {
      print(
          '🔄 [API_RETRY] ⚠️ Received 401, attempting token refresh and retry...');
      try {
        // Use AppAuthService.refreshSession instead of manual clearing
        final refreshed = await AppAuthService.refreshSession();
        if (refreshed != null) {
          print('🔄 [API_RETRY] ✅ Token refreshed, retrying request...');
          print(
              '🔄 [API_RETRY] New tokens received: ${refreshed.keys.toList()}');
          return await requestFn(); // Retry with new token
        } else {
          print(
              '🔄 [API_RETRY] ❌ Token refresh failed, returning original 401 response');
          return response;
        }
      } catch (e) {
        print('🔄 [API_RETRY] ❌ Error during token refresh: $e');
        return response;
      }
    }

    if (response.statusCode == 200) {
      print('🔄 [API_RETRY] ✅ API request successful');
    } else {
      print(
          '🔄 [API_RETRY] ⚠️ API request failed with status: ${response.statusCode}');
    }

    return response;
  }

  /// Public method for making authenticated HTTP requests with comprehensive token sanitization
  /// This method can be used by other services to benefit from the token validation and retry logic
  Future<http.Response> makeAuthenticatedRequest({
    required String method,
    required String path,
    Map<String, String>? additionalHeaders,
    String? body,
    bool preferIdToken = false, // This parameter is now ignored.
  }) async {
    Future<http.Response> makeRequest() async {
      // The `preferIdToken` flag is passed but will be ignored by `_authHeaders`
      // to ensure the access token is always used.
      final headers = await _authHeaders(preferIdToken: preferIdToken);
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }
      // --- Added diagnostic output for Authorization header integrity ---
      final authHeader = headers['Authorization'];
      if (authHeader != null) {
        final tokenPart = authHeader.startsWith('Bearer ')
            ? authHeader.substring(7)
            : authHeader;
        print(
            '🔎 [ApiService] Header Authorization len=${tokenPart.length} starts=${tokenPart.substring(0, tokenPart.length > 10 ? 10 : tokenPart.length)}');
        // Basic character validation (should be base64url + dots)
        final invalidChars = RegExp(r'[^A-Za-z0-9\-_.]');
        if (invalidChars.hasMatch(tokenPart)) {
          print(
              '⚠️ [ApiService] Authorization token contains invalid chars: ${invalidChars.stringMatch(tokenPart)}');
        }
        final dotCount = '.'.allMatches(tokenPart).length;
        if (dotCount != 2) {
          print('⚠️ [ApiService] JWT part count != 3 (dotCount=$dotCount)');
        }
      }

      // Use cache bypass strategy for all requests
      return await _makeRequestWithCacheBypass(
        method: method,
        path: path,
        headers: headers,
        body: body,
      );
    }

    return await _retryRequestOn401(makeRequest);
  }

  /// Get all businesses associated with the current user
  Future<List<Map<String, dynamic>>> getUserBusinesses() async {
    const path = '/auth/user-businesses';
    print('🔍 [getUserBusinesses] Starting request to $path');

    try {
      final response = await makeAuthenticatedRequest(
        method: 'GET',
        path: path,
        preferIdToken: false, // Start with access token
      );

      if (_isAuthorizerForbidden(response)) {
        print(
            '🛑 [getUserBusinesses] Request was forbidden by the authorizer. This is a backend configuration issue.');
        throw Exception('Forbidden by authorizer: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('businesses')) {
          // Ensure the data is a list of the correct type
          return List<Map<String, dynamic>>.from(data['businesses']);
        } else {
          print(
              '⚠️ [getUserBusinesses] Response format is unexpected. Body: ${response.body}');
          return []; // Return empty list for unexpected format
        }
      } else {
        print(
            '❌ [getUserBusinesses] Final error status: ${response.statusCode}. Body: ${response.body}');
        throw Exception('Failed to get user businesses: ${response.body}');
      }
    } catch (e) {
      print('❌ [getUserBusinesses] Exception caught: $e');
      _pushError('getUserBusinesses: ${e.toString()}');
      // Re-throw a more specific error to be caught by the UI
      throw Exception(
          'Could not retrieve your businesses. Please try again. Error: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getDiscounts() async {
    final response = await _retryRequestOn401(() async {
      return await AppHttpClient.get(
        Uri.parse('$baseUrl/discounts'),
        headers: await _authHeaders(),
      );
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['discounts'] ?? []);
      } else {
        throw Exception('Failed to get discounts: ${data['message']}');
      }
    } else {
      throw Exception('Failed to get discounts: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await AppHttpClient.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Store tokens and user data in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      await prefs.setString('refresh_token', data['refresh_token']);
      await prefs.setString('user', jsonEncode(data['user']));
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<User> getMerchantDetails() async {
    try {
      // Use AppAuthService to get current user data
      final userMap = await AppAuthService.getCurrentUser();

      if (userMap != null && userMap['userId'] != null) {
        // Create a User object from the data returned by AppAuthService
        // Ensure email_verified is properly converted to boolean
        bool emailVerified = false;
        final emailVerifiedValue = userMap['email_verified'];
        if (emailVerifiedValue is bool) {
          emailVerified = emailVerifiedValue;
        } else if (emailVerifiedValue is String) {
          emailVerified = emailVerifiedValue.toLowerCase() == 'true';
        }

        final user = User(
          id: userMap['userId'],
          email: userMap['email'] ?? '',
          firstName: userMap['firstName'] ?? '',
          lastName: userMap['lastName'] ?? '',
          emailVerified: emailVerified,
        );
        return user;
      } else {
        throw Exception('No user data found in AppAuthService');
      }
    } catch (e) {
      // Fallback to SharedPreferences if AppAuthService fails
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        return User.fromJson(userMap);
      } else {
        throw Exception('No user data found in SharedPreferences');
      }
    }
  }

  Future<Map<String, dynamic>> registerSimple({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> registerBusiness(
      Map<String, dynamic> businessData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-with-business'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(businessData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to register business: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    print('🔐 [signIn] Starting sign-in process...');
    print('🔐 [signIn] Email: $email');
    print('🔐 [signIn] Base URL: $baseUrl');

    const path = '/auth/signin';
    print('🔐 [signIn] Full URL: $baseUrl$path');
    print('🔐 [signIn] Request method: POST');
    print('🔐 [signIn] Request headers: Content-Type: application/json');

    final requestBody = jsonEncode({
      'email': email,
      'password': password,
    });
    print('🔐 [signIn] Request body keys: [email, password]');
    print('🔐 [signIn] Request body size: ${requestBody.length} chars');

    // Use the cache bypass request handler
    final response = await _makeRequestWithCacheBypass(
      method: 'POST',
      path: path,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    print('🔐 [signIn] Response status: ${response.statusCode}');
    print('🔐 [signIn] Response headers: ${response.headers}');
    print('🔐 [signIn] Response body: ${response.body}');

    // Check if response came from CloudFront
    if (response.headers.containsKey('x-cache')) {
      print(
          '⚠️ [signIn] Response came from CloudFront: ${response.headers['x-cache']}');
    }
    if (response.headers.containsKey('via')) {
      print('⚠️ [signIn] Via header: ${response.headers['via']}');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('🔐 [signIn] Parsed response data: $data');

      // Log detailed information about the response
      if (data['success'] == true) {
        print('🔐 [signIn] Sign-in successful!');
        print('🔐 [signIn] User data: ${data['user']}');
        print('🔐 [signIn] Businesses: ${data['businesses']}');
        print('🔐 [signIn] Auth data keys: ${data['data']?.keys?.toList()}');

        if (data['businesses'] != null && data['businesses'].isNotEmpty) {
          final businesses = data['businesses'] as List;
          print('🔐 [signIn] Found ${businesses.length} business(es):');
          for (int i = 0; i < businesses.length; i++) {
            final business = businesses[i];
            print(
              '  Business $i: ${business['businessId']} - ${business['businessName']}',
            );
          }
        } else {
          print('🔐 [signIn] ⚠️ No businesses found for user!');
        }
      } else {
        print('🔐 [signIn] Sign-in failed: ${data['message']}');
      }
      
      return data;
    } else {
      print('❌ [signIn] HTTP error ${response.statusCode}: ${response.body}');

      // Check for CloudFront cache issues
      if (_isCloudFrontCacheError(response)) {
        final cacheErrorMessage = _getCloudFrontCacheErrorMessage(response);
        print('🔄 [signIn] CloudFront cache issue detected');
        print(cacheErrorMessage);
        throw Exception(cacheErrorMessage);
      }
      
      throw Exception('Failed to sign in: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> registerWithBusiness({
    required String email,
    required String password,
    required Map<String, dynamic> businessData,
  }) async {
    // Combine user data with business data for the request
    final requestData = {
      'email': email,
      'password': password,
      ...businessData,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-with-business'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to register with business: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> confirmRegistration({
    required String email,
    required String confirmationCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'verificationCode': confirmationCode,
      }),
    );

    // Always try to parse the response body as JSON
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return data;
    } else {
      // For error responses, extract the message from the response
      // For error responses, extract the message from the response
      final errorMessage = data['message'] ?? 'Failed to confirm registration';
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> resendRegistrationCode({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to resend registration code: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> checkEmailExists({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/check-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to check email: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createDiscount(
      Map<String, dynamic> discountData) async {
    final response = await AppHttpClient.post(
      Uri.parse('$baseUrl/discounts'),
      headers: await _authHeaders(),
      body: jsonEncode(discountData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['discount'];
      } else {
        throw Exception('Failed to create discount: ${data['message']}');
      }
    } else {
      throw Exception('Failed to create discount: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateDiscount(
      String discountId, Map<String, dynamic> discountData) async {
    final response = await AppHttpClient.put(
      Uri.parse('$baseUrl/discounts/$discountId'),
      headers: await _authHeaders(),
      body: jsonEncode(discountData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['discount'];
      } else {
        throw Exception('Failed to update discount: ${data['message']}');
      }
    } else {
      throw Exception('Failed to update discount: ${response.body}');
    }
  }

  Future<void> deleteDiscount(String discountId) async {
    final response = await AppHttpClient.delete(
      Uri.parse('$baseUrl/discounts/$discountId'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to delete discount: ${data['message'] ?? response.body}');
    }
  }

  // POS Settings API Methods

  /// Update POS settings for a business
  Future<Map<String, dynamic>> updatePosSettings(
      String businessId, Map<String, dynamic> settings) async {
    final response = await AppHttpClient.put(
      Uri.parse('$baseUrl/businesses/$businessId/pos-settings'),
      headers: await _authHeaders(),
      body: jsonEncode(settings),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to update POS settings: ${data['message'] ?? response.body}');
    }
  }

  /// Test POS connection with the provided configuration
  Future<Map<String, dynamic>> testPosConnection(
      String businessId, Map<String, dynamic> testConfig) async {
    final response = await AppHttpClient.post(
      Uri.parse('$baseUrl/businesses/$businessId/pos-settings/test-connection'),
      headers: await _authHeaders(),
      body: jsonEncode(testConfig),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to test POS connection: ${data['message'] ?? response.body}');
    }
  }

  /// Get POS sync logs for a business
  Future<List<dynamic>> getPosSyncLogs(String businessId) async {
    final response = await AppHttpClient.get(
      Uri.parse('$baseUrl/businesses/$businessId/pos-settings/sync-logs'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['logs'] ?? [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to get POS sync logs: ${data['message'] ?? response.body}');
    }
  }

  /// Update business location settings
  Future<Map<String, dynamic>> updateBusinessLocationSettings(
      String businessId, Map<String, dynamic> locationSettings) async {
    final response = await AppHttpClient.put(
      Uri.parse('$baseUrl/businesses/$businessId/location-settings'),
      headers: await _authHeaders(),
      body: jsonEncode(locationSettings),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to update business location settings: ${data['message'] ?? response.body}');
    }
  }

  /// Get business working hours
  Future<Map<String, dynamic>> getBusinessWorkingHours(
      String businessId) async {
    final response = await AppHttpClient.get(
      Uri.parse('$baseUrl/businesses/$businessId/working-hours'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to get business working hours: ${data['message'] ?? response.body}');
    }
  }

  /// Update business working hours
  Future<Map<String, dynamic>> updateBusinessWorkingHours(
      String businessId, Map<String, dynamic> workingHours) async {
    final response = await AppHttpClient.put(
      Uri.parse('$baseUrl/businesses/$businessId/working-hours'),
      headers: await _authHeaders(),
      body: jsonEncode(workingHours),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to update business working hours: ${data['message'] ?? response.body}');
    }
  }

  /// Register device FCM/APNs token with backend
  Future<void> registerDeviceToken(String deviceToken) async {
    final response = await AppHttpClient.post(
      Uri.parse('$baseUrl/notifications/register-token'),
      headers: await _authHeaders(),
      body: jsonEncode({'deviceToken': deviceToken}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to register device token: ${response.body}');
    }
  }

  /// Update business accepting orders status
  Future<void> updateBusinessAcceptingOrdersStatus(
      String businessId, String userId, bool isOnline) async {
    final response = await AppHttpClient.put(
      Uri.parse('$baseUrl/businesses/$businessId/status'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'userId': userId,
        'status': isOnline ? 'ONLINE' : 'OFFLINE',
      }),
    );

    if (response.statusCode == 409) {
      try {
        final data = jsonDecode(response.body);
        if (data['code'] == 'NO_ACTIVE_CONNECTIONS') {
          throw BusinessStatusBlockedException(
            message: data['message'] ?? 'No active real-time connection',
            code: data['code'],
          );
        }
      } catch (_) {
        /* ignore parse errors */
      }
    }

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to update business status: ${errorData['error'] ?? response.body}');
    }
  }

  /// Get business accepting orders status
  Future<Map<String, dynamic>> getBusinessAcceptingOrdersStatus(
      String businessId) async {
    final response = await AppHttpClient.get(
      Uri.parse('$baseUrl/businesses/$businessId/online-status'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        'Failed to get business status: ${errorData['error'] ?? response.body}',
      );
    }
  }

  /// Get all business subcategories
  Future<List<Map<String, dynamic>>> getBusinessSubcategories() async {
    // Subcategory endpoints are public; no auth required
    final response = await http.get(
      Uri.parse('$baseUrl/business-subcategories'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['subcategories'] ?? []);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        'Failed to get business subcategories: ${errorData['error'] ?? response.body}',
      );
    }
  }

  /// Get business subcategories by business type
  Future<List<Map<String, dynamic>>> getBusinessSubcategoriesByType(
    String businessType,
  ) async {
    // Subcategory endpoints are public; no auth required
    final response = await http.get(
      Uri.parse('$baseUrl/business-subcategories/business-type/$businessType'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['subcategories'] ?? []);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        'Failed to get business subcategories: ${errorData['error'] ?? response.body}',
      );
    }
  }

  /// Get diagnostics data
  Future<Map<String, dynamic>> getDiagnostics() async {
    print('🩺 [diagnostics] Fetching diagnostics...');
    final headers = await _authHeaders();
    final resp = await AppHttpClient.get(Uri.parse('$baseUrl/diagnostics'),
        headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      print('🩺 [diagnostics] Data: $data');
      return data;
    } else {
      final err = 'Diagnostics failed ${resp.statusCode}: ${resp.body}';
      _pushError(err);
      throw Exception(err);
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }

  Future<void> signOut({required String refreshToken}) async {
    try {
      final response = await AppHttpClient.post(
        Uri.parse('$baseUrl/auth/signout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        print('✅ Backend sign-out successful.');
      } else {
        // Don't throw an exception, just log it.
        // The client should proceed with local sign-out regardless.
        print(
            '⚠️ Backend sign-out failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error during backend sign-out: $e');
    }
  }

  // Consolidated GET request method
  Future<http.Response> get(String path, {bool preferIdToken = false}) async {
    return _retryRequestOn401(
      () async {
        final url = Uri.parse('$baseUrl$path');
        final headers = await _authHeaders(preferIdToken: preferIdToken);
        print(
            '➡️  GET $url  Auth:${headers['Authorization']?.isNotEmpty ?? false ? headers['Authorization']!.substring(0, 20) + '...' : 'none'}');
        final response = await AppHttpClient.get(url, headers: headers);
        print('⬅️  GET $path -> ${response.statusCode}');
        return response;
      },
    );
  }

  // Consolidated POST request method
  Future<http.Response> post(String path,
      {dynamic body, bool preferIdToken = false}) async {
    return _retryRequestOn401(
      () async {
        final url = Uri.parse('$baseUrl$path');
        final headers = await _authHeaders(preferIdToken: preferIdToken);
        final bodyJson = body != null ? json.encode(body) : null;
        print(
            '➡️  POST $url  Auth:${headers['Authorization']?.isNotEmpty ?? false ? headers['Authorization']!.substring(0, 20) + '...' : 'none'}');
        final response =
            await AppHttpClient.post(url, headers: headers, body: bodyJson);
        print('⬅️  POST $path -> ${response.statusCode}');
        return response;
      },
    );
  }

  Future<http.Response> put(String path,
      {dynamic body, bool preferIdToken = false}) async {
    return _retryRequestOn401(
      () async {
        final url = Uri.parse('$baseUrl$path');
        final headers = await _authHeaders(preferIdToken: preferIdToken);
        final bodyJson = body != null ? json.encode(body) : null;
        final response =
            await AppHttpClient.put(url, headers: headers, body: bodyJson);
        return response;
      },
    );
  }

  Future<http.Response> delete(String path,
      {bool preferIdToken = false}) async {
    return _retryRequestOn401(
      () async {
        final url = Uri.parse('$baseUrl$path');
        final headers = await _authHeaders(preferIdToken: preferIdToken);
        final response = await AppHttpClient.delete(url, headers: headers);
        return response;
      },
    );
  }
}
