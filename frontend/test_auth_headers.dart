import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple test script to validate JWT token format and HTTP headers
void main() async {
  // Sample JWT tokens from the logs
  const sampleAccessToken = "eyJraWQiOiJDUE44cWFJSlVRUktXVm05d05BeEF4eGYrUFk4RVNoM2Q1SGFmRlBqZFJ3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1NGU4ZjRkOC1jMDYxLTcwYzYtYjA3ZC01NGY1YjlhZTdkNTgiLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9QSFBrRzc4YjUiLCJjbGllbnRfaWQiOiIxdGw5ZzduazJrMmNodGo1Zmc5NjBmZ2R0aCIsIm9yaWdpbl9qdGkiOiI5YmQ1NmIwNS0wOTc1LTQ5MGEtYmI1MC0zM2U3NTJmNjVjOGQiLCJldmVudF9pZCI6IjM4ZjdhZDZlLTIyZGUtNDU5YS04ZDRlLThlMzkxN2IzZWZlMiIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuYWRtaW4iLCJhdXRoX3RpbWUiOjE3NTU3ODI3MTUsImV4cCI6MTc1NTc4NjMxNSwiaWF0IjoxNzU1NzgyNzE1LCJqdGkiOiI4YTVmMzlmNi01NzE5LTRmNzYtOGQ1MC0yODE4ZmUxNGUzYmYiLCJ1c2VybmFtZSI6IjU0ZThmNGQ4LWMwNjEtNzBjNi1iMDdkLTU0ZjViOWFlN2Q1OCJ9.jsLyLho-G6wOrU1QSEJhxxeBEhgo5ry4qOogKcp2LjH2AhzQsLKJFwKA2Eksmc_mOq8x6GnFuqvUnHs-qbUYx7-PIVsA2D8jAgYKVnZaSEici7J1OF80j4f9zR-CE68IZSpBZqR86GquQMiW-j9HsSHHB6I7PkTGnkUdsTyWtpd_";
  
  print("=== JWT Token Validation ===");
  
  // Test 1: Check JWT structure
  final parts = sampleAccessToken.split('.');
  print("JWT parts count: ${parts.length}");
  print("Header length: ${parts[0].length}");
  print("Payload length: ${parts[1].length}");
  print("Signature length: ${parts[2].length}");
  
  // Test 2: Check for problematic characters
  final problematicChars = RegExp(r'[^A-Za-z0-9\-_.]');
  final matches = problematicChars.allMatches(sampleAccessToken);
  print("Problematic characters found: ${matches.length}");
  for (final match in matches) {
    print("  Character '${match.group(0)}' at position ${match.start}");
  }
  
  // Test 3: Test header format
  final headers = {
    'Authorization': 'Bearer $sampleAccessToken',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  print("\n=== HTTP Header Test ===");
  print("Authorization header length: ${headers['Authorization']!.length}");
  print("Authorization starts with 'Bearer ': ${headers['Authorization']!.startsWith('Bearer ')}");
  
  // Test 4: Check for hidden characters
  final authHeader = headers['Authorization']!;
  final bytes = utf8.encode(authHeader);
  print("Authorization header bytes length: ${bytes.length}");
  print("Contains null bytes: ${bytes.contains(0)}");
  print("Contains control characters: ${bytes.any((byte) => byte < 32 && byte != 9 && byte != 10 && byte != 13)}");
  
  // Test 5: Simulate API call format
  print("\n=== API Call Simulation ===");
  final testUri = Uri.parse('https://httpbin.org/headers');
  
  try {
    print("Making test request to httpbin.org to validate headers...");
    final response = await http.get(testUri, headers: headers);
    print("Test response status: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final receivedHeaders = responseData['headers'];
      print("Server received Authorization header: ${receivedHeaders['Authorization']}");
    }
  } catch (e) {
    print("Test request failed: $e");
  }
  
  print("\n=== Token Decode Test ===");
  try {
    // Decode JWT payload
    String payloadB64 = parts[1];
    
    // Add padding if needed
    while (payloadB64.length % 4 != 0) {
      payloadB64 += '=';
    }
    
    // Replace URL-safe characters
    payloadB64 = payloadB64.replaceAll('-', '+').replaceAll('_', '/');
    
    final payloadBytes = base64.decode(payloadB64);
    final payloadJson = utf8.decode(payloadBytes);
    final payload = jsonDecode(payloadJson);
    
    print("Token type: ${payload['token_use']}");
    print("Client ID: ${payload['client_id']}");
    print("Scope: ${payload['scope']}");
    print("Issuer: ${payload['iss']}");
    print("Expiry: ${DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000)}");
    
  } catch (e) {
    print("JWT decode failed: $e");
  }
}
