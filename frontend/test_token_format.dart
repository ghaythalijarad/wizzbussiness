// Simple test to verify JWT token format
import 'dart:convert';

void main() {
  // Example access token from the logs
  final token = "eyJraWQiOiJDUE44cWFJSlVRUktXVm05d05BeEF4eGYrUFk4RVNoM2Q1SGFmRlBqZFJ3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1NGU4ZjRkOC1jMDYxLTcwYzYtYjA3ZC01NGY1YjlhZTdkNTgiLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9QSFBrRzc4YjUiLCJjbGllbnRfaWQiOiIxdGw5ZzduazJrMmNodGo1Zmc5NjBmZ2R0aCIsIm9yaWdpbl9qdGkiOiI5YmQ1NmIwNS0wOTc1LTQ5MGEtYmI1MC0zM2U3NTJmNjVjOGQiLCJldmVudF9pZCI6IjM4ZjdhZDZlLTIyZGUtNDU5YS04ZDRlLThlMzkxN2IzZWZlMiIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuYWRtaW4iLCJhdXRoX3RpbWUiOjE3NTU3ODI3MTUsImV4cCI6MTc1NTc4NjMxNSwiaWF0IjoxNzU1NzgyNzE1LCJqdGkiOiI4YTVmMzlmNi01NzE5LTRmNzYtOGQ1MC0yODE4ZmUxNGUzYmYiLCJ1c2VybmFtZSI6IjU0ZThmNGQ4LWMwNjEtNzBjNi1iMDdkLTU0ZjViOWFlN2Q1OCJ9.jsLyLho-G6wOrU1QSEJhxxeBEhgo5ry4qOogKcp2LjH2AhzQsLKJFwKA2Eksmc_mOq8x6GnFuqvUnHs-qbUYx7-PIVsA2D8jAgYKVnZaSEici7J1OF80j4f9zR-CE68IZSpBZqR86GquQMiW-j9HsSHHB6I7PkTGnkUdsTyWtpd";

  print('Token length: ${token.length}');
  print('Token parts: ${token.split('.').length}');
  
  // Verify it's a valid JWT structure
  final parts = token.split('.');
  if (parts.length == 3) {
    print('✅ Valid JWT structure');
    
    // Decode header
    try {
      String headerB64 = parts[0].replaceAll('-', '+').replaceAll('_', '/');
      while (headerB64.length % 4 != 0) headerB64 += '=';
      final headerJson = utf8.decode(base64.decode(headerB64));
      final header = jsonDecode(headerJson);
      print('Header: $header');
      
      // Decode payload
      String payloadB64 = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payloadB64.length % 4 != 0) payloadB64 += '=';
      final payloadJson = utf8.decode(base64.decode(payloadB64));
      final payload = jsonDecode(payloadJson);
      print('Payload token_use: ${payload['token_use']}');
      print('Payload client_id: ${payload['client_id']}');
      print('Payload iss: ${payload['iss']}');
    } catch (e) {
      print('❌ Error decoding JWT: $e');
    }
  } else {
    print('❌ Invalid JWT structure');
  }
  
  // Check for problematic characters
  final problematicChars = RegExp(r'[^A-Za-z0-9\-_.]');
  if (problematicChars.hasMatch(token)) {
    print('❌ Token contains problematic characters');
  } else {
    print('✅ Token contains only valid JWT characters');
  }
  
  // Test authorization header format
  final authHeader = 'Bearer $token';
  print('Authorization header length: ${authHeader.length}');
  print('Authorization header starts with "Bearer ": ${authHeader.startsWith('Bearer ')}');
}
