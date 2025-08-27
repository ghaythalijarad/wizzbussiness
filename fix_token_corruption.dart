#!/usr/bin/env dart

// Fix token corruption by clearing all stored tokens and forcing fresh authentication
import 'dart:io';

void main() async {
  print('🧹 FIXING TOKEN CORRUPTION');
  print('==========================');
  
  try {
    // Get the iOS simulator application data directory
    final homeDir = Platform.environment['HOME'];
    final simulatorDir = '$homeDir/Library/Developer/CoreSimulator/Devices';
    
    print('📱 Looking for iPhone 16 Plus simulator data...');
    
    // Find the iPhone 16 Plus device directory
    final devicesDir = Directory(simulatorDir);
    if (!devicesDir.existsSync()) {
      print('❌ Simulator directory not found');
      return;
    }
    
    var foundDevice = false;
    await for (final deviceDir in devicesDir.list()) {
      if (deviceDir is Directory) {
        final devicePlistPath = '${deviceDir.path}/device.plist';
        final devicePlist = File(devicePlistPath);
        
        if (devicePlist.existsSync()) {
          final plistContent = await devicePlist.readAsString();
          if (plistContent.contains('iPhone 16 Plus')) {
            print('✅ Found iPhone 16 Plus simulator: ${deviceDir.path}');
            
            // Look for the app's data directory
            final appDataDir = Directory('${deviceDir.path}/data/Containers/Data/Application');
            if (appDataDir.existsSync()) {
              await for (final appDir in appDataDir.list()) {
                if (appDir is Directory) {
                  final prefsDir = Directory('${appDir.path}/Library/Preferences');
                  if (prefsDir.existsSync()) {
                    await for (final prefFile in prefsDir.list()) {
                      if (prefFile.path.contains('hadhir') || 
                          prefFile.path.contains('business') ||
                          prefFile.path.toLowerCase().contains('com.example')) {
                        print('🗑️ Removing preference file: ${prefFile.path}');
                        try {
                          await prefFile.delete();
                          foundDevice = true;
                        } catch (e) {
                          print('⚠️ Could not delete ${prefFile.path}: $e');
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    
    if (foundDevice) {
      print('✅ Token cleanup completed!');
      print('📱 Please restart the Flutter app to see the effect');
    } else {
      print('⚠️ Could not find app data to clear');
      print('💡 Alternative: Manually reset simulator content and settings');
    }
    
  } catch (e) {
    print('❌ Error during cleanup: $e');
    print('💡 Alternative: Reset simulator via Device > Erase All Content and Settings');
  }
  
  print('\n🔄 Next steps:');
  print('1. Stop the Flutter app if running');
  print('2. Restart the Flutter app'); 
  print('3. The app should now request fresh authentication');
  print('4. Try saving location settings again');
}
