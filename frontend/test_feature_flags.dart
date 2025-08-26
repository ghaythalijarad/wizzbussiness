import 'package:flutter/material.dart';
import 'lib/config/app_config.dart';

void main() {
  // Test development environment
  print('=== Development Environment ===');
  print('Environment: ${AppConfig.environment}');
  print('Base URL: ${AppConfig.baseUrl}');
  print('Floating Notifications: ${AppConfig.enableFloatingNotifications}');
  print('Firebase Push: ${AppConfig.enableFirebasePush}');
  print('Search Functionality: ${AppConfig.enableSearchFunctionality}');
  print('');
  
  // Print configuration
  AppConfig.printConfig();
  
  print('✅ Feature flag test completed');
}
