import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/signup_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/dashboards/business_dashboard.dart';
import 'providers/session_provider.dart';
import 'firebase_options.dart';
import 'services/floating_order_notification_service.dart';
import 'theme/theme_manager.dart';
import 'services/app_auth_service.dart';

// Background notification handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📩 Background notification received: ${message.messageId}');
  // Handle background notification here
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Show the main app with initialization logic
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Make Riverpod container available to AppAuthService for session updates
    final container = ProviderScope.containerOf(context);
    AppAuthService.setProviderContainer(container);
    final locale = ref.watch(localeProvider);
    final authStatus = ref.watch(authStatusProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ar', '')],
      theme: ref.read(themeDataProvider(locale)),
      darkTheme: ref.read(darkThemeDataProvider(locale)),
      themeMode: ref.watch(themeManagerProvider).useSystemTheme
          ? ThemeMode.system
          : ref.watch(themeManagerProvider).themeMode,
      debugShowCheckedModeBanner: false,
      home: authStatus.when(
        loading: () => const SplashScreenContent(),
        error: (err, stack) {
          print('Error during initialization: $err');
          print(stack);
          return ErrorScreenContent(error: err);
        },
        data: (_) {
          // Auth check is complete, now decide which screen to show
          final session = ref.watch(sessionProvider);
          // Initialize the notification service here
          ref
              .read(floatingOrderNotificationServiceProvider)
              .initialize(context);
          return session.isAuthenticated
              ? const BusinessDashboard()
              : const SignInScreen();
        },
      ),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/login': (_) => const SignInScreen(),
        '/verify': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return EmailVerificationScreen(email: email);
        },
      },
    );
  }
}

class SplashScreenContent extends StatelessWidget {
  const SplashScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}

class ErrorScreenContent extends StatelessWidget {
  final Object error;
  const ErrorScreenContent({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Initialization Error:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
