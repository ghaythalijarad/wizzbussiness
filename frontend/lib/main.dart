import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Show splash screen immediately then initialize
  runApp(const SplashScreen());
  _initializeApp();
}

// Extracted async setup to a separate function
Future<void> _initializeApp() async {
  try {
    // Consolidated Amplify plugin configuration
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyAPI(),
    ]);

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
    runApp(MyApp(
      initialLanguageCode: languageCode,
      isSignedIn: signedIn && business != null,
      business: business,
    ));
  } catch (e, _) {
    // Initialization error caught, show error screen
    print('Error during setup: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Initialization Error:\n$e',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    ));
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
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      theme: ThemeData(
        primarySwatch: const MaterialColor(
          0xFF3399FF,
          <int, Color>{
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
          },
        ),
        primaryColor: const Color(0xFF3399FF),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(
            0xFF3399FF,
            <int, Color>{
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
            },
          ),
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
        '/signup': (_) => const SignUpScreen(),
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
    );
  }
}
