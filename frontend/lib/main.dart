import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

// Import services
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'screens/wizz_business_splash_page.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await _initializeApp();

  // Get saved language
  final languageCode = await LanguageService.getLanguage();

  runApp(MyApp(initialLanguageCode: languageCode));
}

Future<void> _initializeApp() async {
  // Initialize notification service
  await NotificationService.init();

  // Request permissions
  await Permission.notification.request();
}

class MyApp extends StatefulWidget {
  final String initialLanguageCode;

  const MyApp({
    Key? key,
    required this.initialLanguageCode,
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

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Auth(),
      child: MaterialApp(
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
          fontFamily: GoogleFonts.cairo().fontFamily,
        ),
        home: WizzBusinessSplashPage(onLanguageChanged: _setLocale),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
