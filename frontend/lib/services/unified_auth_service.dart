import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'cognito_auth_service.dart';
import 'auth_service.dart' as custom_auth;
import 'api_service.dart';

/// Unified authentication service that supports both Cognito and custom authentication
class UnifiedAuthService {
  static bool _isInitialized = false;

  /// Initialize the authentication service based on configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      await CognitoAuthService.configure(
        userPoolId: AppConfig.cognitoUserPoolId,
        userPoolClientId: AppConfig.cognitoUserPoolClientId,
        region: AppConfig.cognitoRegion,
        identityPoolId: AppConfig.cognitoIdentityPoolId.isNotEmpty
            ? AppConfig.cognitoIdentityPoolId
            : null,
      );
      print('Initialized with AWS Cognito authentication');
    } else {
      print('Initialized with custom authentication');
    }

    _isInitialized = true;
  }

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
    File? licenseFile,
    File? identityFile,
    File? healthCertificateFile,
    File? ownerPhotoFile,
  }) async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      // Convert userData to user attributes for Cognito
      final userAttributes = <String, String>{};
      if (userData != null) {
        userData.forEach((key, value) {
          if (value != null) {
            userAttributes[key] = value.toString();
          }
        });
      }

      return await CognitoAuthService.signUp(
        email: email,
        password: password,
        userAttributes: userAttributes,
      );
    } else {
      // Use custom authentication
      return await custom_auth.AuthService.register(
        userData ?? {'email': email, 'password': password},
        licenseFile,
        identityFile,
        healthCertificateFile,
        ownerPhotoFile,
      );
    }
  }

  /// Confirm user registration (for Cognito email verification)
  static Future<Map<String, dynamic>> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.confirmSignUp(
        email: email,
        confirmationCode: confirmationCode,
      );
    } else {
      // Custom auth doesn't require confirmation
      return {
        'success': true,
        'message': 'Registration confirmed',
      };
    }
  }

  /// Resend confirmation code (for Cognito)
  static Future<Map<String, dynamic>> resendConfirmationCode({
    required String email,
  }) async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.resendSignUpCode(email: email);
    } else {
      // Custom auth doesn't use confirmation codes
      return {
        'success': false,
        'message': 'Confirmation codes not supported in custom authentication',
      };
    }
  }

  /// Sign in user
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.signIn(
        email: email,
        password: password,
      );
    } else {
      return await custom_auth.AuthService.login(email, password);
    }
  }

  /// Sign out user
  static Future<Map<String, dynamic>> signOut() async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.signOut();
    } else {
      return await custom_auth.AuthService.logout();
    }
  }

  /// Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.getCurrentUser();
    } else {
      return await custom_auth.AuthService.getCurrentUser();
    }
  }

  /// Get user attributes/profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.getUserAttributes();
    } else {
      return await custom_auth.AuthService.getCurrentUser();
    }
  }

  /// Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.resetPassword(email: email);
    } else {
      return await custom_auth.AuthService.sendPasswordReset(email);
    }
  }

  /// Confirm password reset
  static Future<Map<String, dynamic>> confirmPasswordReset({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.confirmResetPassword(
        email: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } else {
      return await custom_auth.AuthService.resetPassword(
        confirmationCode,
        newPassword,
      );
    }
  }

  /// Check if user is signed in
  static Future<bool> isSignedIn() async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.isSignedIn();
    } else {
      final result = await custom_auth.AuthService.getCurrentUser();
      return result['success'] == true;
    }
  }

  /// Get access token for API requests
  static Future<String?> getAccessToken() async {
    await initialize();

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      return await CognitoAuthService.getAccessToken();
    } else {
      // For custom auth, get the actual token from SharedPreferences
      // This should match the same storage mechanism used by AuthService._getToken()
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    }
  }

  /// Register business data after successful email verification
  static Future<Map<String, dynamic>> registerBusinessData({
    required String cognitoUserId,
    required String email,
    required String businessName,
    required String businessType,
    required String ownerName,
    required String phoneNumber,
    required Map<String, dynamic> address,
  }) async {
    await initialize();

    // For both Cognito and custom auth, we need to call the backend API
    // to register the business data
    final apiService = _createApiServiceInstance();

    return await apiService.registerBusiness(
      cognitoUserId: cognitoUserId,
      email: email,
      businessName: businessName,
      businessType: businessType,
      ownerName: ownerName,
      phoneNumber: phoneNumber,
      address: address,
    );
  }

  /// Helper method to create ApiService instance
  static ApiService _createApiServiceInstance() {
    return ApiService();
  }

  /// Get current authentication mode
  static String get authMode => AppConfig.authMode;

  /// Check if using Cognito
  static bool get usingCognito =>
      AppConfig.useCognito && AppConfig.isCognitoConfigured;

  /// Check if using custom authentication
  static bool get usingCustomAuth => !usingCognito;
}
