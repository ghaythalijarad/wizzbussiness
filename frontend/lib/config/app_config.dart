class AppConfig {
  // Environment variables from dart-define
  static const String environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const String apiUrl = String.fromEnvironment('API_URL',
      defaultValue:
          'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev');
  static const String authMode =
      String.fromEnvironment('AUTH_MODE', defaultValue: 'cognito');
  static const String cognitoUserPoolId = String.fromEnvironment(
      'COGNITO_USER_POOL_ID',
      defaultValue: 'us-east-1_PHPkG78b5');
  static const String appClientId = String.fromEnvironment('APP_CLIENT_ID',
      defaultValue: '1tl9g7nk2k2chtj5fg960fgdth');
  static const String cognitoRegion =
      String.fromEnvironment('COGNITO_REGION', defaultValue: 'us-east-1');
  static const String cognitoIdentityPoolId =
      String.fromEnvironment('COGNITO_IDENTITY_POOL_ID', defaultValue: '');
  static const String featureSet =
      String.fromEnvironment('FEATURE_SET', defaultValue: 'enhanced');

  // Backward compatibility - some services use baseUrl
  static String get baseUrl => apiUrl;
  
  // WebSocket URL derived from API URL
  static String get webSocketUrl {
    // Convert HTTPS REST API URL to WSS WebSocket URL
    return apiUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('/dev', '/dev/websocket');
  }
  
  // Development flags
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  
  // Authentication configuration flags
  static bool get isCognitoConfigured =>
      cognitoUserPoolId.isNotEmpty && appClientId.isNotEmpty;
  
  // Feature flags
  static bool get isEnhancedMode => featureSet == 'enhanced';
}
