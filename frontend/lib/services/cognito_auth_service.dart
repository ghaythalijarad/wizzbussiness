import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import '../config/app_config.dart';

/// Real AWS Cognito Auth Service implementation using Amplify
class CognitoAuthService {
  static bool _isConfigured = false;

  /// Configure Cognito settings
  static Future<void> configure({
    required String userPoolId,
    required String userPoolClientId,
    required String region,
    String? identityPoolId,
  }) async {
    if (_isConfigured) return;

    try {
      // Check if Amplify is already configured
      if (Amplify.isConfigured) {
        _isConfigured = true;
        print('✅ Amplify already configured, skipping configuration');
        return;
      }

      // Configure Amplify with Cognito
      final authPlugin = AmplifyAuthCognito();
      final apiPlugin = AmplifyAPI();
      await Amplify.addPlugins([authPlugin, apiPlugin]);

      // Configure Amplify
      final amplifyconfig = '''{
        "UserAgent": "aws-amplify-cli/2.0",
        "Version": "1.0",
        "auth": {
          "plugins": {
            "awsCognitoAuthPlugin": {
              "UserAgent": "aws-amplify-cli/0.1.0",
              "Version": "0.1.0",
              "IdentityManager": {
                "Default": {}
              },
              "CognitoUserPool": {
                "Default": {
                  "PoolId": "$userPoolId",
                  "AppClientId": "$userPoolClientId",
                  "Region": "$region"
                }
              }
            }
          }
        },
        "api": {
          "plugins": {
            "awsAPIPlugin": {
              "haddir-api": {
                "endpointType": "REST",
                "endpoint": "${AppConfig.baseUrl}",
                "region": "$region",
                "authorizationType": "AMAZON_COGNITO_USER_POOLS"
              }
            }
          }
        }
      }''';

      await Amplify.configure(amplifyconfig);
      _isConfigured = true;
      print('✅ Cognito Auth Service configured successfully');
    } catch (e) {
      print('❌ Error configuring Cognito Auth Service: $e');
      // If Amplify is already configured, that's okay
      if (e.toString().contains('Amplify has already been configured')) {
        _isConfigured = true;
        print('✅ Amplify already configured, continuing...');
      } else {
        throw e;
      }
    }
  }

  /// Check if Cognito is properly configured
  static bool get isConfigured => _isConfigured;

  /// Sign up a new user
  static Future<Map<String, dynamic>> signUp({
    required String username,
    required String password,
    Map<String, String>? userAttributes,
  }) async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      final result = await Amplify.Auth.signUp(
        username: username,
        password: password,
        options: SignUpOptions(
          userAttributes: userAttributes?.map(
                (key, value) => MapEntry(
                  CognitoUserAttributeKey.parse(key),
                  value,
                ),
              ) ??
              {},
        ),
      );

      return {
        'success': true,
        'message':
            'User created successfully. Please check your email for verification code.',
        'userSub': result.userId,
        'nextStep': result.nextStep.signUpStep.name,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Confirm sign up with verification code
  static Future<Map<String, dynamic>> confirmSignUp({
    required String username,
    required String confirmationCode,
  }) async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: username,
        confirmationCode: confirmationCode,
      );

      return {
        'success': result.isSignUpComplete,
        'message': result.isSignUpComplete
            ? 'Email verified successfully'
            : 'Verification in progress',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Resend signup confirmation code
  static Future<void> resendSignUpCode({required String email}) async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      await Amplify.Auth.resendSignUpCode(username: email);
    } catch (e) {
      throw Exception('Failed to resend code: $e');
    }
  }

  /// Sign in user
  static Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
  }) async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      final result = await Amplify.Auth.signIn(
        username: username,
        password: password,
      );

      if (result.isSignedIn) {
        // Get tokens
        final session = await Amplify.Auth.fetchAuthSession();
        final cognitoSession = session as CognitoAuthSession;

        // Get user attributes
        final user = await Amplify.Auth.getCurrentUser();
        final userAttributes = await Amplify.Auth.fetchUserAttributes();

        final userAttributesMap = <String, String>{};
        for (final attr in userAttributes) {
          userAttributesMap[attr.userAttributeKey.key] = attr.value;
        }

        // Check if tokens are available
        try {
          final tokens = cognitoSession.userPoolTokensResult.value;
          print('✅ Cognito tokens retrieved successfully during sign in');

          return {
            'success': true,
            'accessToken': tokens.accessToken.raw,
            'idToken': tokens.idToken.raw,
            'refreshToken': tokens.refreshToken,
            'user': {
              'userId': user.userId,
              'username': user.username,
              'email': userAttributesMap['email'],
              'email_verified': userAttributesMap['email_verified'] == 'true',
              'sub': user.userId,
              ...userAttributesMap,
            },
          };
        } catch (tokenError) {
          print('❌ Cognito tokens not available after sign in: $tokenError');
          return {
            'success': false,
            'message': 'Authentication tokens not available: $tokenError',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Sign in not completed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Sign out user
  static Future<void> signOut() async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Get current access token
  static Future<String?> getAccessToken() async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;

      if (cognitoSession.isSignedIn) {
        try {
          final tokens = cognitoSession.userPoolTokensResult.value;
          print('✅ Cognito access token retrieved successfully');
          return tokens.accessToken.raw;
        } catch (tokenError) {
          print('❌ Error accessing Cognito tokens: $tokenError');
          return null;
        }
      }
      print('❌ User not signed in to Cognito');
      return null;
    } catch (e) {
      print('❌ Error getting access token: $e');
      return null;
    }
  }

  /// Get current user information
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      // Check if user is signed in
      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;

      if (!cognitoSession.isSignedIn) {
        print('❌ No user currently signed in');
        return null;
      }

      // Get current user details
      final user = await Amplify.Auth.getCurrentUser();
      final userAttributes = await Amplify.Auth.fetchUserAttributes();

      final userAttributesMap = <String, String>{};
      for (final attr in userAttributes) {
        userAttributesMap[attr.userAttributeKey.key] = attr.value;
      }

      return {
        'success': true,
        'userId': user.userId,
        'username': user.username,
        'email': userAttributesMap['email'],
        'email_verified': userAttributesMap['email_verified'] == 'true',
        'given_name': userAttributesMap['given_name'],
        'family_name': userAttributesMap['family_name'],
        'phone_number': userAttributesMap['phone_number'],
        'sub': user.userId,
        ...userAttributesMap,
      };
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is signed in
  static Future<bool> isSignedIn() async {
    if (!_isConfigured) {
      return false;
    }

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;
      return cognitoSession.isSignedIn;
    } catch (e) {
      print('❌ Error checking if user is signed in: $e');
      return false;
    }
  }

  /// Change user password
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      await Amplify.Auth.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Forgot password - initiate reset
  static Future<Map<String, dynamic>> forgotPassword({
    required String username,
  }) async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      await Amplify.Auth.resetPassword(username: username);

      return {
        'success': true,
        'message': 'Password reset code sent to your email',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Confirm forgot password with new password
  static Future<Map<String, dynamic>> confirmForgotPassword({
    required String username,
    required String confirmationCode,
    required String newPassword,
  }) async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      await Amplify.Auth.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );

      return {
        'success': true,
        'message': 'Password reset successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get user attributes
  static Future<Map<String, dynamic>?> getUserAttributes() async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      final userAttributes = await Amplify.Auth.fetchUserAttributes();

      final userAttributesMap = <String, dynamic>{};
      for (final attr in userAttributes) {
        userAttributesMap[attr.userAttributeKey.key] = attr.value;
      }

      return userAttributesMap;
    } catch (e) {
      print('❌ Error getting user attributes: $e');
      return null;
    }
  }

  /// Update user attributes
  static Future<Map<String, dynamic>> updateUserAttributes(
    Map<String, String> attributes,
  ) async {
    if (!_isConfigured) {
      throw Exception('CognitoAuthService not configured');
    }

    try {
      final List<AuthUserAttribute> userAttributes = attributes.entries
          .map((entry) => AuthUserAttribute(
                userAttributeKey: CognitoUserAttributeKey.parse(entry.key),
                value: entry.value,
              ))
          .toList();

      await Amplify.Auth.updateUserAttributes(attributes: userAttributes);

      return {
        'success': true,
        'message': 'User attributes updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
