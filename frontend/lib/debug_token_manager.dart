import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/token_manager.dart';
import 'services/auth_header_builder.dart';

/// Debug script to test TokenManager and authorization header fixes
class TokenManagerDebugger {
  
  /// Test token sanitization with various corruption scenarios
  static Future<void> testTokenSanitization() async {
    print('\n🧪 TESTING TOKEN MANAGER SANITIZATION');
    print('=' * 50);

    // Test scenarios that previously caused issues
    final testTokens = [
      // Scenario 1: Clean token (should pass through)
      'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.EkN-DOsnsuRjRO6BxXemmJDm3HbxrbRzXglbN2S4sOkopdU4IsDxTI8jO19W_A4K8ZPJijNLis4EZsHeY559a4DFOd50_OqgHs3PH-oW_H5C6VBwkL9GyaKI4A7K_-CXWaWZj7mVBGHIgBV0-QYRPzR9_7VdqVVqw6wK_wQgZ',
      
      // Scenario 2: Token with pipe characters (like the error we saw)
      '=3PLDJBQY1A5nL+X29R+|fUgtDC9QMwz1|2k6WyIMWH4',
      
      // Scenario 3: Token with whitespace corruption
      '  \n\reyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.corrupted.token  \t\n',
      
      // Scenario 4: Bearer prefix corruption
      'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.test.token',
      
      // Scenario 5: Empty/null scenarios
      '',
      '   \n\r\t   ',
    ];

    for (int i = 0; i < testTokens.length; i++) {
      final testToken = testTokens[i];
      print('\n📋 Test ${i + 1}: ${_describeToken(testToken)}');
      print('   Input: "${testToken}"');
      
      try {
        await TokenManager.setAccessToken(testToken);
        final retrieved = await TokenManager.getAccessToken();
        
        if (retrieved != null && retrieved.isNotEmpty) {
          print('   ✅ Sanitized: "${retrieved}" (${retrieved.length} chars)');
          print('   ✅ Valid JWT format: ${_isValidJWT(retrieved)}');
        } else {
          print('   ✅ Rejected empty/invalid token');
        }
      } catch (e) {
        print('   ❌ Error: $e');
      }
    }
  }

  /// Test authorization header construction
  static Future<void> testAuthHeaderConstruction() async {
    print('\n🔐 TESTING AUTHORIZATION HEADER CONSTRUCTION');
    print('=' * 50);
    
    // Store a test token
    const testToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.EkN-DOsnsuRjRO6BxXemmJDm3HbxrbRzXglbN2S4sOkopdU4IsDxTI8jO19W_A4K8ZPJijNLis4EZsHeY559a4DFOd50_OqgHs3PH-oW_H5C6VBwkL9GyaKI4A7K_-CXWaWZj7mVBGHIgBV0-QYRPzR9_7VdqVVqw6wK_wQgZ';
    
    await TokenManager.setAccessToken(testToken);
    
    try {
      final headers = await AuthHeaderBuilder.build();
      print('📤 Standard headers:');
      headers.forEach((key, value) {
        print('   $key: ${value.length > 50 ? "${value.substring(0, 50)}..." : value}');
      });
      
      final altHeaders = await AuthHeaderBuilder.buildAlternative();
      print('\n📤 Alternative headers:');
      altHeaders.forEach((key, value) {
        print('   $key: ${value.length > 50 ? "${value.substring(0, 50)}..." : value}');
      });
      
      // Validate no corruption
      final authHeader = headers['Authorization'];
      if (authHeader != null) {
        final hasPipeChars = authHeader.contains('|');
        final hasLeadingEquals = authHeader.startsWith('=') || authHeader.contains('Bearer =');
        final hasValidFormat = authHeader.startsWith('Bearer ') && authHeader.length > 10;
        
        print('\n🔍 Header validation:');
        print('   ✅ No pipe characters: ${!hasPipeChars}');
        print('   ✅ No leading equals: ${!hasLeadingEquals}');
        print('   ✅ Valid Bearer format: $hasValidFormat');
        
        if (hasPipeChars || hasLeadingEquals || !hasValidFormat) {
          print('   ❌ AUTHORIZATION HEADER CORRUPTION DETECTED!');
        } else {
          print('   ✅ Authorization header is clean');
        }
      }
      
    } catch (e) {
      print('❌ Error building headers: $e');
    }
  }

  /// Test a simulated login-to-location-save flow
  static Future<void> testLocationSaveFlow() async {
    print('\n📍 TESTING LOCATION SAVE FLOW SIMULATION');
    print('=' * 50);
    
    // Simulate corrupted token from backend (like the issue we saw)
    const corruptedBackendToken = '\n  =3PLDJBQY1A5nL+X29R+|fUgtDC9QMwz1|2k6WyIMWH4  \r\n';
    
    print('📥 Simulating corrupted token from backend:');
    print('   Raw: "$corruptedBackendToken"');
    
    // Store it through TokenManager (this should sanitize it)
    await TokenManager.setAccessToken(corruptedBackendToken);
    
    // Retrieve and test header construction
    final sanitizedToken = await TokenManager.getAccessToken();
    print('✨ After TokenManager sanitization:');
    print('   Clean: "$sanitizedToken"');
    
    if (sanitizedToken != null && sanitizedToken.isNotEmpty) {
      try {
        final headers = await AuthHeaderBuilder.build();
        final authHeader = headers['Authorization'];
        print('🔐 Final authorization header:');
        print('   $authHeader');
        
        // Check for the specific error pattern
        if (authHeader != null) {
          final hasCorruption = authHeader.contains('|') || authHeader.contains('Bearer =');
          if (hasCorruption) {
            print('   ❌ STILL HAS CORRUPTION - FIX FAILED');
          } else {
            print('   ✅ CORRUPTION FIXED - READY FOR API CALLS');
          }
        }
      } catch (e) {
        print('   ❌ Header construction failed: $e');
      }
    } else {
      print('   ❌ Token was completely invalid and rejected');
    }
  }

  /// Describe a token for debugging
  static String _describeToken(String token) {
    if (token.isEmpty) return 'Empty token';
    if (token.trim().isEmpty) return 'Whitespace-only token';
    if (token.contains('|')) return 'Token with pipe characters';
    if (token.startsWith('=')) return 'Token with leading equals';
    if (token.toLowerCase().startsWith('bearer')) return 'Token with Bearer prefix';
    if (token.contains('\n') || token.contains('\r')) return 'Token with newlines';
    return 'Clean token';
  }

  /// Basic JWT format validation
  static bool _isValidJWT(String token) {
    if (token.isEmpty) return false;
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }
}

/// Run all token manager tests
Future<void> main() async {
  print('🚀 TOKEN MANAGER DEBUG SUITE');
  print('Testing the fix for authorization header corruption');
  print('=' * 60);
  
  await TokenManagerDebugger.testTokenSanitization();
  await TokenManagerDebugger.testAuthHeaderConstruction();
  await TokenManagerDebugger.testLocationSaveFlow();
  
  print('\n🎉 TOKEN MANAGER DEBUG COMPLETE');
  print('If all tests show ✅, the authorization corruption should be fixed.');
}
