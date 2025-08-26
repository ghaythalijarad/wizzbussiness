import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import './cognito_auth_service.dart';
import './api_service.dart';
import '../providers/session_provider.dart';
import '../providers/business_provider.dart';
import '../config/app_config.dart';
import './realtime_order_service.dart';

class AppAuthService {
  static bool _isInitialized = false;
  static ProviderContainer? _container;
  static CognitoAuthService? _cognitoService;

  static void setProviderContainer(ProviderContainer container) {
    _container = container;
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (AppConfig.isCognitoConfigured) {
      _cognitoService = CognitoAuthService();
      // Note: Amplify should be configured in main.dart
    }

    _isInitialized = true;
  }

  static Future<RegisterResult> registerSimple({
    required String email,
    required String password,
  }) async {
    await initialize();

    try {
      final apiService = ApiService();
      final response = await apiService.registerSimple(
        email: email,
        password: password,
      );
      return RegisterResult(
        success: response['success'] ?? false,
        message: response['message'] ?? 'Registration initiated successfully',
        userSub: response['user_sub'],
        codeDeliveryDetails: response['code_delivery_details'],
      );
    } catch (e) {
      return RegisterResult(
        success: false,
        message: e.toString(),
        userSub: null,
        codeDeliveryDetails: null,
      );
    }
  }

  static Future<ConfirmResult> confirmSignUp({
    required String username,
    required String code,
  }) async {
    await initialize();
    try {
      if (_cognitoService != null) {
        final result = await _cognitoService!.confirmSignUp(
          email: username,
          confirmationCode: code,
        );
        return ConfirmResult(
          success: result.isSignUpComplete,
          message: result.isSignUpComplete 
              ? 'Verification successful'
              : 'Verification failed',
        );
      } else {
        // Fallback to API service
        final apiService = ApiService();
        final result = await apiService.confirmRegistration(
          email: username,
          confirmationCode: code,
        );

        if (result['success'] == true) {
          return ConfirmResult(
            success: true,
            message: result['message'] ?? 'Registration confirmed successfully',
            user: result['user'],
          );
        } else {
          return ConfirmResult(
            success: false,
            message: result['message'] ?? 'Confirmation failed',
          );
        }
      }
    } catch (e) {
      return ConfirmResult(success: false, message: e.toString());
    }
  }

  static Future<void> resendSignUpCode({required String username}) async {
    await initialize();
    if (_cognitoService != null) {
      await _cognitoService!.resendSignUpCode(email: username);
    } else {
      final apiService = ApiService();
      await apiService.resendRegistrationCode(email: username);
    }
  }

  static Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    await initialize();
    try {
      // Use backend API for sign-in
      final apiService = ApiService();
      final apiResponse = await apiService.signIn(
        email: email,
        password: password,
      );

      if (apiResponse['success'] == true) {
        // Store tokens
        final authData = apiResponse['data'];
        if (authData != null) {
          await _storeAuthTokens({
            'accessToken': authData['AccessToken'],
            'idToken': authData['IdToken'],
            'refreshToken': authData['RefreshToken'],
          });
        }

        // Also establish Amplify session if available
        if (_cognitoService != null) {
          try {
            await _cognitoService!.signIn(
              email: email,
              password: password,
            );
          } catch (e) {
            print('⚠️ Amplify sign-in failed: $e');
          }
        }

        // Update session provider
        if (apiResponse['businesses'] != null &&
            apiResponse['businesses'].isNotEmpty) {
          final businessId = apiResponse['businesses'][0]['businessId'];
          _container?.read(sessionProvider.notifier).setSession(businessId);
        }

        return SignInResult(
          success: true,
          message: apiResponse['message'] ?? 'Sign in successful',
          user: apiResponse['user'],
          businesses:
              List<Map<String, dynamic>>.from(apiResponse['businesses'] ?? []),
          data: authData,
        );
      } else {
        return SignInResult(
          success: false,
          message: apiResponse['message'] ?? 'Sign-in failed',
          user: null,
          businesses: [],
          data: null,
        );
      }
    } catch (e) {
      return SignInResult(
        success: false,
        message: e.toString(),
        user: null,
        businesses: [],
        data: null,
      );
    }
  }

  static Future<void> signOut() async {
    try {
      // Disconnect from real-time service
      if (_container != null) {
        _container!.read(realtimeOrderServiceProvider).disconnect();
      }

      await _clearStoredTokens();
      _container?.read(sessionProvider.notifier).clearSession();
      _container?.invalidate(businessProvider);
      
      if (_cognitoService != null) {
        await _cognitoService!.signOut();
      }
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    await initialize();

    // Check stored tokens from backend authentication first
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken != null && accessToken.isNotEmpty) {
        final apiService = ApiService();
        
        try {
          final businessList = await apiService.getUserBusinesses();

          if (businessList.isNotEmpty) {
            final business = businessList.first;

            // Update session provider
            final businessId = business['businessId'];
            if (businessId != null) {
              _container?.read(sessionProvider.notifier).setSession(businessId);
            }

            return {
              'success': true,
              'email': business['email'],
              'userId': business['ownerId'] ?? business['cognitoUserId'],
              'sub': business['cognitoUserId'],
              'email_verified': true,
            };
          }
        } catch (apiError) {
          if (apiError.toString().contains('401') || 
              apiError.toString().contains('Invalid or expired access token')) {
            await _clearStoredTokens();
            _container?.read(sessionProvider.notifier).clearSession();
          }
        }
      }
    } catch (e) {
      print('⚠️ Error getting user from backend: $e');
    }

    // Fallback to Cognito
    if (_cognitoService != null) {
      try {
        final result = await _cognitoService!.getCurrentUser();
        if (result != null) {
          return {
            'email': result.username,
            'userId': result.userId,
            'sub': result.userId,
            'email_verified': true,
          };
        }
      } catch (e) {
        print('⚠️ Cognito getCurrentUser error: $e');
      }
    }

    return null;
  }

  static Future<RegisterResult> registerWithBusiness({
    required String email,
    required String password,
    required Map<String, dynamic> businessData,
  }) async {
    await initialize();

    try {
      final apiService = ApiService();
      final response = await apiService.registerWithBusiness(
        email: email,
        password: password,
        businessData: businessData,
      );
      return RegisterResult(
        success: true,
        message: response['message'] ?? 'Registration initiated successfully.',
        userSub: response['user_sub'],
        codeDeliveryDetails: response['code_delivery_details'],
        businessId: response['business_id'],
      );
    } catch (e) {
      return RegisterResult(
        success: false,
        message: e.toString(),
        userSub: null,
        codeDeliveryDetails: null,
        businessId: null,
      );
    }
  }

  static Future<String?> getAccessToken() async {
    await initialize();
    
    // First try Cognito if configured
    if (_cognitoService != null) {
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session is CognitoAuthSession) {
          final tokens = session.userPoolTokensResult.value;
          final freshToken = tokens.accessToken.raw;

          // Update SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', freshToken);

          return freshToken;
        }
      } catch (_) {
        // fallback to stored
      }
    }
    
    // Fallback to stored token
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<bool> isSignedIn() async {
    await initialize();

    // Check stored tokens first
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken != null && accessToken.isNotEmpty) {
        return true;
      }
    } catch (e) {
      print('⚠️ Error checking stored tokens: $e');
    }

    // Fallback to Cognito
    if (_cognitoService != null) {
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        return session.isSignedIn;
      } catch (e) {
        print('⚠️ Cognito session check failed: $e');
      }
    }

    return false;
  }

  static Future<void> _storeAuthTokens(Map<String, dynamic> authResult) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = authResult['accessToken'] as String?;
      final idToken = authResult['idToken'] as String?;
      final refreshToken = authResult['refreshToken'] as String?;

      if (accessToken != null && accessToken.isNotEmpty) {
        await prefs.setString('access_token', accessToken);
      }

      if (idToken != null && idToken.isNotEmpty) {
        await prefs.setString('id_token', idToken);
      }

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString('refresh_token', refreshToken);
      }
    } catch (e) {
      print('❌ Error storing auth tokens: $e');
    }
  }

  static Future<void> _clearStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('id_token');
      await prefs.remove('refresh_token');
      _container?.read(sessionProvider.notifier).clearSession();
    } catch (e) {
      // Handle error silently
    }
  }

  // Add debug method that doesn't conflict with undefined method
  static Map<String, dynamic> debugAuthState() {
    return {
      'isInitialized': _isInitialized,
      'hasCognitoService': _cognitoService != null,
      'hasContainer': _container != null,
    };
  }
}

// Result classes
class RegisterResult {
  final bool success;
  final String message;
  final String? userSub;
  final Map<String, dynamic>? codeDeliveryDetails;
  final String? businessId;

  RegisterResult({
    required this.success,
    required this.message,
    this.userSub,
    this.codeDeliveryDetails,
    this.businessId,
  });
}

class ConfirmResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? business;
  final Map<String, dynamic>? user;

  ConfirmResult({
    required this.success,
    this.message,
    this.business,
    this.user,
  });
}

class SignInResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>> businesses;
  final Map<String, dynamic>? data;

  SignInResult({
    required this.success,
    required this.message,
    this.user,
    required this.businesses,
    this.data,
  });
}
