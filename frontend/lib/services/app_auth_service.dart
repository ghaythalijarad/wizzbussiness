import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import './cognito_auth_service.dart';
import '../providers/session_provider.dart';
import '../providers/business_provider.dart';
import '../config/app_config.dart';
import './api_service.dart';
import './realtime_order_service.dart';

class AppAuthService {
  static bool _isInitialized = false;
  static ProviderContainer? _container;

  static void setProviderContainer(ProviderContainer container) {
    _container = container;
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (AppConfig.isCognitoConfigured) {
      await CognitoAuthService.configure(
        userPoolId: AppConfig.cognitoUserPoolId,
        userPoolClientId: AppConfig.cognitoUserPoolClientId,
        region: AppConfig.cognitoRegion,
        identityPoolId: AppConfig.cognitoIdentityPoolId.isNotEmpty
            ? AppConfig.cognitoIdentityPoolId
            : null,
      );
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
        success: true,
        message: response['message'] ?? 'Registration initiated successfully.',
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
      final result = await CognitoAuthService.confirmSignUp(
        username: username,
        confirmationCode: code,
      );
      return ConfirmResult(
        success: result['success'] == true,
        message: result['message'] ??
            (result['success'] == true
                ? 'Verification successful'
                : 'Verification failed'),
      );
    } catch (e) {
      return ConfirmResult(success: false, message: e.toString());
    }
  }

  static Future<ConfirmResult> createBusiness({
    required Map<String, dynamic> businessData,
  }) async {
    await initialize();
    try {
      final apiService = ApiService();
      final businessResp = await apiService.registerBusiness(businessData);
      return ConfirmResult(
        success: businessResp['success'] == true,
        message: businessResp['message'] ??
            (businessResp['success'] == true
                ? 'Business created successfully'
                : 'Business creation failed'),
        business: businessResp['business'],
      );
    } catch (e) {
      return ConfirmResult(
        success: false,
        message: e.toString(),
        business: null,
      );
    }
  }

  static Future<void> resendSignUpCode({required String username}) async {
    await initialize();
    await CognitoAuthService.resendSignUpCode(email: username);
  }

  static Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    await initialize();
    try {
      // Check if a user is already signed in and sign them out first
      try {
        final existingSession = await Amplify.Auth.fetchAuthSession();
        if ((existingSession as CognitoAuthSession).isSignedIn) {
          print('🔄 User already signed in, signing out first...');
          await signOut(); // Use our own signOut to ensure local tokens are cleared
          print('✅ Previous user signed out successfully');
          // Add a small delay to ensure cleanup is complete
          await Future.delayed(Duration(milliseconds: 500));
        }
      } catch (e) {
        print('⚠️ Error checking/clearing previous session: $e');
        // If there's an error, it might be because the session is broken.
        // Let's try to clear our stored tokens just in case.
        await _clearStoredTokens();
      }

      // Use our backend API for sign-in which returns both auth tokens and business data
      final apiResponse = await ApiService().signIn(
        email: email,
        password: password,
      );

      if (apiResponse['success'] == true) {
        print('📡 Backend sign-in successful');

        // Extract tokens from the response
        final authData = apiResponse['data'];
        if (authData != null) {
          await _storeAuthTokens({
            'accessToken': authData['AccessToken'],
            'idToken': authData['IdToken'],
            'refreshToken': authData['RefreshToken'],
          });
        }

        // Also establish Amplify session for password change
        try {
          await CognitoAuthService.signIn(
            username: email,
            password: password,
          );
          print('✅ Amplify sign-in successful');
        } catch (e) {
          print('⚠️ Amplify sign-in failed: $e');
        }

        // Update session provider
        if (apiResponse['businesses'] != null &&
            apiResponse['businesses'].isNotEmpty) {
          final businessId = apiResponse['businesses'][0]['businessId'];
          _container?.read(sessionProvider.notifier).setSession(businessId);
        }

        // Return the user and business data from our backend
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
      // Disconnect from real-time service to prevent lingering connections
      if (_container != null) {
        print('🔌 Disconnecting real-time service on sign-out...');
        _container!.read(realtimeOrderServiceProvider).disconnect();
      }

      await _clearStoredTokens();
      _container?.read(sessionProvider.notifier).clearSession();
      _container?.invalidate(businessProvider);
      await CognitoAuthService.signOut();
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // Authentication state and data retrieval using legacy AuthService
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    await initialize();

    print('🔍 AppAuthService.getCurrentUser() - Starting validation');

    // First try to get user from Cognito if configured
    if (AppConfig.isCognitoConfigured) {
      print('🔍 Trying Cognito getCurrentUser...');
      try {
        final result = await CognitoAuthService.getCurrentUser();
        if (result != null) {
          print('✅ Got user from Cognito: ${result['email']}');
          return result;
        }
        print('⚠️ Cognito getCurrentUser returned null');
      } catch (e) {
        print('⚠️ Cognito getCurrentUser error: $e');
      }
    }

    // Fallback to checking stored user data from backend authentication
    print('🔍 Trying stored token validation...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      print(
          '🔍 Access token exists: ${accessToken != null && accessToken.isNotEmpty}');

      if (accessToken != null && accessToken.isNotEmpty) {
        print('🔍 Access token length: ${accessToken.length}');
        print('🔍 Access token preview: ${accessToken.substring(0, 50)}...');

        // If we have an access token, try to get user info
        final apiService = ApiService();
        print('🔍 Calling getUserBusinesses...');
        
        try {
          final businessList = await apiService.getUserBusinesses();
          print('🔍 Got ${businessList.length} businesses');

          if (businessList.isNotEmpty) {
            final business = businessList.first;
            print('🔍 Business data: ${business.keys.toList()}');

            // Update session provider
            final businessId = business['businessId'];
            if (businessId != null) {
              _container?.read(sessionProvider.notifier).setSession(businessId);
            }

            final userResult = {
              'success': true,
              'email': business['email'],
              'userId': business['ownerId'] ?? business['cognitoUserId'],
              'sub': business['cognitoUserId'],
              'email_verified': true,
            };

            print('✅ Returning user data: $userResult');
            return userResult;
          } else {
            print('❌ No businesses found for user');
          }
        } catch (apiError) {
          print('⚠️ API call failed, but token exists: $apiError');
          
          // If API call fails but we have a valid token, it might be a temporary issue
          // Don't clear the session immediately, just return a basic user object
          if (apiError.toString().contains('401') || 
              apiError.toString().contains('Invalid or expired access token')) {
            print('🧹 Token is actually expired, clearing session');
            await _clearStoredTokens();
            _container?.read(sessionProvider.notifier).clearSession();
          } else {
            print('🔄 Assuming temporary API issue, keeping session active');
            // Return a minimal user object to keep the session active
            return {
              'success': true,
              'email': 'unknown@temp.com',
              'userId': 'temp-user-id',
              'sub': 'temp-sub',
              'email_verified': true,
              'temporary': true, // Flag to indicate this is a fallback
            };
          }
        }
      } else {
        print('❌ No access token found');
      }
    } catch (e) {
      print('⚠️ Error getting user from backend: $e');
      // For general errors, don't clear the session immediately as it might be a temporary issue
    }

    print('❌ getCurrentUser returning null');
    return null;
  }

  static Future<void> _storeAuthTokens(Map<String, dynamic> authResult) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = authResult['accessToken'] as String?;
      final idToken = authResult['idToken'] as String?;
      final refreshToken = authResult['refreshToken'] as String?;

      print('🔒 AppAuthService: Storing auth tokens...');

      if (accessToken != null && accessToken.isNotEmpty) {
        await prefs.setString('access_token', accessToken);
        print('✅ AppAuthService: Access token stored');
      } else {
        print('⚠️ AppAuthService: No access token to store');
      }

      if (idToken != null && idToken.isNotEmpty) {
        await prefs.setString('id_token', idToken);
        print('✅ AppAuthService: ID token stored');
      }

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString('refresh_token', refreshToken);
        print('✅ AppAuthService: Refresh token stored');
      }
    } catch (e) {
      print('❌ AppAuthService: Error storing auth tokens: $e');
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

  static Future<ConfirmResult> confirmRegistration({
    required String email,
    required String confirmationCode,
  }) async {
    await initialize();
    try {
      final apiService = ApiService();
      final result = await apiService.confirmRegistration(
        email: email,
        confirmationCode: confirmationCode,
      );

      if (result['success'] == true) {
        // Check if the backend returned user and business data (new auto-login flow)
        if (result['verified'] == true &&
            result['user'] != null &&
            result['businesses'] != null) {
          // Update session provider
          if (result['businesses']?.isNotEmpty == true) {
            final businessId = result['businesses'][0]['businessId'];
            _container?.read(sessionProvider.notifier).setSession(businessId);
          }
          return ConfirmResult(
            success: true,
            message: result['message'] ?? 'Registration confirmed successfully',
            user: result['user'],
            business: result['businesses']?.isNotEmpty == true
                ? result['businesses'][0]
                : null,
          );
        } else {
          // Old flow - store authentication tokens if provided
          await _storeAuthTokens(result);
          // Try to get businessId and update session
          if (result['user'] != null) {
            try {
              final businesses = await ApiService().getUserBusinesses();
              if (businesses.isNotEmpty) {
                final businessId = businesses.first['businessId'];
                _container
                    ?.read(sessionProvider.notifier)
                    .setSession(businessId);
              }
            } catch (_) {}
          }
          return ConfirmResult(
            success: true,
            message: result['message'] ?? 'Registration confirmed successfully',
            user: result['user'],
          );
        }
      } else {
        return ConfirmResult(
          success: false,
          message: result['message'] ?? 'Confirmation failed',
        );
      }
    } catch (e) {
      return ConfirmResult(success: false, message: e.toString());
    }
  }

  static Future<void> resendRegistrationCode({required String email}) async {
    await initialize();
    try {
      final apiService = ApiService();
      await apiService.resendRegistrationCode(email: email);
    } catch (e) {
      throw e;
    }
  }

  static Future<EmailCheckResult> checkEmailExists({
    required String email,
  }) async {
    await initialize();

    try {
      final apiService = ApiService();
      final response = await apiService.checkEmailExists(email: email);
      return EmailCheckResult(
        exists: response['exists'] ?? false,
        message: response['message'] ?? 'Email check completed',
      );
    } catch (e) {
      return EmailCheckResult(
        exists: false,
        message: e.toString(),
      );
    }
  }

  /// Check if user is signed in, using backend tokens primarily
  static Future<bool> isSignedIn() async {
    await initialize();

    // Check stored tokens from backend authentication first (our primary auth method)
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken != null && accessToken.isNotEmpty) {
        print('✅ Found stored access token: ${accessToken.length} chars');
        
        // For backend authentication, we trust the stored token if it exists
        // The token validation happens in getCurrentUser() when needed
        return true;
      }
    } catch (e) {
      print('⚠️ Error checking stored tokens: $e');
    }

    // Fallback to Cognito session if configured and no backend token found
    if (AppConfig.isCognitoConfigured) {
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if ((session as CognitoAuthSession).isSignedIn) {
          print('✅ Cognito session is active');
          return true;
        }
      } catch (e) {
        print('⚠️ Cognito session check failed: $e');
      }
    }

    print('❌ No valid authentication found');
    return false;
  }

  /// Get current access token from Cognito or shared preferences (fallbacks: access_token, auth_token)
  static Future<String?> getAccessToken() async {
    await initialize();
    String? token;
    if (AppConfig.isCognitoConfigured) {
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session is CognitoAuthSession) {
          final tokens = session.userPoolTokensResult.value;
          final freshToken = tokens.accessToken.raw;

          // Update SharedPreferences with the fresh token for consistency
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', freshToken);

          return freshToken;
        }
      } catch (_) {
        // fallback to stored
      }
    }
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('access_token');
    return token;
  }

  /// Get current ID token from Cognito or shared preferences
  static Future<String?> getIdToken() async {
    await initialize();
    String? token;
    if (AppConfig.isCognitoConfigured) {
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session is CognitoAuthSession) {
          final tokens = session.userPoolTokensResult.value;
          final freshIdToken = tokens.idToken.raw;

          // Update SharedPreferences with the fresh token for consistency
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('id_token', freshIdToken);

          return freshIdToken;
        }
      } catch (_) {
        // fallback to stored
      }
    }
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('id_token');
    return token;
  }

  static Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await initialize();
    try {
      final result = await CognitoAuthService.changePassword(
        oldPassword: currentPassword,
        newPassword: newPassword,
      );
      return ChangePasswordResult(
        success: result['success'] == true,
        message: result['message'] ??
            (result['success'] == true
                ? 'Password changed successfully'
                : 'Password change failed'),
      );
    } catch (e) {
      return ChangePasswordResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  static Future<ForgotPasswordResult> forgotPassword({
    required String email,
  }) async {
    await initialize();
    try {
      final result = await CognitoAuthService.forgotPassword(username: email);
      return ForgotPasswordResult(
        success: result['success'] == true,
        message: result['message'] ?? 'Reset code sent successfully',
        codeDeliveryDetails: result['codeDeliveryDetails'],
      );
    } catch (e) {
      return ForgotPasswordResult(
        success: false,
        message: e.toString(),
        codeDeliveryDetails: null,
      );
    }
  }

  static Future<ConfirmForgotPasswordResult> confirmForgotPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    await initialize();
    try {
      final result = await CognitoAuthService.confirmForgotPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      return ConfirmForgotPasswordResult(
        success: result['success'] == true,
        message: result['message'] ?? 'Password reset successfully',
      );
    } catch (e) {
      return ConfirmForgotPasswordResult(
        success: false,
        message: e.toString(),
      );
    }
  }
}

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

class EmailCheckResult {
  final bool exists;
  final String message;

  EmailCheckResult({
    required this.exists,
    required this.message,
  });
}

class ChangePasswordResult {
  final bool success;
  final String message;

  ChangePasswordResult({
    required this.success,
    required this.message,
  });
}

class ForgotPasswordResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? codeDeliveryDetails;

  ForgotPasswordResult({
    required this.success,
    required this.message,
    this.codeDeliveryDetails,
  });
}

class ConfirmForgotPasswordResult {
  final bool success;
  final String message;

  ConfirmForgotPasswordResult({
    required this.success,
    required this.message,
  });
}
