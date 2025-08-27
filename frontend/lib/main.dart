import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'amplifyconfiguration.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider_riverpod.dart';
import 'providers/language_provider_riverpod.dart';
import 'providers/business_provider.dart';
import 'providers/session_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/dashboards/business_dashboard.dart';
import 'screens/merchant_status_screen.dart';
import 'services/app_auth_service.dart';
import 'services/api_service.dart';
import 'utils/emergency_token_cleanup.dart';

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
  late ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // 🚨 EMERGENCY: Clear any corrupted token data on app start
    await EmergencyTokenCleanup.emergencyCleanup();
    
    // Get the provider container from the widget
    _container = ProviderScope.containerOf(context);
    
    // Set the SAME provider container for services
    AppAuthService.setProviderContainer(_container);

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
    debugPrint('🏠 Main: _buildHome called with auth status: ${authState.status}');
    
    if (authState.isLoading) {
      debugPrint('🏠 Main: Showing loading screen');
      return const _LoadingScreen();
    }

    switch (authState.status) {
      case AuthStatus.authenticated:
        debugPrint('🏠 Main: User authenticated, showing AuthenticationWrapper');
        return const _AuthenticationWrapper();
      case AuthStatus.unauthenticated:
      case AuthStatus.unconfirmed:
      case AuthStatus.unknown:
        debugPrint('🏠 Main: User not authenticated (${authState.status}), showing AuthScreen');
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

class _AuthenticationWrapper extends ConsumerStatefulWidget {
  const _AuthenticationWrapper();

  @override
  ConsumerState<_AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends ConsumerState<_AuthenticationWrapper> {
  bool _isInitializingSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitializeSession();
    });
  }

  Future<void> _checkAndInitializeSession() async {
    final session = ref.read(sessionProvider);
    final authState = ref.read(authProviderRiverpod);
    
    debugPrint('🔍 AuthWrapper: Checking session state...');
    debugPrint('🔍 AuthWrapper: Auth status: ${authState.status}');
    debugPrint('🔍 AuthWrapper: Session authenticated: ${session.isAuthenticated}');
    debugPrint('🔍 AuthWrapper: Session business ID: ${session.businessId}');

    // If authenticated but no session, try to establish one
    if (authState.isAuthenticated && (!session.isAuthenticated || session.businessId == null)) {
      debugPrint('🔄 AuthWrapper: User authenticated but no active session, attempting to establish session...');
      await _initializeSessionFromAuth();
    }
  }

  Future<void> _initializeSessionFromAuth() async {
    if (_isInitializingSession) return;
    
    setState(() {
      _isInitializingSession = true;
    });

    try {
      debugPrint('🔄 AuthWrapper: Fetching user businesses to establish session...');
      final apiService = ApiService();
      final businesses = await apiService.getUserBusinesses();
      
      if (businesses.isNotEmpty) {
        final businessData = businesses.first;
        final businessId = businessData['businessId'] ?? businessData['id'];
        
        if (businessId != null) {
          debugPrint('✅ AuthWrapper: Found business, setting session with ID: $businessId');
          debugPrint('🏢 AuthWrapper: Business data: ${businessData.keys}');
          
          // Store both business ID and business data in session
          ref.read(sessionProvider.notifier).setSessionWithBusinessData(businessId, businessData);
          
          // Invalidate business provider to trigger refresh
          ref.invalidate(businessProvider);
          ref.invalidate(enhancedBusinessProvider);
        } else {
          debugPrint('❌ AuthWrapper: Business data missing ID');
        }
      } else {
        debugPrint('❌ AuthWrapper: No businesses found for authenticated user');
      }
    } catch (e) {
      debugPrint('❌ AuthWrapper: Error establishing session: $e');
      
      // If we get unauthorized, clear auth state to prevent infinite loop
      if (e.toString().contains('Unauthorized') || e.toString().contains('401')) {
        debugPrint('🧹 AuthWrapper: Clearing auth state due to unauthorized error');
        await AppAuthService.signOut();
        ref.read(authProviderRiverpod.notifier).signOut();
        return;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingSession = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(enhancedBusinessProvider);
    
    // Show loading if we're initializing session
    if (_isInitializingSession) {
      debugPrint('🔄 AuthWrapper: Initializing session...');
      return const _LoadingScreen();
    }

    return businessAsync.when(
      data: (business) {
        if (business == null) {
          // No business found, redirect to auth
          debugPrint('🔍 AuthWrapper: No business found, redirecting to auth');
          return const AuthScreen();
        }

        // AUTHORIZATION: Check business status and route accordingly
        debugPrint('🔐 AUTHORIZATION: Business status is "${business.status}"');
        debugPrint('🔐 AUTHORIZATION: Business name is "${business.name}"');
        debugPrint('🔐 AUTHORIZATION: Business ID is "${business.id}"');

        switch (business.status.toLowerCase().trim()) {
          case 'approved':
            debugPrint('✅ AUTHORIZATION: Business APPROVED - Full access granted');
            return BusinessDashboard(initialBusiness: business);

          case 'pending':
            debugPrint('⏸️ AUTHORIZATION: Business PENDING - Limited access, showing status screen');
            return MerchantStatusScreen(status: business.status, business: business);

          case 'pending_review':
          case 'under_review':
            debugPrint('🔍 AUTHORIZATION: Business UNDER REVIEW - Limited access, showing status screen');
            return MerchantStatusScreen(status: business.status, business: business);

          case 'rejected':
            debugPrint('❌ AUTHORIZATION: Business REJECTED - Limited access, showing status screen');
            return MerchantStatusScreen(status: business.status, business: business);

          case 'suspended':
            debugPrint('🚫 AUTHORIZATION: Business SUSPENDED - Limited access, showing status screen');
            return MerchantStatusScreen(status: business.status, business: business);

          default:
            debugPrint('❓ AUTHORIZATION: Unknown business status "${business.status}" - Showing status screen');
            return MerchantStatusScreen(status: business.status, business: business);
        }
      },
      loading: () {
        debugPrint('⏳ AuthWrapper: Loading business data...');
        return const _LoadingScreen();
            },
      error: (error, stack) {
        debugPrint('❌ AuthWrapper: Error loading business data: $error');
        return const AuthScreen();
      },
    );
  }
}
