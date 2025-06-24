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
          primarySwatch: Colors.blue,
          fontFamily: GoogleFonts.cairo().fontFamily,
        ),
        home: WizzBusinessSplashPage(onLanguageChanged: _setLocale),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
