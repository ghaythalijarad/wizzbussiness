import 'dart:io';
import 'package:http/http.dart' as http;

/// Direct test to reproduce and fix the token corruption issue
void main() async {
  print('🚨 TOKEN CORRUPTION REPRODUCTION TEST');
  print('=====================================');

  // These are the exact token patterns we've seen causing errors
  final corruptedTokens = [
    'VluqHyE7IrQ\n.' + 'rrd4knvhfHZqyU220i15Ad+PXYIkR5Z0',
    'sometoken\nwithlinebreak',
    'tokenwithкириллица',
    'token with spaces',
    'token"with"quotes',
    "token'with'singlequotes",
    'tokenwithуникод',
    'validtoken.part.signature',
  ];

  print('\n🧪 Testing each corrupted token pattern...\n');

  for (int i = 0; i < corruptedTokens.length; i++) {
    final token = corruptedTokens[i];
    print('═══════════════════════════════════════');
    print('Test ${i + 1}: "${token}"');
    print('Length: ${token.length}');
    print('Has newlines: ${token.contains('\n')}');
    print('Has Cyrillic: ${RegExp(r'[\u0400-\u04FF]').hasMatch(token)}');

    // Test what happens when we try to use it in Authorization header
    try {
      final authHeader = 'Bearer $token';
      print('Authorization header: "$authHeader"');

      // Check for HTTP compliance
      bool hasInvalidChars = false;
      for (int j = 0; j < authHeader.length; j++) {
        final code = authHeader.codeUnitAt(j);
        if (!(code == 9 || (code >= 32 && code <= 126))) {
          print(
            '❌ Invalid character at position $j: ${authHeader[j]} (code: $code)',
          );
          hasInvalidChars = true;
        }
      }

      if (!hasInvalidChars) {
        print('✅ Authorization header is HTTP compliant');
      }

      // Apply our sanitization and test again
      String cleanedToken = applySanitization(token);
      final cleanedAuthHeader = 'Bearer $cleanedToken';
      print('Cleaned token: "$cleanedToken"');
      print('Cleaned auth header: "$cleanedAuthHeader"');

      // Validate cleaned version
      bool cleanedHasInvalidChars = false;
      for (int j = 0; j < cleanedAuthHeader.length; j++) {
        final code = cleanedAuthHeader.codeUnitAt(j);
        if (!(code == 9 || (code >= 32 && code <= 126))) {
          cleanedHasInvalidChars = true;
          break;
        }
      }

      if (!cleanedHasInvalidChars) {
        print('✅ Cleaned Authorization header is HTTP compliant');
      } else {
        print('❌ Cleaned Authorization header still has invalid characters');
      }
    } catch (e) {
      print('❌ Error creating auth header: $e');
    }

    print('');
  }

  print('\n🎯 TESTING ACTUAL HTTP REQUEST WITH CORRUPTED TOKEN');
  print('==================================================');

  // Test making an actual HTTP request with a corrupted token
  final corruptedToken = 'VluqHyE7IrQ\n.' + 'rrd4knvhfHZqyU220i15Ad+PXYIkR5Z0';

  try {
    print('Testing with corrupted token: "$corruptedToken"');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $corruptedToken',
    };

    print('Headers: $headers');

    final response = await http.get(
      Uri.parse('https://httpbin.org/headers'),
      headers: headers,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  } catch (e) {
    if (e.toString().contains('Invalid key=value pair')) {
      print('🚨 REPRODUCED THE ERROR! Invalid key=value pair error occurred');
    }
    print('❌ HTTP request failed: $e');
  }

  print('\n✅ Testing with sanitized token...');

  try {
    final sanitizedToken = applySanitization(corruptedToken);
    print('Sanitized token: "$sanitizedToken"');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $sanitizedToken',
    };

    final response = await http.get(
      Uri.parse('https://httpbin.org/headers'),
      headers: headers,
    );

    print('✅ Sanitized request succeeded!');
    print('Response status: ${response.statusCode}');
  } catch (e) {
    print('❌ Even sanitized request failed: $e');
  }
}

/// Apply the same sanitization logic as the app
String applySanitization(String token) {
  String cleanToken = token.trim();

  // Remove ALL non-printable ASCII characters (0x00-0x1F, 0x7F-0xFF)
  cleanToken = cleanToken.replaceAll(RegExp(r'[\x00-\x1F\x7F-\xFF]'), '');

  // Remove ALL Unicode characters (anything above ASCII 127)
  cleanToken = cleanToken.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

  // Remove ALL whitespace characters (spaces, tabs, newlines, etc.)
  cleanToken = cleanToken.replaceAll(RegExp(r'\s'), '');

  // Remove specific problematic characters we've seen
  cleanToken = cleanToken.replaceAll('\r', '');
  cleanToken = cleanToken.replaceAll('\n', '');
  cleanToken = cleanToken.replaceAll('\t', '');
  cleanToken = cleanToken.replaceAll("'", ''); // Remove single quotes
  cleanToken = cleanToken.replaceAll('"', ''); // Remove double quotes

  // Remove Bearer prefix if accidentally included
  if (cleanToken.toLowerCase().startsWith('bearer')) {
    cleanToken = cleanToken.substring(6);
  }

  // Keep ONLY valid JWT characters: A-Z, a-z, 0-9, -, _, and .
  cleanToken = cleanToken.replaceAll(RegExp(r'[^A-Za-z0-9\-_.]'), '');

  return cleanToken;
}
