import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // For development/testing purposes
    // In production, you would have proper Firebase configuration
    return const FirebaseOptions(
      apiKey: 'development-key',
      appId: 'development-app-id',
      messagingSenderId: 'development-sender-id',
      projectId: 'hadhir-business-dev',
      storageBucket: 'hadhir-business-dev.appspot.com',
    );
  }
}
