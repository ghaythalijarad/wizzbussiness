import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import './cognito_auth_service.dart';
import './api_service.dart';
import './session_manager.dart';
import '../providers/session_provider.dart';
import '../providers/business_provider.dart';
import '../config/app_config.dart';
import './realtime_order_service.dart';
import '../utils/token_manager.dart';

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

        // Update session provider with business data
        if (apiResponse['businesses'] != null &&
            apiResponse['businesses'].isNotEmpty) {
          final businessData = Map<String, dynamic>.from(apiResponse['businesses'][0]);
          final businessId = businessData['businessId'];
          final userId =
              apiResponse['user']?['userId'] ?? apiResponse['user']?['sub'];
          
          // Store the business data in session so the business provider can access it
          _container?.read(sessionProvider.notifier).setSessionWithBusinessData(businessId, businessData);
          
          // Add lightweight login tracking for business user
          await _trackBusinessLogin(businessId, userId, email);
        }

        return SignInResult(
          success: true,
          message: apiResponse['message'] ?? 'Sign in successful',
          user: apiResponse['user'],
          businesses:
              List<Map<String, dynamic>>.from(apiResponse['businesses'] ?? []),
          data: authData,
          accountStatus: apiResponse['accountStatus'],
        );
      } else {
        return SignInResult(
          success: false,
          message: apiResponse['message'] ?? 'Sign-in failed',
          user: null,
          businesses: [],
          data: null,
          accountStatus: apiResponse['accountStatus'],
        );
      }
    } catch (e) {
      return SignInResult(
        success: false,
        message: e.toString(),
        user: null,
        businesses: [],
        data: null,
        accountStatus: null,
      );
    }
  }

  /// Track business user login in WebSocket connections table (lightweight)
  static Future<void> _trackBusinessLogin(
      String businessId, String? userId, String email) async {
    try {
      print('📋 Tracking business user login');
      print('   Business ID: $businessId');
      print('   User ID: $userId');
      print('   Email: $email');

      // Create a simple login tracking entry in the WebSocket connections table
      final apiService = ApiService();
      await apiService.trackBusinessLogin(
        businessId: businessId,
        userId: userId ?? email,
        email: email,
      );

      print('✅ Business login tracked successfully');
    } catch (e) {
      print('⚠️ Error tracking business login: $e');
      // Don't fail login if tracking fails
    }
  }

  static Future<void> signOut() async {
    try {
      // Get current session info before clearing
      String? businessId;
      String? userId;
      
      if (_container != null) {
        final session = _container!.read(sessionProvider);
        businessId = session.businessId;

        // Get user ID from current user
        final currentUser = await getCurrentUser();
        userId = currentUser?['userId'] ?? currentUser?['sub'];
      }

      // Remove login tracking for this business user
      if (businessId != null) {
        await _trackBusinessLogout(businessId, userId);
      }

      // Disconnect from real-time service
      if (_container != null) {
        _container!.read(realtimeOrderServiceProvider).disconnect();
      }

      // Clear stored tokens and Riverpod providers
      await _clearStoredTokens();
      _container?.read(sessionProvider.notifier).clearSession();
      _container?.invalidate(businessProvider);
      
      // Clear SessionManager singleton state to prevent "user already signed in" error
      await SessionManager.clearInstance();

      // Sign out from Cognito/Amplify
      if (_cognitoService != null) {
        await _cognitoService!.signOut();
      }

      print('✅ Sign out completed with WebSocket cleanup');
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  /// Track business user logout by removing login tracking entries
  static Future<void> _trackBusinessLogout(
      String businessId, String? userId) async {
    try {
      print('📋 Tracking business user logout');
      print('   Business ID: $businessId');
      print('   User ID: $userId');
      
      // Remove login tracking entries for this business/user
      final apiService = ApiService();
      await apiService.trackBusinessLogout(
        businessId: businessId,
        userId: userId ?? '',
      );
      
      print('✅ Business logout tracked successfully');
    } catch (e) {
      print('⚠️ Error tracking business logout: $e');
      // Don't fail logout if tracking fails
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
    print('🔄 AppAuthService.registerWithBusiness called');
    print('📧 Email: $email');
    print('🏢 Business data keys: ${businessData.keys.toList()}');
    
    await initialize();

    try {
      print('🌐 Making API call to registerWithBusiness...');
      final apiService = ApiService();
      final response = await apiService.registerWithBusiness(
        email: email,
        password: password,
        businessData: businessData,
      );
      print('✅ API response received: $response');
      
      return RegisterResult(
        success: true,
        message: response['message'] ?? 'Registration initiated successfully.',
        userSub: response['user_sub'],
        codeDeliveryDetails: response['code_delivery_details'],
        businessId: response['business_id'],
      );
    } catch (e) {
      print('❌ AppAuthService.registerWithBusiness error: $e');
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

          // Update SharedPreferences using TokenManager
          await TokenManager.setAccessToken(freshToken);

          return freshToken;
        }
      } catch (_) {
        // fallback to stored
      }
    }
    
    // Fallback to stored token using TokenManager
    return await TokenManager.getAccessToken();
  }

  static Future<bool> isSignedIn() async {
    await initialize();

    // Check stored tokens first using TokenManager
    try {
      final accessToken = await TokenManager.getAccessToken();

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
        await TokenManager.setAccessToken(accessToken);
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
      await TokenManager.clearAccessToken();
      final prefs = await SharedPreferences.getInstance();
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

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Use API service for password change
      final apiService = ApiService();
      final response = await apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return response['success'] ?? false;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  static Future<EmailCheckResult> checkEmailExists(
      {required String email}) async {
    await initialize();

    try {
      final apiService = ApiService();
      final response = await apiService.checkEmailExists(email: email);
      return EmailCheckResult(
        exists: response['exists'] ?? false,
        message: response['message'] ?? 'Email check completed',
      );
    } catch (e) {
      print('Error checking email existence: $e');
      return EmailCheckResult(
        exists: false,
        message: 'Error checking email: $e',
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
      final response = await apiService.confirmRegistration(
        email: email,
        confirmationCode: confirmationCode,
      );

      return ConfirmResult(
        success: response['success'] ?? false,
        message: response['message'],
        business: response['business'],
        user: response['user'],
      );
    } catch (e) {
      print('Error confirming registration: $e');
      return ConfirmResult(
        success: false,
        message: 'Registration confirmation failed: $e',
      );
    }
  }

  static Future<bool> resendRegistrationCode({required String email}) async {
    await initialize();

    try {
      final apiService = ApiService();
      final response = await apiService.resendRegistrationCode(email: email);
      return response['success'] ?? false;
    } catch (e) {
      print('Error resending registration code: $e');
      return false;
    }
  }

  /// Check user status before password reset
  static Future<UserStatusResult> checkUserStatus({
    required String email,
  }) async {
    await initialize();

    try {
      final apiService = ApiService();
      // Try to get user info to see if account exists
      final response = await apiService.getUserByEmail(email: email);

      if (response['success'] == true && response['user'] != null) {
        final user = response['user'];
        final userStatus = user['status']?.toLowerCase();

        if (userStatus == 'unconfirmed' ||
            userStatus == 'pending_confirmation') {
          return UserStatusResult(
            exists: true,
            isConfirmed: false,
            status: 'unconfirmed',
            message:
                'Your account exists but is not confirmed. Please verify your email first.',
          );
        } else if (userStatus == 'confirmed' || userStatus == 'active') {
          return UserStatusResult(
            exists: true,
            isConfirmed: true,
            status: 'confirmed',
            message: 'Account confirmed and ready for password reset.',
          );
        } else {
          return UserStatusResult(
            exists: true,
            isConfirmed: false,
            status: userStatus ?? 'unknown',
            message: 'Account found but has an unknown status: $userStatus',
          );
        }
      } else {
        // User doesn't exist based on API response
        return UserStatusResult(
          exists: false,
          isConfirmed: false,
          status: 'not_found',
          message: 'No account found with this email address.',
        );
      }
    } catch (e) {
      print('Error checking user status: $e');

      // Return error status instead of falling back to email-sending methods
      return UserStatusResult(
        exists: false,
        isConfirmed: false,
        status: 'error',
        message: 'Unable to check account status. Please try again later.',
      );
    }
  }

  /// Initiate forgot password flow
  static Future<ForgotPasswordResult> forgotPassword({
    required String email,
  }) async {
    await initialize();

    try {
      if (_cognitoService != null) {
        final response =
            await CognitoAuthService.forgotPassword(username: email);
        return ForgotPasswordResult(
          success: response['success'] ?? false,
          message: response['message'] ?? '',
          codeDeliveryDetails: response['codeDeliveryDetails'],
        );
      } else {
        // If no Cognito service, return error
        return ForgotPasswordResult(
          success: false,
          message: 'Password reset service not available',
        );
      }
    } catch (e) {
      print('Error initiating password reset: $e');
      return ForgotPasswordResult(
        success: false,
        message: 'Failed to initiate password reset: $e',
      );
    }
  }

  /// Confirm forgot password with verification code
  static Future<ConfirmForgotPasswordResult> confirmForgotPassword({
    required String email,
    required String confirmationCode,
    required String newPassword,
  }) async {
    await initialize();

    try {
      if (_cognitoService != null) {
        final response = await CognitoAuthService.confirmForgotPassword(
          username: email,
          confirmationCode: confirmationCode,
          newPassword: newPassword,
        );
        return ConfirmForgotPasswordResult(
          success: response['success'] ?? false,
          message: response['message'] ?? '',
        );
      } else {
        // If no Cognito service, return error
        return ConfirmForgotPasswordResult(
          success: false,
          message: 'Password reset service not available',
        );
      }
    } catch (e) {
      print('Error confirming password reset: $e');
      return ConfirmForgotPasswordResult(
        success: false,
        message: 'Failed to confirm password reset: $e',
      );
    }
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
  final String? accountStatus;

  SignInResult({
    required this.success,
    required this.message,
    this.user,
    required this.businesses,
    this.data,
    this.accountStatus,
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

class UserStatusResult {
  final bool exists;
  final bool isConfirmed;
  final String status;
  final String message;

  UserStatusResult({
    required this.exists,
    required this.isConfirmed,
    required this.status,
    required this.message,
  });
}
