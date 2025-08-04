import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
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
import 'providers/app_auth_provider.dart';
import 'firebase_options.dart';

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
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _initialLanguageCode = 'en';
  bool _isSignedIn = false;
  Business? _business;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Extracted async setup to a separate function
  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase only if properly configured
      if (DefaultFirebaseOptions.currentPlatform.projectId !=
          'your-project-id') {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print('✅ Firebase initialized successfully');
        } catch (e) {
          print('⚠️ Firebase initialization failed: $e');
          print('📱 App will continue without Firebase push notifications');
        }
      } else {
        print(
          '⚠️ Firebase not configured - using placeholder values. Push notifications disabled.',
        );
      }

      // Initialize local notifications
      await NotificationHelper.initialize();

      // Initialize Firebase push notifications (will gracefully handle missing Firebase)
      await FirebaseService().initialize();

      // Initialize Amplify for Auth and API only
      await Amplify.addPlugins([AmplifyAuthCognito(), AmplifyAPI()]);

      // Build configuration JSON from AppConfig
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
                  "AppClientId": "${AppConfig.cognitoUserPoolClientId}",
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

      // Restore existing session if any
      try {
        await Amplify.Auth.fetchAuthSession();
      } catch (_) {}

      // Determine launch page
      bool signedIn = await AppAuthService.isSignedIn();
      Business? business;
      if (signedIn) {
        try {
          final list = await ApiService().getUserBusinesses();
          if (list.isNotEmpty) business = Business.fromJson(list.first);
        } catch (e) {
          print('Error fetching user businesses: $e');
          // Clear stale session and treat as signed out
          try {
            await Amplify.Auth.signOut();
          } catch (_) {}
          signedIn = false;
        }
      }

      final languageCode = await LanguageService.getLanguage();
      
      setState(() {
        _initialLanguageCode = languageCode;
        _isSignedIn = signedIn && business != null;
        _business = business;
        _isInitialized = true;
      });
    } catch (e, _) {
      // Initialization error caught, show error screen
      print('Error during setup: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashScreen();
    }

    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Initialization Error:\n$_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return MyApp(
      initialLanguageCode: _initialLanguageCode,
      isSignedIn: _isSignedIn,
      business: _business,
    );
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

class MyApp extends StatefulWidget {
  final String initialLanguageCode;
  final bool isSignedIn;
  final Business? business;

  const MyApp({
    Key? key,
    required this.initialLanguageCode,
    required this.isSignedIn,
    this.business,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLanguageCode);
  }

  void changeLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
    LanguageService.setLanguage(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppAuthProvider(),
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        locale: _locale,
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
          fontFamily: _locale.languageCode == 'ar'
              ? GoogleFonts.cairo().fontFamily
              : GoogleFonts.inter().fontFamily,
          textTheme: _locale.languageCode == 'ar'
              ? GoogleFonts.cairoTextTheme()
              : GoogleFonts.interTextTheme(),
        ),
        home: widget.isSignedIn && widget.business != null
            ? BusinessDashboard(
                business: widget.business!,
                onLanguageChanged: (locale) =>
                    changeLanguage(locale.languageCode),
              )
            : LoginPage(
                onLanguageChanged: (locale) =>
                    changeLanguage(locale.languageCode),
              ),
        routes: {
          '/signup': (context) => SignUpScreen(
                onLanguageChanged: (locale) =>
                    changeLanguage(locale.languageCode),
              ),
          '/login': (_) => LoginPage(
                onLanguageChanged: (locale) =>
                    changeLanguage(locale.languageCode),
              ),
          '/verify': (context) {
            final email = ModalRoute.of(context)!.settings.arguments as String;
            return EmailVerificationScreen(email: email);
          },
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
