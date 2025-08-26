import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../firebase_options.dart';
import '../services/notification_helper.dart';
import '../services/firebase_service.dart';

/// Provider to handle the asynchronous initialization of Firebase.
final firebaseInitializationProvider = FutureProvider<void>((ref) async {
  // Initialize Firebase only if properly configured
  if (DefaultFirebaseOptions.currentPlatform.projectId != 'your-project-id') {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Initialize local and push notifications after Firebase is ready
      await NotificationHelper.initialize();
      await FirebaseService().initialize();
    } catch (e) {
      // Log the error but don't rethrow, as the app can run without Firebase
      print('⚠️ Firebase initialization failed: $e');
      print('📱 App will continue without Firebase push notifications');
    }
  } else {
    print(
      '⚠️ Firebase not configured - using placeholder values. Push notifications disabled.',
    );
  }
});

/// Provider to handle the asynchronous configuration of Amplify.
final amplifyConfigurationProvider = FutureProvider<void>((ref) async {
  // Wait for Firebase to initialize first, if needed for dependencies.
  await ref.watch(firebaseInitializationProvider.future);

  // If Amplify is already configured, don't re-configure.
  if (Amplify.isConfigured) {
    return;
  }

  try {
    await Amplify.addPlugins([AmplifyAuthCognito(), AmplifyAPI()]);

    final amplifyconfig = '''{
      "UserAgent": "aws-amplify-cli/2.0",
      "Version": "1.0",
      "auth": {
        "plugins": {
          "awsCognitoAuthPlugin": {
            "UserAgent": "aws-amplify-cli/0.1.0",
            "Version": "0.1.0",
            "CognitoUserPool": {
              "Default": {
                "PoolId": "${AppConfig.cognitoUserPoolId}",
                "AppClientId": "${AppConfig.appClientId}",
                "Region": "${AppConfig.cognitoRegion}"
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
              "region": "${AppConfig.cognitoRegion}",
              "authorizationType": "AMAZON_COGNITO_USER_POOLS"
            }
          }
        }
      }
    }''';

    await Amplify.configure(amplifyconfig);
  } catch (e) {
    print('❌ Amplify configuration failed: $e');
    // Rethrow to be caught by the UI layer and display an error screen
    throw Exception('Failed to configure Amplify: $e');
  }
});
