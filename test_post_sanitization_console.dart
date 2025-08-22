/// Quick console test to verify POST request token sanitization
/// This simulates the exact conditions that would cause the "Invalid key=value pair" error

void main() async {
  print('🧪 POST Request Sanitization Console Test');
  print('==========================================');

  // Test cases that would typically cause "Invalid key=value pair" errors
  final testTokens = [
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
    'Bearer eyJhbGциОиJIUzI1NiIsInR5cCI6IkpXVCJ9.corrupted-token', // Cyrillic characters
    'Bearer \neyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\n.newline-token', // Line breaks
    'Bearer eyJhbGci\rOiJIUzI1NiIsInR5cCI6IkpXVCJ9.carriage-return', // Carriage returns
    'Bearer   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.extra-spaces   ', // Extra spaces
    'Bearer Russian: Русский текст in token', // Cyrillic text
    'Bearer \u0000\u0001\u0002control-chars', // Control characters
  ];

  for (int i = 0; i < testTokens.length; i++) {
    final token = testTokens[i];
    print('\n🔍 Test ${i + 1}: Testing token with potential issues');
    print(
      'Original: "${token.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}"',
    );

    final sanitized = sanitizeAuthToken(token);
    print('Sanitized: "$sanitized"');

    final isValid = isValidHttpHeaderValue(sanitized);
    print('Valid HTTP header: ${isValid ? "✅" : "❌"}');

    if (!isValid) {
      print('❌ This token would cause "Invalid key=value pair" error!');
    }
  }

  print('\n📊 Summary:');
  print('- All tokens should be sanitized to valid HTTP header format');
  print(
    '- No tokens should contain line breaks, control characters, or non-ASCII',
  );
  print('- Bearer prefix should be preserved and properly formatted');
}

/// Sanitize an authorization token for HTTP headers
String sanitizeAuthToken(String token) {
  if (token.isEmpty) return '';

  try {
    // Remove any existing Bearer prefix for processing
    String cleanToken = token;
    if (cleanToken.toLowerCase().startsWith('bearer ')) {
      cleanToken = cleanToken.substring(7);
    }

    // Ultra-aggressive sanitization
    // 1. Remove all whitespace including line breaks, tabs, etc.
    cleanToken = cleanToken.replaceAll(RegExp(r'\s+'), '');

    // 2. Remove control characters (0x00-0x1F and 0x7F-0x9F)
    cleanToken = cleanToken.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');

    // 3. Remove Cyrillic and other non-ASCII characters
    cleanToken = cleanToken.replaceAll(RegExp(r'[^\x20-\x7E]'), '');

    // 4. Remove any characters that could break HTTP headers
    cleanToken = cleanToken.replaceAll(RegExp(r'[<>{}|\\\^`\[\]]'), '');

    // 5. Ensure it only contains valid JWT characters (A-Z, a-z, 0-9, +, /, =, -, _)
    cleanToken = cleanToken.replaceAll(RegExp(r'[^A-Za-z0-9+/=._-]'), '');

    // 6. Reconstruct with Bearer prefix
    if (cleanToken.isNotEmpty) {
      return 'Bearer $cleanToken';
    } else {
      return 'Bearer invalid-token-sanitized';
    }
  } catch (e) {
    print('❌ Error during sanitization: $e');
    return 'Bearer error-during-sanitization';
  }
}

/// Check if a string is a valid HTTP header value
bool isValidHttpHeaderValue(String value) {
  if (value.isEmpty) return false;

  // HTTP header values should not contain control characters or line breaks
  for (int i = 0; i < value.length; i++) {
    final char = value.codeUnitAt(i);

    // Check for control characters (0x00-0x1F except space 0x20) and DEL (0x7F)
    if ((char >= 0x00 && char <= 0x1F && char != 0x20) || char == 0x7F) {
      return false;
    }

    // Check for line breaks specifically
    if (char == 0x0A || char == 0x0D) {
      // LF or CR
      return false;
    }
  }

  return true;
}
