#!/bin/bash

echo "🧪 TESTING COMPREHENSIVE TOKEN SANITIZATION FIX"
echo "==============================================="

cd /Users/ghaythallaheebi/order-receiver-app-2/frontend

# Create a test script that will simulate the token corruption and test the fix
cat > test_token_sanitization_fix.dart << 'EOF'
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/utils/token_manager.dart';
import 'lib/services/app_auth_service.dart';

void main() async {
  print('🧪 TESTING TOKEN SANITIZATION FIX');
  print('==================================');
  
  // Test patterns that have been causing the "Invalid key=value pair" error
  final corruptedTokens = [
    'VluqHyE7IrQ\n.rrd4knvhfHZqyU220i15Ad+PXYIkR5Z0',  // The exact pattern from error
    'eyJhbGcийаllциOiJSUzI1NiJ9.payload.signature',        // Cyrillic characters
    'eyJhbGciOiJSUzI1NiJ9\n.payload\n.signature',         // Line breaks
    'token with spaces and\ttabs',                          // Spaces and tabs
    'token"with"quotes\'and\'more',                         // Quotes
    'Bearer eyJhbGciOiJSUzI1NiJ9.payload.signature',       // Accidental Bearer prefix
  ];
  
  print('\n🔧 Testing TokenManager sanitization...');
  
  for (int i = 0; i < corruptedTokens.length; i++) {
    final corruptedToken = corruptedTokens[i];
    print('\n--- Test ${i + 1} ---');
    print('Original: "${corruptedToken}"');
    print('Length: ${corruptedToken.length}');
    print('Has newlines: ${corruptedToken.contains('\n')}');
    print('Has Cyrillic: ${RegExp(r'[\u0400-\u04FF]').hasMatch(corruptedToken)}');
    
    try {
      // Test storing the corrupted token
      await TokenManager.setAccessToken(corruptedToken);
      
      // Test retrieving it (should be sanitized)
      final retrievedToken = await TokenManager.getAccessToken();
      
      print('Retrieved: "$retrievedToken"');
      print('Sanitized length: ${retrievedToken?.length ?? 0}');
      
      // Validate the retrieved token is clean
      if (retrievedToken != null) {
        final isClean = !retrievedToken.contains('\n') && 
                       !retrievedToken.contains('\r') && 
                       !retrievedToken.contains(' ') &&
                       !RegExp(r'[\u0400-\u04FF]').hasMatch(retrievedToken);
        print('Is clean: $isClean');
        
        if (!isClean) {
          print('❌ SANITIZATION FAILED!');
          exit(1);
        }
      }
      
    } catch (e) {
      print('❌ Error: $e');
      exit(1);
    }
  }
  
  print('\n✅ All token sanitization tests passed!');
  print('✅ The "Invalid key=value pair" error should now be fixed');
  
  // Clean up
  await TokenManager.clearAccessToken();
  
  exit(0);
}
EOF

echo "🚀 Running token sanitization tests..."
dart test_token_sanitization_fix.dart

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Token sanitization is working correctly"
    echo "🔧 The fix should resolve the 'Invalid key=value pair' error in POST requests"
    echo ""
    echo "Next steps:"
    echo "1. Hot reload the Flutter app to pick up the changes"
    echo "2. Try creating a product to test the fix"
    echo "3. Check that no more 'Invalid key=value pair' errors occur"
else
    echo "❌ FAILED! There are still issues with token sanitization"
    exit 1
fi

# Clean up test file
rm -f test_token_sanitization_fix.dart
