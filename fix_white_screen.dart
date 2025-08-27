#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🧹 FIXING WHITE SCREEN - CLEARING CORRUPTED TOKENS');
  print('===================================================');
  
  try {
    // Method 1: Clear iOS Simulator app data
    print('\n🔄 Step 1: Clearing iOS Simulator app data...');
    
    final clearAppDataResult = await Process.run('xcrun', [
      'simctl',
      'privacy',
      'A3DDA783-158C-4D71-B5D6-E617966BE41D',
      'reset',
      'all',
      'com.hadhir.business'
    ]);
    
    if (clearAppDataResult.exitCode == 0) {
      print('✅ iOS Simulator app data cleared');
    } else {
      print('⚠️ Could not clear app data: ${clearAppDataResult.stderr}');
    }
    
    // Method 2: Flutter clean and restart
    print('\n🔄 Step 2: Flutter clean...');
    
    final cleanResult = await Process.run('flutter', ['clean'], 
        workingDirectory: '/Users/ghaythallaheebi/order-receiver-app-2/frontend');
    
    if (cleanResult.exitCode == 0) {
      print('✅ Flutter clean completed');
    } else {
      print('❌ Flutter clean failed: ${cleanResult.stderr}');
    }
    
    // Method 3: Flutter pub get
    print('\n🔄 Step 3: Flutter pub get...');
    
    final pubGetResult = await Process.run('flutter', ['pub', 'get'], 
        workingDirectory: '/Users/ghaythallaheebi/order-receiver-app-2/frontend');
    
    if (pubGetResult.exitCode == 0) {
      print('✅ Flutter pub get completed');
    } else {
      print('❌ Flutter pub get failed: ${pubGetResult.stderr}');
    }
    
    print('\n🎉 CLEANUP COMPLETE!');
    print('📱 Now restart the Flutter app to test the TokenManager fix');
    
  } catch (e) {
    print('❌ Error during cleanup: $e');
  }
}
