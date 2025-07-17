import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'cognito_auth_service.dart';
import 'api_service.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class AppAuthService {
  static bool _isInitialized = false;

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
          await Amplify.Auth.signOut();
          print('✅ Previous user signed out successfully');
          // Add a small delay to ensure cleanup is complete
          await Future.delayed(Duration(milliseconds: 500));
        }
      } catch (e) {
        print('⚠️ Error checking/clearing previous session: $e');
        // Continue with sign-in attempt
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

        // Configure Amplify with the tokens to establish session
        try {
          // Use CognitoAuthService to establish the Amplify session
          final cognitoResult = await CognitoAuthService.signIn(
            username: email,
            password: password,
          );
          print('🔄 Amplify session established: ${cognitoResult['success']}');
        } catch (e) {
          print('⚠️ Warning: Could not establish Amplify session: $e');
          // Continue anyway as we have the backend data
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
      await CognitoAuthService.signOut();
      await _clearStoredTokens();
    } catch (e) {
      await _clearStoredTokens();
    }
  }

  // Authentication state and data retrieval using legacy AuthService
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    await initialize();
    try {
      final result = await CognitoAuthService.getCurrentUser();
      // Return user attributes map if available
      if (result != null) {
        return result;
      }
      return null;
    } catch (e) {
      print('❌ AppAuthService.getCurrentUser error: $e');
      return null;
    }
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
        // Store authentication tokens
        await _storeAuthTokens(result);

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

  /// Check if user is signed in, using Cognito if configured, otherwise falling back to shared preferences or legacy token
  static Future<bool> isSignedIn() async {
    await initialize();
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return (session as CognitoAuthSession).isSignedIn;
    } catch (_) {
      return false;
    }
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
