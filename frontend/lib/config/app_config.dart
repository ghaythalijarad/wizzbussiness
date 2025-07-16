import 'dart:io';

/// Application configuration for different environments
///
/// Backend Architecture:
/// - AWS Lambda Functions (Serverless)
/// - AWS API Gateway (REST API)
/// - AWS DynamoDB (NoSQL Database)
/// - AWS Cognito (Authentication)
///
/// Note: MongoDB/Beanie backend has been removed and replaced with DynamoDB
class AppConfig {
  // Use deployed AWS API Gateway URL for development/testing (us-east-1)
  static const String _defaultLocalUrl =
      'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
  static const String _defaultAndroidUrl =
      'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

  // Environment configuration
  static const String _awsApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // AWS Cognito configuration (Stage 1 Fix: hardcoded defaults for reliable authentication)
  static const String _cognitoUserPoolId = String.fromEnvironment(
    'COGNITO_USER_POOL_ID',
    defaultValue: 'us-east-1_bDqnKdrqo',
  );

  static const String _cognitoUserPoolClientId = String.fromEnvironment(
    'COGNITO_USER_POOL_CLIENT_ID',
    defaultValue: '6n752vrmqmbss6nmlg6be2nn9a',
  );

  static const String _cognitoRegion = String.fromEnvironment(
    'COGNITO_REGION',
    defaultValue: 'us-east-1',
  );

  static const String _cognitoIdentityPoolId = String.fromEnvironment(
    'COGNITO_IDENTITY_POOL_ID',
    defaultValue: '',
  );

  // Google Maps API Key for Places API
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue:
        'YOUR_GOOGLE_MAPS_API_KEY_HERE', // TODO: Replace with your actual key
  );

  // Mapbox Access Token
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue:
        'pk.eyJ1Ijoid2l6emdvIiwiYSI6ImNtYm50cGY0ajFpYW0ybXF0ZnY1ZG1uczMifQ.UPBxYXZeez7n4gAhmjVgSQ',
  );

  // Authentication mode: 'cognito' only (Stage 1 Fix)
  static const String _authMode = String.fromEnvironment(
    'AUTH_MODE',
    defaultValue: 'cognito',
  );

  /// Get the appropriate base URL based on environment and platform
  static String get baseUrl {
    // If AWS API URL is provided (production/staging), use it
    if (_awsApiUrl.isNotEmpty) {
      return _awsApiUrl;
    }

    // Otherwise, use local development URLs
    try {
      return Platform.isAndroid ? _defaultAndroidUrl : _defaultLocalUrl;
    } catch (e) {
      // Web platform doesn't support Platform.isAndroid, use default
      return _defaultLocalUrl;
    }
  }

  /// Get current environment
  static String get environment => _environment;

  /// Check if running in production
  static bool get isProduction => _environment == 'production';

  /// Check if running in development
  static bool get isDevelopment => _environment == 'development';

  /// Check if running in staging
  static bool get isStaging => _environment == 'staging';

  /// Authentication configuration
  static String get authMode => _authMode;
  static bool get useCognito => _authMode == 'cognito';
  static bool get useCustomAuth => _authMode == 'custom';

  /// Cognito configuration
  static String get cognitoUserPoolId => _cognitoUserPoolId;
  static String get cognitoUserPoolClientId => _cognitoUserPoolClientId;
  static String get cognitoRegion => _cognitoRegion;
  static String get cognitoIdentityPoolId => _cognitoIdentityPoolId;

  /// Check if Cognito is properly configured
  static bool get isCognitoConfigured =>
      _cognitoUserPoolId.isNotEmpty && _cognitoUserPoolClientId.isNotEmpty;

  /// Get WebSocket URL (convert http to ws)
  static String get webSocketUrl {
    final url = baseUrl;
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', 'wss://');
    } else if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'ws://');
    }
    return url;
  }

  /// API timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);

  /// Debug configuration
  static bool get enableLogging => isDevelopment || isStaging;

  /// Print current configuration (for debugging)
  static void printConfig() {
    if (enableLogging) {
      print('=== App Configuration ===');
      print('Environment: $environment');
      print('Base URL: $baseUrl');
      print('WebSocket URL: $webSocketUrl');
      try {
        print('Platform: ${Platform.operatingSystem}');
      } catch (e) {
        print('Platform: web');
      }
      print('Auth Mode: $authMode');
      if (useCognito) {
        print('Cognito User Pool ID: $cognitoUserPoolId');
        print('Cognito Client ID: $cognitoUserPoolClientId');
        print('Cognito Region: $cognitoRegion');
        print('Cognito Configured: $isCognitoConfigured');
      }
      if (googleMapsApiKey.contains('YOUR_GOOGLE_MAPS_API_KEY')) {
        print(
            '⚠️ Google Maps API Key is not set. Please add it to your environment variables or directly in app_config.dart');
      }
      if (mapboxAccessToken.isEmpty) {
        print('⚠️ Mapbox Access Token is not set.');
      }
      print('========================');
    }
  }
}
