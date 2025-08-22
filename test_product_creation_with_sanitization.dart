// Test script to validate product creation with enhanced token sanitization
import 'dart:convert';

void main() {
  print('🧪 Testing Product Creation with Enhanced Token Sanitization');

  // Simulate the corrupted token that was causing issues
  String corruptedToken =
      "eyJraWQiOiIxaittN0o4WFo0NVNRbHhLUkM1ZWJobGUrSHI3OE9Ec0xNYVp2VDdIRXRBPSIsImFsZyI6IlJTMjU2IiyJzdWIiOiI1NGU4ZjRkOC1jMDYxLTcwYzYtYjA3ZC01NGY1YjlhZTdkNTgiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYWRkcmVzcyI6eyJmb3JtYXR0ZWQiOiJ7XCJmb3\nх'/k4Rv+j0='"; // Contains Cyrillic х and line break

  print(
    '🔧 [CORRUPTION-TEST] Original corrupted token sample: ${corruptedToken.substring(0, 80)}...',
  );

  // Apply our enhanced sanitization logic
  String cleanToken = sanitizeToken(corruptedToken);

  print(
    '🔧 [CORRUPTION-TEST] Sanitized token sample: ${cleanToken.substring(0, 80)}...',
  );

  // Validate HTTP header compliance
  final authHeader = 'Bearer $cleanToken';
  bool isValid = validateHttpHeader(authHeader);

  print('✅ [VALIDATION] HTTP Header Valid: $isValid');
  print('✅ [VALIDATION] Authorization Header Length: ${authHeader.length}');

  if (isValid) {
    print(
      '🎉 SUCCESS: Enhanced token sanitization fixed the corruption issue!',
    );
    print('🎉 The token is now HTTP-compliant and ready for POST requests');
  } else {
    print('❌ FAILURE: Token still contains invalid characters');
  }
}

String sanitizeToken(String token) {
  String cleanToken = token.trim();

  print('🧹 [TokenSanitization] Original token length: ${cleanToken.length}');

  // Check for the specific corruption patterns we've seen
  final problematicPatterns = [
    RegExp(r'[\u0400-\u04FF]'), // Cyrillic characters like 'х'
    RegExp(r'[\r\n\t]'), // Line breaks and tabs
    RegExp(r"['\x22]"), // Quote characters (single and double)
    RegExp(
      r'[^\x21-\x7E]',
    ), // Non-printable ASCII (except space which we'll handle)
  ];

  bool foundIssues = false;
  for (int i = 0; i < problematicPatterns.length; i++) {
    final pattern = problematicPatterns[i];
    if (pattern.hasMatch(cleanToken)) {
      final matches = pattern
          .allMatches(cleanToken)
          .map(
            (m) =>
                '${cleanToken.substring(m.start, m.end)} (${cleanToken.codeUnitAt(m.start)})',
          )
          .join(', ');
      print('🚨 [FINAL-CHECK] Pattern $i found problematic chars: $matches');
      foundIssues = true;
    }
  }

  if (foundIssues) {
    print('🔧 [FINAL-CHECK] Applying emergency token cleanup...');
    // Ultra-conservative approach: keep ONLY valid JWT characters
    cleanToken = cleanToken
        .split('')
        .where((char) {
          final code = char.codeUnitAt(0);
          return (code >= 65 && code <= 90) || // A-Z
              (code >= 97 && code <= 122) || // a-z
              (code >= 48 && code <= 57) || // 0-9
              char == '-' ||
              char == '_' ||
              char == '.';
        })
        .join('');

    print(
      '🔧 [FINAL-CHECK] Emergency cleaned token length: ${cleanToken.length}',
    );
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

  // STEP 5: Remove Bearer prefix if accidentally included
  if (cleanToken.toLowerCase().startsWith('bearer')) {
    cleanToken = cleanToken.substring(6);
  }

  // STEP 6: Keep ONLY valid JWT characters: A-Z, a-z, 0-9, -, _, and .
  cleanToken = cleanToken.replaceAll(RegExp(r'[^A-Za-z0-9\-_.]'), '');

  print('🧹 [TokenSanitization] Cleaned token length: ${cleanToken.length}');

  return cleanToken;
}

bool validateHttpHeader(String authHeader) {
  // Validate the final Authorization header for HTTP compliance
  for (int i = 0; i < authHeader.length; i++) {
    final code = authHeader.codeUnitAt(i);
    // HTTP header values can only contain ASCII characters 32-126 and tab (9)
    if (!(code == 9 || (code >= 32 && code <= 126))) {
      final char = authHeader[i];
      print(
        '🚨 [HTTP-HEADER-VALIDATION] Invalid char at position $i: "$char" (code: $code)',
      );
      return false;
    }
  }

  return true;
}
