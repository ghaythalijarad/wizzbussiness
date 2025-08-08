import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/initialization_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/signup_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/login_page.dart';
import 'screens/dashboards/business_dashboard.dart';
import 'models/business.dart';
import 'services/language_service.dart';
import 'services/api_service.dart';
import 'services/app_auth_service.dart';
import 'services/notification_helper.dart';
import 'services/firebase_service.dart';
import 'providers/session_provider.dart';
import 'firebase_options.dart';
import 'services/floating_order_notification_service.dart';

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
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusProvider);

    return authStatus.when(
      loading: () => const SplashScreen(),
      error: (err, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Initialization Error:\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
      data: (_) => const AuthStateWrapper(),
    );
  }
}

class AuthStateWrapper extends ConsumerWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the notification service here
    ref.read(floatingOrderNotificationServiceProvider).initialize(context);
    return const MyApp();
  }
}

// Add a splash screen widget for initial loading
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final locale = ref.watch(localeProvider);

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
      theme: ThemeData(
        primarySwatch: const MaterialColor(0xFF3399FF, <int, Color>{
          50: Color(0xFFE0F2FF),
          100: Color(0xFFB3DEFF),
          200: Color(0xFF80C9FF),
          300: Color(0xFF4DB3FF),
          400: Color(0xFF26A3FF),
          500: Color(0xFF3399FF),
          600: Color(0xFF0077FF),
          700: Color(0xFF006CFF),
          800: Color(0xFF0062FF),
          900: Color(0xFF004FFF),
        }),
        primaryColor: const Color(0xFF3399FF),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(0xFF3399FF, <int, Color>{
            50: Color(0xFFE0F2FF),
            100: Color(0xFFB3DEFF),
            200: Color(0xFF80C9FF),
            300: Color(0xFF4DB3FF),
            400: Color(0xFF26A3FF),
            500: Color(0xFF3399FF),
            600: Color(0xFF0077FF),
            700: Color(0xFF006CFF),
            800: Color(0xFF0062FF),
            900: Color(0xFF004FFF),
          }),
        ).copyWith(
          primary: const Color(0xFF3399FF),
          secondary: const Color(0xFF030e8e),
        ),
        fontFamily: locale.languageCode == 'ar'
            ? GoogleFonts.cairo().fontFamily
            : GoogleFonts.inter().fontFamily,
        textTheme: locale.languageCode == 'ar'
            ? GoogleFonts.cairoTextTheme()
            : GoogleFonts.interTextTheme(),
      ),
      home: session.isAuthenticated
          ? const BusinessDashboard()
          : const LoginPage(),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/login': (_) => const LoginPage(),
        '/verify': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return EmailVerificationScreen(email: email);
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
