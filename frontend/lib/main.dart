import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'amplifyconfiguration.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider_riverpod.dart';
import 'providers/language_provider_riverpod.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/dashboards/main_dashboard.dart';
import 'services/app_auth_service.dart';

void main() {
  runApp(
    ProviderScope(
      child: const OrderReceiverApp(),
    ),
  );
}

class OrderReceiverApp extends ConsumerStatefulWidget {
  const OrderReceiverApp({super.key});

  @override
  ConsumerState<OrderReceiverApp> createState() => _OrderReceiverAppState();
}

class _OrderReceiverAppState extends ConsumerState<OrderReceiverApp> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Set provider container for services
    AppAuthService.setProviderContainer(ProviderContainer());

    // Initialize auth
    await ref.read(authProviderRiverpod.notifier).initialize(amplifyconfig);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProviderRiverpod);
    final currentLocale = ref.watch(languageProviderRiverpod);

    return MaterialApp(
      title: 'WIZZ Business Manager',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: currentLocale,
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
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    if (authState.isLoading) {
      return const _LoadingScreen();
    }

    switch (authState.status) {
      case AuthStatus.authenticated:
        return const MainDashboard();
      case AuthStatus.unauthenticated:
      case AuthStatus.unconfirmed:
      case AuthStatus.unknown:
        return const AuthScreen();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Initializing WIZZ...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
