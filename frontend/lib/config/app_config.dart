import 'dart:io';

/// Application configuration for different environments
class AppConfig {
  static const String _defaultLocalUrl = 'http://127.0.0.1:8000';
  static const String _defaultAndroidUrl = 'http://10.0.2.2:8000';

  // Environment configuration
  static const String _awsApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // AWS Cognito configuration
  static const String _cognitoUserPoolId = String.fromEnvironment(
    'COGNITO_USER_POOL_ID',
    defaultValue: '',
  );

  static const String _cognitoUserPoolClientId = String.fromEnvironment(
    'COGNITO_USER_POOL_CLIENT_ID',
    defaultValue: '',
  );

  static const String _cognitoRegion = String.fromEnvironment(
    'COGNITO_REGION',
    defaultValue: 'us-east-1',
  );

  static const String _cognitoIdentityPoolId = String.fromEnvironment(
    'COGNITO_IDENTITY_POOL_ID',
    defaultValue: '',
  );

  // Authentication mode: 'cognito' or 'custom'
  static const String _authMode = String.fromEnvironment(
    'AUTH_MODE',
    defaultValue: 'custom',
  );

  /// Get the appropriate base URL based on environment and platform
  static String get baseUrl {
    // If AWS API URL is provided (production/staging), use it
    if (_awsApiUrl.isNotEmpty) {
      return _awsApiUrl;
    }

    // Otherwise, use local development URLs
    return Platform.isAndroid ? _defaultAndroidUrl : _defaultLocalUrl;
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
      print('Platform: ${Platform.operatingSystem}');
      print('Auth Mode: $authMode');
      if (useCognito) {
        print('Cognito User Pool ID: $cognitoUserPoolId');
        print('Cognito Client ID: $cognitoUserPoolClientId');
        print('Cognito Region: $cognitoRegion');
        print('Cognito Configured: $isCognitoConfigured');
      }
      print('========================');
    }
  }
}
