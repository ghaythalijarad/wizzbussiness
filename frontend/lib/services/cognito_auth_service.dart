import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

/// AWS Cognito authentication service
class CognitoAuthService {
  static bool _isConfigured = false;

  /// Initialize Amplify with Cognito configuration
  static Future<void> configure({
    required String userPoolId,
    required String userPoolClientId,
    required String region,
    String? identityPoolId,
  }) async {
    if (_isConfigured) return;

    try {
      // Create Cognito configuration
      final authPlugin = AmplifyAuthCognito();

      // Configure Amplify
      await Amplify.addPlugin(authPlugin);

      // Create the configuration manually
      final config = '''
{
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
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "${identityPoolId ?? ''}",
              "Region": "$region"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "$userPoolId",
            "AppClientId": "$userPoolClientId",
            "Region": "$region"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "socialProviders": [],
            "usernameAttributes": ["email"],
            "signupAttributes": ["email"],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": []
            },
            "mfaConfiguration": "OFF",
            "mfaTypes": ["SMS"],
            "verificationMechanisms": ["EMAIL"]
          }
        }
      }
    }
  }
}''';

      await Amplify.configure(config);
      _isConfigured = true;
      safePrint('Amplify configured successfully');
    } catch (e) {
      safePrint('Error configuring Amplify: $e');
      rethrow;
    }
  }

  /// Sign up a new user
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    Map<String, String>? userAttributes,
  }) async {
    try {
      // Convert userAttributes to the correct type
      final Map<AuthUserAttributeKey, String> cognitoAttributes = {};
      if (userAttributes != null) {
        userAttributes.forEach((key, value) {
          // Map common attribute keys to AuthUserAttributeKey
          switch (key.toLowerCase()) {
            case 'email':
              cognitoAttributes[AuthUserAttributeKey.email] = value;
              break;
            case 'given_name':
            case 'givenName':
            case 'firstName':
              cognitoAttributes[AuthUserAttributeKey.givenName] = value;
              break;
            case 'family_name':
            case 'familyName':
            case 'lastName':
              cognitoAttributes[AuthUserAttributeKey.familyName] = value;
              break;
            case 'phone_number':
            case 'phoneNumber':
              cognitoAttributes[AuthUserAttributeKey.phoneNumber] = value;
              break;
            // For other attributes, we'll skip them or you can add more mappings
          }
        });
      }

      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: cognitoAttributes,
        ),
      );

      return {
        'success': true,
        'message': 'User registered successfully',
        'isSignUpComplete': result.isSignUpComplete,
        'nextStep': result.nextStep?.signUpStep.toString(),
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _parseAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Confirm sign up with verification code
  static Future<Map<String, dynamic>> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );

      return {
        'success': true,
        'message': 'Email verified successfully',
        'isSignUpComplete': result.isSignUpComplete,
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _parseAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Resend confirmation code
  static Future<Map<String, dynamic>> resendSignUpCode({
    required String email,
  }) async {
    try {
      final result = await Amplify.Auth.resendSignUpCode(username: email);

      return {
        'success': true,
        'message': 'Confirmation code sent successfully',
        'destination': result.codeDeliveryDetails.destination,
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _parseAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Sign in user
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        // Get user session for tokens
        final session = await Amplify.Auth.fetchAuthSession();
        String? accessToken;

        if (session is CognitoAuthSession) {
          accessToken = session.userPoolTokensResult.value.accessToken.raw;
        }

        return {
          'success': true,
          'message': 'Sign in successful',
          'isSignedIn': result.isSignedIn,
          'accessToken': accessToken,
        };
      } else {
        return {
          'success': false,
          'message': 'Sign in incomplete',
          'nextStep': result.nextStep?.signInStep.toString(),
        };
      }
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _parseAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Sign out user
  static Future<Map<String, dynamic>> signOut() async {
    try {
      await Amplify.Auth.signOut();
      return {
        'success': true,
        'message': 'Signed out successfully',
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _parseAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final session = await Amplify.Auth.fetchAuthSession();

      String? accessToken;
      if (session is CognitoAuthSession) {
        accessToken = session.userPoolTokensResult.value.accessToken.raw;
      }

      return {
        'success': true,
        'user': {
          'userId': user.userId,
          'username': user.username,
        },
        'accessToken': accessToken,
        'isSignedIn': session.isSignedIn,
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _parseAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Get user attributes
  static Future<Map<String, dynamic>> getUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();

      final attributeMap = <String, String>{};
      for (final attr in attributes) {
        attributeMap[attr.userAttributeKey.key] = attr.value;
      }

      return {
        'success': true,
        'attributes': attributeMap,
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _parseAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      final result = await Amplify.Auth.resetPassword(username: email);

      return {
        'success': true,
        'message': 'Password reset code sent',
        'destination': result.nextStep.codeDeliveryDetails?.destination,
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _parseAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Confirm password reset
  static Future<Map<String, dynamic>> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );

      return {
        'success': true,
        'message': 'Password reset successful',
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _parseAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Check if user is signed in
  static Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      return false;
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is CognitoAuthSession) {
        return session.userPoolTokensResult.value.accessToken.raw;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse Cognito auth errors into user-friendly messages
  static String _parseAuthError(AuthException e) {
    switch (e.runtimeType.toString()) {
      case 'UserNotFoundException':
        return 'User not found. Please check your email address.';
      case 'NotAuthorizedException':
        return 'Invalid email or password.';
      case 'UserNotConfirmedException':
        return 'Please verify your email before signing in.';
      case 'CodeMismatchException':
        return 'Invalid verification code.';
      case 'ExpiredCodeException':
        return 'Verification code has expired. Please request a new one.';
      case 'LimitExceededException':
        return 'Too many attempts. Please try again later.';
      case 'UsernameExistsException':
        return 'An account with this email already exists.';
      case 'InvalidPasswordException':
        return 'Password does not meet requirements.';
      case 'InvalidParameterException':
        return 'Invalid input. Please check your information.';
      case 'TooManyRequestsException':
        return 'Too many requests. Please wait before trying again.';
      default:
        return e.message;
    }
  }
}
