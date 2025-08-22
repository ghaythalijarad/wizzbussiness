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
  // Environment configuration - prioritize dart-define values
  static const String _awsApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  // Feature set configuration for staging deployments
  static const String _featureSet = String.fromEnvironment(
    'FEATURE_SET',
    defaultValue: 'core',
  );

  // Fallback URLs (only used if API_URL not provided via dart-define)
  static const String _defaultLocalUrl =
      'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev';
  static const String _defaultAndroidUrl =
      'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev';
  
  // Staging URLs
  static const String _defaultStagingUrl =
      'https://staging-zz9cszv6a8.execute-api.us-east-1.amazonaws.com/staging';

  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const String _authMode = String.fromEnvironment(
    'AUTH_MODE',
    defaultValue: 'cognito',
  );

  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY',
  );

  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  // Optional override for WebSocket endpoint via build-time define
  static const String _webSocketUrlOverride = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: '',
  );

  // AWS Cognito configuration (MIGRATED to new account - merchants-pool)
  static const String _cognitoUserPoolId = String.fromEnvironment(
    'COGNITO_USER_POOL_ID',
    defaultValue: 'us-east-1_PHPkG78b5', // NEW target pool id
  );

  // New unified app client id (required)
  static const String _appClientId = String.fromEnvironment(
    'APP_CLIENT_ID',
    defaultValue: '1tl9g7nk2k2chtj5fg960fgdth', // NEW target client id
  );

  static const String _cognitoRegion = String.fromEnvironment(
    'COGNITO_REGION',
    defaultValue: 'us-east-1',
  );

  static const String _cognitoIdentityPoolId = String.fromEnvironment(
    'COGNITO_IDENTITY_POOL_ID',
    defaultValue: '',
  );

  // New getter for AWS region for API Gateway
  static String get awsRegion => _cognitoRegion;

  // Base URL for API requests
  static String get baseUrl {
    String url;
    if (_awsApiUrl.isNotEmpty) {
      url = _awsApiUrl;
    } else {
      // Environment-specific defaults
      switch (_environment) {
        case 'staging':
          url = _defaultStagingUrl;
          break;
        case 'production':
          url = 'https://api.wizzbusiness.com/prod'; // Production URL
          break;
        default:
          url = Platform.isAndroid ? _defaultAndroidUrl : _defaultLocalUrl;
      }
    }
    // Remove trailing slash to prevent double slashes in URL construction
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // WebSocket URL - Derived from API base when not explicitly overridden
  static String get webSocketUrl {
    // 1. Explicit override always wins
    if (_webSocketUrlOverride.isNotEmpty) {
      return _webSocketUrlOverride.endsWith('/')
          ? _webSocketUrlOverride.substring(0, _webSocketUrlOverride.length - 1)
          : _webSocketUrlOverride;
    }

    // 2. Derive from baseUrl (convert https->wss, keep host + stage path)
    try {
      final rest =
          Uri.parse(baseUrl); // baseUrl already trimmed of trailing slash
      if (rest.host.isNotEmpty) {
        final wsUri = Uri(
          scheme: 'wss',
          host: rest.host,
          port: rest.hasPort ? rest.port : null,
          path: rest.path, // includes stage (e.g. /Prod or /dev)
        );
        final derived = wsUri.toString();
        // Warn if previously hardcoded value would have differed
        if (enableLogging && derived.contains('execute-api.') == true) {
          // If someone accidentally left a mismatch, log it once
          if (rest.host != '3sfzxlb2v8.execute-api.us-east-1.amazonaws.com') {
            // Only log when differing from old hardcoded host to aid migration
            // ignore: avoid_print
            print('🔄 Derived WebSocket URL: ' + derived);
          }
        }
        return derived;
      }
    } catch (e) {
      if (enableLogging) {
        // ignore: avoid_print
        print('⚠️ Failed deriving WebSocket URL from baseUrl: $e');
      }
    }

    // 3. Fallback (should rarely be used) – keep previous value but note mismatch
    const fallback =
        'wss://s8nf89antk.execute-api.us-east-1.amazonaws.com/Prod';
    if (enableLogging) {
      // ignore: avoid_print
      print('⚠️ Using fallback WebSocket URL: $fallback');
    }
    return fallback;
  }

  // Environment type
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

  /// Cognito configuration - Environment-aware
  static String get cognitoUserPoolId {
    switch (_environment) {
      case 'staging':
        return 'us-east-1_staging_pool'; // Will be created for staging
      case 'production':  
        return 'us-east-1_prod_pool'; // Will be created for production
      default:
        return _cognitoUserPoolId; // Use dev pool
    }
  }
  
  /// Preferred getter for the Cognito app client id (environment-aware)
  static String get appClientId {
    switch (_environment) {
      case 'staging':
        return 'staging_client_id'; // Will be created for staging
      case 'production':
        return 'prod_client_id'; // Will be created for production
      default:
        return _appClientId; // Use dev client
    }
  }
  
  static String get cognitoRegion => _cognitoRegion;
  static String get cognitoIdentityPoolId => _cognitoIdentityPoolId;
  static String get googleMapsApiKey => _googleMapsApiKey;

  /// Feature set configuration
  static String get featureSet => _featureSet;

  // =============================================================================
  // FEATURE FLAGS - Control what features are enabled per environment
  // =============================================================================
  
  /// Check if a specific feature is enabled in the current feature set
  static bool _isFeatureEnabled(String feature) {
    final enabledFeatures = _featureSet.split(',').map((f) => f.trim()).toList();
    
    // Core features are always enabled
    const coreFeatures = ['auth', 'orders', 'dashboard', 'search'];
    if (coreFeatures.contains(feature)) {
      return true;
    }
    
    // Enhanced features
    const enhancedFeatures = ['realtime', 'notifications', 'toggle'];
    if (enhancedFeatures.contains(feature)) {
      return enabledFeatures.contains('enhanced') || 
             enabledFeatures.contains('beta') ||
             enabledFeatures.contains(feature);
    }
    
    // Beta features
    const betaFeatures = ['firebase', 'floating', 'centralized'];
    if (betaFeatures.contains(feature)) {
      return enabledFeatures.contains('beta') || enabledFeatures.contains(feature);
    }
    
    // Default: check if explicitly enabled
    return enabledFeatures.contains(feature);
  }
  
  /// Enable floating notifications (beta feature)
  static bool get enableFloatingNotifications {
    return !isProduction && _isFeatureEnabled('floating');
  }
  
  /// Enable Firebase push notifications (testing migration)
  static bool get enableFirebasePush {
    return isStaging && _isFeatureEnabled('firebase');
  }
  
  /// Enable centralized platform features
  static bool get enableCentralizedPlatform {
    return !isProduction && _isFeatureEnabled('centralized');
  }
  
  /// Enable real-time notifications via WebSocket
  static bool get enableRealTimeNotifications {
    return _isFeatureEnabled('realtime');
  }
  
  /// Enable enhanced search functionality (always enabled - we fixed this!)
  static bool get enableSearchFunctionality {
    return true; // Core feature - always enabled
  }
  
  /// Enable merchant approval workflow
  static bool get enableMerchantApproval {
    return true; // Core feature - always enabled
  }
  
  /// Enable online/offline toggle
  static bool get enableOnlineOfflineToggle {
    return _isFeatureEnabled('toggle');
  }
  
  /// Enable AI-powered features (future)
  static bool get enableAIFeatures {
    return false; // Not ready in any environment yet
  }

  /// Check if Cognito is properly configured
  static bool get isCognitoConfigured =>
      cognitoUserPoolId.isNotEmpty && appClientId.isNotEmpty;

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
      print('Feature Set: $featureSet');
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
        print('App Client ID: $appClientId');
        print('Cognito Region: $cognitoRegion');
        print('Cognito Configured: $isCognitoConfigured');
      }
      print('--- Feature Flags ---');
      print('Floating Notifications: $enableFloatingNotifications');
      print('Firebase Push: $enableFirebasePush');
      print('Centralized Platform: $enableCentralizedPlatform');
      print('Real-time Notifications: $enableRealTimeNotifications');
      print('Search Functionality: $enableSearchFunctionality');
      print('Merchant Approval: $enableMerchantApproval');
      print('Online/Offline Toggle: $enableOnlineOfflineToggle');
      print('AI Features: $enableAIFeatures');
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
