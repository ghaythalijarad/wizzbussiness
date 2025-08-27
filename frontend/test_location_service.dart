import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lib/services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await testLocationService();
}

Future<void> testLocationService() async {
  print('🧪 Testing LocationService...');
  
  // Test 1: Check if location service is supported
  print('📍 Test 1: Checking if location service is supported');
  bool isSupported = LocationService.isSupported;
  print('📍 Location service supported: $isSupported');
  
  // Test 2: Check if location services are enabled
  print('📍 Test 2: Checking if location services are enabled');
  try {
    bool serviceEnabled = await LocationService.isLocationServiceEnabled();
    print('📍 Location services enabled: $serviceEnabled');
  } catch (e) {
    print('📍 Error checking location service: $e');
  }
  
  // Test 3: Check permission status
  print('📍 Test 3: Checking permission status');
  try {
    bool hasPermission = await LocationService.hasPermission();
    print('📍 Has location permission: $hasPermission');
  } catch (e) {
    print('📍 Error checking permission: $e');
  }
  
  // Test 4: Request permission
  print('📍 Test 4: Requesting location permission');
  try {
    bool permissionGranted = await LocationService.requestPermission();
    print('📍 Permission granted: $permissionGranted');
  } catch (e) {
    print('📍 Error requesting permission: $e');
  }
  
  // Test 5: Get current location
  print('📍 Test 5: Getting current location');
  try {
    Map<String, double>? location = await LocationService.getCurrentLocation();
    if (location != null) {
      print('📍 Current location: ${location['latitude']}, ${location['longitude']}');
      print('✅ Location service test PASSED - Got coordinates!');
    } else {
      print('❌ Location service test FAILED - Got null location');
    }
  } catch (e) {
    print('📍 Error getting location: $e');
    print('❌ Location service test FAILED with exception');
  }
  
  print('🧪 Location service test completed');
}
