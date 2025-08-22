import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/foundation.dart';

import './cognito_auth_service.dart';
import '../providers/session_provider.dart';
import '../providers/business_provider.dart';
import '../config/app_config.dart';
import './api_service.dart';
import './realtime_order_service.dart';
import '../utils/token_manager.dart';

class AppAuthService {
  static bool _isInitialized = false;
  static ProviderContainer? _container;

  static void setProviderContainer(ProviderContainer container) {
    _container = container;
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Only initialize Cognito if not on web and properly configured
    if (!kIsWeb && AppConfig.isCognitoConfigured) {
      try {
        await CognitoAuthService.configure(
          userPoolId: AppConfig.cognitoUserPoolId,
          userPoolClientId: AppConfig.appClientId,
          region: AppConfig.cognitoRegion,
          identityPoolId: AppConfig.cognitoIdentityPoolId.isNotEmpty
              ? AppConfig.cognitoIdentityPoolId
              : null,
        );
      } catch (e) {
        print(
            '⚠️ AppAuthService: Failed to configure Cognito, continuing with API-only auth: $e');
      }
    } else if (kIsWeb) {
      print(
          '🌐 AppAuthService: Running on web - using API-only authentication');
    }
    _isInitialized = true;
  }

  // ---------- Registration & Confirmation ----------
  static Future<RegisterResult> registerSimple({
    required String email,
    required String password,
  }) async {
    await initialize();
    try {
      final resp =
          await ApiService().registerSimple(email: email, password: password);
      return RegisterResult(
        success: true,
        message: resp['message'] ?? 'Registration initiated successfully.',
        userSub: resp['user_sub'],
        codeDeliveryDetails: resp['code_delivery_details'],
      );
    } catch (e) {
      return RegisterResult(success: false, message: e.toString());
    }
  }

  static Future<ConfirmResult> confirmSignUp({
    required String username,
    required String code,
  }) async {
    await initialize();
    try {
      final r = await CognitoAuthService.confirmSignUp(
        username: username,
        confirmationCode: code,
      );
      return ConfirmResult(
        success: r['success'] == true,
        message: r['message'] ??
            (r['success'] == true
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
      final r = await ApiService().registerBusiness(businessData);
      return ConfirmResult(
        success: r['success'] == true,
        message: r['message'] ??
            (r['success'] == true
                ? 'Business created successfully'
                : 'Business creation failed'),
        business: r['business'],
      );
    } catch (e) {
      return ConfirmResult(success: false, message: e.toString());
    }
  }

  static Future<void> resendSignUpCode({required String username}) async {
    await initialize();
    await CognitoAuthService.resendSignUpCode(email: username);
  }

  static Future<RegisterResult> registerWithBusiness({
    required String email,
    required String password,
    required Map<String, dynamic> businessData,
  }) async {
    await initialize();
    try {
      final r = await ApiService().registerWithBusiness(
        email: email,
        password: password,
        businessData: businessData,
      );
      return RegisterResult(
        success: true,
        message: r['message'] ?? 'Registration initiated successfully.',
        userSub: r['user_sub'],
        codeDeliveryDetails: r['code_delivery_details'],
        businessId: r['business_id'],
      );
    } catch (e) {
      return RegisterResult(success: false, message: e.toString());
    }
  }

  static Future<ConfirmResult> confirmRegistration({
    required String email,
    required String confirmationCode,
  }) async {
    await initialize();
    try {
      final r = await ApiService().confirmRegistration(
        email: email,
        confirmationCode: confirmationCode,
      );
      if (r['success'] == true) {
        if (r['verified'] == true &&
            r['user'] != null &&
            r['businesses'] != null) {
          if (r['businesses']?.isNotEmpty == true) {
            final businessId = r['businesses'][0]['businessId'];
            _container?.read(sessionProvider.notifier).setSession(businessId);
          }
          return ConfirmResult(
            success: true,
            message: r['message'] ?? 'Registration confirmed successfully',
            user: r['user'],
            business:
                r['businesses']?.isNotEmpty == true ? r['businesses'][0] : null,
          );
        } else {
          await _storeAuthTokens(r);
          if (r['user'] != null) {
            try {
              final bs = await ApiService().getUserBusinesses();
              if (bs.isNotEmpty) {
                _container
                    ?.read(sessionProvider.notifier)
                    .setSession(bs.first['businessId']);
              }
            } catch (_) {}
          }
          return ConfirmResult(
            success: true,
            message: r['message'] ?? 'Registration confirmed successfully',
            user: r['user'],
          );
        }
      }
      return ConfirmResult(
          success: false, message: r['message'] ?? 'Confirmation failed');
    } catch (e) {
      return ConfirmResult(success: false, message: e.toString());
    }
  }

  static Future<void> resendRegistrationCode({required String email}) async {
    await initialize();
    await ApiService().resendRegistrationCode(email: email);
  }

  static Future<EmailCheckResult> checkEmailExists(
      {required String email}) async {
    await initialize();
    try {
      final r = await ApiService().checkEmailExists(email: email);
      return EmailCheckResult(
        exists: r['exists'] ?? false,
        message: r['message'] ?? 'Email check completed',
      );
    } catch (e) {
      return EmailCheckResult(exists: false, message: e.toString());
    }
  }

  // ---------- Sign In / Session ----------
  static Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    await initialize();
    try {
      // Clear any existing session first (only if not on web)
      if (!kIsWeb) {
        try {
          final existing = await Amplify.Auth.fetchAuthSession();
          if ((existing as CognitoAuthSession).isSignedIn) {
            await signOut();
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } catch (_) {
          // Fallback to clearing stored tokens
        }
      }

      // Always clear stored tokens to ensure clean state
      await _clearStoredTokens();

      final resp = await ApiService().signIn(email: email, password: password);
      if (resp['success'] == true) {
        final authData = resp['data'];
        if (authData != null) {
          await _storeAuthTokens({
            'accessToken': authData['AccessToken'],
            'idToken': authData['IdToken'],
            'refreshToken': authData['RefreshToken'],
          });

          // Wait a moment for tokens to be properly stored
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Optional Amplify session (only on non-web platforms)
        if (!kIsWeb) {
          try {
            await CognitoAuthService.signIn(
                username: email, password: password);
          } catch (e) {
            print(
                '⚠️ Failed to create Amplify session, continuing with API tokens: $e');
          }
        }

        // Set session with first business if present
        if (resp['businesses'] != null && resp['businesses'].isNotEmpty) {
          _container
              ?.read(sessionProvider.notifier)
              .setSession(resp['businesses'][0]['businessId']);
        }

        return SignInResult(
          success: true,
          message: resp['message'] ?? 'Sign in successful',
          user: resp['user'],
          businesses: List<Map<String, dynamic>>.from(resp['businesses'] ?? []),
          data: authData,
        );
      }
      return SignInResult(
          success: false,
          message: resp['message'] ?? 'Sign-in failed',
          user: null,
          businesses: const [],
          data: null);
    } catch (e) {
      return SignInResult(
          success: false,
          message: e.toString(),
          user: null,
          businesses: const [],
          data: null);
    }
  }

  static Future<void> signOut() async {
    await initialize();

    // Attempt backend sign-out first (best-effort)
    String? refreshToken;
    try {
      final stored = await _getStoredTokens();
      refreshToken = stored['refreshToken'];
    } catch (_) {}
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await ApiService().signOut(refreshToken: refreshToken);
      } catch (e) {
        // Ignore backend sign-out errors; proceed with local cleanup
      }
    }

    // Best-effort Amplify sign out (only on non-web platforms)
    if (!kIsWeb) {
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session.isSignedIn) {
          await Amplify.Auth.signOut();
        }
      } catch (e) {
        print(
            '⚠️ Failed to sign out from Amplify, continuing with local cleanup: $e');
      }
    }

    await _clearStoredTokens();
    _container?.read(sessionProvider.notifier).clearSession();
    if (_container != null) {
      _container!.invalidate(businessProvider);
      _container!.read(realtimeOrderServiceProvider).disconnect();
    }
  }

  static Future<bool> isSignedIn() async {
    await initialize();
    try {
      final token = await TokenManager.getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getAccessToken() async {
    await initialize();
    return TokenManager.getAccessToken();
  }

  static Future<String?> getIdToken() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('id_token');
    
    if (storedToken == null || storedToken.isEmpty) {
      return null;
    }
    
    // Apply comprehensive sanitization to fix "Invalid key=value pair" errors
    String cleanedToken = _sanitizeIdToken(storedToken);
    
    // Update storage if we had to clean something significant
    if (storedToken != cleanedToken && cleanedToken.isNotEmpty) {
      print(
          '🔧 [AppAuthService] ID token was corrupted in storage, updating with clean version');
      await prefs.setString('id_token', cleanedToken);
    } else if (cleanedToken.isEmpty) {
      print(
          '❌ [AppAuthService] ID token became empty after sanitization, removing from storage');
      await prefs.remove('id_token');
      return null;
    }
    
    return cleanedToken;
  }

  /// Comprehensive ID token sanitization
  static String _sanitizeIdToken(String token) {
    print('🧹 [AppAuthService] Sanitizing ID token (length: ${token.length})');
    
    String cleaned = token.trim();

    // Log original token issues
    final hasNewlines = cleaned.contains('\n') || cleaned.contains('\r');
    final hasCyrillic = RegExp(r'[\u0400-\u04FF]').hasMatch(cleaned);
    final hasSpaces = cleaned.contains(' ');
    if (hasNewlines || hasCyrillic || hasSpaces) {
      print('🚨 [AppAuthService] ID token corruption detected:');
      print('   - Has newlines: $hasNewlines');
      print('   - Has Cyrillic: $hasCyrillic');
      print('   - Has spaces: $hasSpaces');
    }
    
    // Apply the same comprehensive sanitization as access tokens
    // STEP 1: Remove ALL non-printable ASCII characters
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x1F\x7F-\xFF]'), '');
    
    // STEP 2: Remove ALL Unicode characters (Cyrillic, etc.)
    cleaned = cleaned.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

    // STEP 3: Remove ALL whitespace characters
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');

    // STEP 4: Remove specific problematic characters
    cleaned = cleaned.replaceAll('\r', '');
    cleaned = cleaned.replaceAll('\n', '');
    cleaned = cleaned.replaceAll('\t', '');
    cleaned = cleaned.replaceAll("'", '');
    cleaned = cleaned.replaceAll('"', '');

    // STEP 5: Remove Bearer prefix if mistakenly included
    if (cleaned.toLowerCase().startsWith('bearer')) {
      cleaned = cleaned.substring(6);
    }
    
    // STEP 6: Keep ONLY valid JWT characters
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9\-_.]'), '');

    print(
        '🧹 [AppAuthService] ID token sanitized (new length: ${cleaned.length})');
    return cleaned;
  }

  static Future<Map<String, dynamic>?> refreshSession() async {
    await initialize();
    final tokens = await _getStoredTokens();
    final refresh = tokens['refreshToken'];
    if (refresh == null) {
      await signOut();
      return null;
    }
    try {
      final r = await ApiService().refreshToken(refresh);
      if (r['success'] == true) {
        final newTokens = r['data'];
        await _storeAuthTokens({
          'accessToken': newTokens['AccessToken'],
          'idToken': newTokens['IdToken'],
          'refreshToken': newTokens['RefreshToken'] ?? refresh,
        });
        return newTokens;
      } else {
        await signOut();
        return null;
      }
    } catch (_) {
      await signOut();
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    await initialize();

    // Try Cognito first (only on non-web platforms)
    if (!kIsWeb && AppConfig.isCognitoConfigured) {
      try {
        final u = await CognitoAuthService.getCurrentUser();
        if (u != null) return u;
      } catch (e) {
        print('⚠️ Failed to get Cognito user, falling back to API method: $e');
      }
    }

    // Fallback to backend token approach (always works on web)
    try {
      final token = await TokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final bs = await ApiService().getUserBusinesses();
        if (bs.isNotEmpty) {
          final b = bs.first;
          final id = b['businessId'];
          if (id != null) {
            _container?.read(sessionProvider.notifier).setSession(id);
          }
          return {
            'success': true,
            'email': b['email'],
            'userId': b['ownerId'] ?? b['cognitoUserId'],
            'sub': b['cognitoUserId'],
            'email_verified': true,
          };
        } else {
          await signOut();
        }
      }
    } catch (e) {
      if (e.toString().contains('401') ||
          e.toString().contains('Invalid or expired access token')) {
        await signOut();
      } else {
        rethrow;
      }
    }
    return null;
  }

  // ---------- Password Management ----------
  static Future<ForgotPasswordResult> forgotPassword(
      {required String email}) async {
    await initialize();
    try {
      final r = await CognitoAuthService.forgotPassword(username: email);
      return ForgotPasswordResult(
        success: r['success'] == true,
        message: r['message'] ?? 'Reset code sent successfully',
        codeDeliveryDetails: r['codeDeliveryDetails'],
      );
    } catch (e) {
      return ForgotPasswordResult(success: false, message: e.toString());
    }
  }

  static Future<ConfirmForgotPasswordResult> confirmForgotPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    await initialize();
    try {
      final r = await CognitoAuthService.confirmForgotPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      return ConfirmForgotPasswordResult(
        success: r['success'] == true,
        message: r['message'] ?? 'Password reset successfully',
      );
    } catch (e) {
      return ConfirmForgotPasswordResult(success: false, message: e.toString());
    }
  }

  static Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await initialize();
    try {
      final r = await CognitoAuthService.changePassword(
        oldPassword: currentPassword,
        newPassword: newPassword,
      );
      return ChangePasswordResult(
        success: r['success'] == true,
        message: r['message'] ?? 'Password changed successfully',
      );
    } catch (e) {
      return ChangePasswordResult(success: false, message: e.toString());
    }
  }

  // ---------- Private Helpers ----------
  static Future<void> _storeAuthTokens(Map<String, dynamic> tokens) async {
    final prefs = await SharedPreferences.getInstance();

    // Enhanced token storage with sanitization
    if (tokens['accessToken'] != null) {
      await TokenManager.setAccessToken(tokens['accessToken']);
    }

    if (tokens['idToken'] != null) {
      // Apply comprehensive sanitization for ID token storage
      String idToken = _sanitizeIdToken(tokens['idToken'].toString());

      if (idToken.isNotEmpty) {
        print('💾 Storing sanitized ID token (length: ${idToken.length})');
        await prefs.setString('id_token', idToken);
      } else {
        print('❌ ID token became empty after sanitization, not storing');
      }
    }

    if (tokens['refreshToken'] != null) {
      // Apply comprehensive sanitization for refresh token storage
      String refreshToken =
          _sanitizeRefreshToken(tokens['refreshToken'].toString());

      if (refreshToken.isNotEmpty) {
        print(
            '💾 Storing sanitized refresh token (length: ${refreshToken.length})');
        await prefs.setString('refresh_token', refreshToken);
      } else {
        print('❌ Refresh token became empty after sanitization, not storing');
      }
    }
  }

  /// Comprehensive refresh token sanitization
  static String _sanitizeRefreshToken(String token) {
    print(
        '🧹 [AppAuthService] Sanitizing refresh token (length: ${token.length})');
    
    String cleaned = token.trim();
    
    // Log original token issues
    final hasNewlines = cleaned.contains('\n') || cleaned.contains('\r');
    final hasCyrillic = RegExp(r'[\u0400-\u04FF]').hasMatch(cleaned);
    final hasSpaces = cleaned.contains(' ');
    if (hasNewlines || hasCyrillic || hasSpaces) {
      print('🚨 [AppAuthService] Refresh token corruption detected:');
      print('   - Has newlines: $hasNewlines');
      print('   - Has Cyrillic: $hasCyrillic');
      print('   - Has spaces: $hasSpaces');
    }
    
    // Apply comprehensive sanitization
    // STEP 1: Remove ALL non-printable ASCII characters
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x1F\x7F-\xFF]'), '');

    // STEP 2: Remove ALL Unicode characters (Cyrillic, etc.)
    cleaned = cleaned.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

    // STEP 3: Remove ALL whitespace characters
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    
    // STEP 4: Remove specific problematic characters
    cleaned = cleaned.replaceAll('\r', '');
    cleaned = cleaned.replaceAll('\n', '');
    cleaned = cleaned.replaceAll('\t', '');
    cleaned = cleaned.replaceAll("'", '');
    cleaned = cleaned.replaceAll('"', '');
    
    // STEP 5: Remove Bearer prefix if mistakenly included
    if (cleaned.toLowerCase().startsWith('bearer')) {
      cleaned = cleaned.substring(6);
    }
    
    // STEP 6: Keep ONLY valid characters for refresh tokens (more permissive than JWT)
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9\-_+=]'), '');

    print(
        '🧹 [AppAuthService] Refresh token sanitized (new length: ${cleaned.length})');
    return cleaned;
  }

  static Future<Map<String, String?>> _getStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'accessToken': await TokenManager.getAccessToken(),
      'idToken': prefs.getString('id_token'),
      'refreshToken': prefs.getString('refresh_token'),
    };
  }

  static Future<void> _clearStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await TokenManager.clearAccessToken();
      await prefs.remove('id_token');
      await prefs.remove('refresh_token');
      _container?.read(sessionProvider.notifier).clearSession();
    } catch (_) {}
  }
}

// ---------- Data Classes ----------
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
  EmailCheckResult({required this.exists, required this.message});
}

class ChangePasswordResult {
  final bool success;
  final String message;
  ChangePasswordResult({required this.success, required this.message});
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
