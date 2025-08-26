# Riverpod Migration Plan 🚀

## **Phase 1: Create Riverpod Equivalents**

### 1. Replace AuthProvider with Riverpod
Create `lib/providers/auth_provider_riverpod.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/cognito_auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, unconfirmed }

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? errorMessage;
  final AuthUser? currentUser;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.errorMessage,
    this.currentUser,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
    AuthUser? currentUser,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      currentUser: currentUser ?? this.currentUser,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnconfirmed => status == AuthStatus.unconfirmed;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());
  
  final CognitoAuthService _authService = CognitoAuthService();

  Future<void> initialize(String amplifyConfig) async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _authService.configure(amplifyConfig);
      final status = _authService.authStatus;
      
      AuthUser? currentUser;
      if (status == AuthStatus.authenticated) {
        currentUser = await _authService.getCurrentUser();
      }
      
      state = state.copyWith(
        status: status,
        currentUser: currentUser,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final result = await _authService.signIn(email: email, password: password);
      
      if (result.isSignedIn) {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          currentUser: user,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unconfirmed,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProviderRiverpod = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

### 2. Replace LanguageProvider with Riverpod
Create `lib/providers/language_provider_riverpod.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en', '')) {
    _loadLanguage();
  }

  static const String _languageKey = 'selected_language';

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        state = Locale(languageCode, '');
      }
    } catch (e) {
      // Keep default English
    }
  }

  Future<void> setLanguage(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
      state = locale;
    } catch (e) {
      // Handle error
    }
  }

  bool get isArabic => state.languageCode == 'ar';
  bool get isEnglish => state.languageCode == 'en';
}

final languageProviderRiverpod = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});
```

## **Phase 2: Update Main App Structure**

Update `lib/main.dart`:

```dart
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Set provider container for services
    AppAuthService.setProviderContainer(ref.container);
    
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
      default:
        return const AuthScreen();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

## **Phase 3: Update Widgets to Use Riverpod**

### Example: Update AuthScreen
```dart
// Before (Provider)
class AuthScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // ...
      },
    );
  }
}

// After (Riverpod)
class AuthScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProviderRiverpod);
    final authNotifier = ref.read(authProviderRiverpod.notifier);
    
    // ...
  }
}
```

## **Phase 4: Remove Provider Dependencies**

1. Remove `provider` package dependency from `pubspec.yaml`
2. Remove `import 'package:provider/provider.dart'` statements
3. Delete old Provider files:
   - `lib/providers/auth_provider.dart`
   - `lib/providers/language_provider.dart`
   - `lib/providers/app_auth_provider.dart`

## **Phase 5: Cleanup and Testing**

1. Update all Consumer widgets to ConsumerWidget/ConsumerStatefulWidget
2. Replace `context.read()` and `context.watch()` with `ref.read()` and `ref.watch()`
3. Test thoroughly to ensure no breaking changes
4. Update imports across the codebase

## **Migration Benefits After Completion**

✅ **Unified State Management**: Single approach across entire app
✅ **Better Performance**: Granular rebuilds only when needed  
✅ **Type Safety**: Compile-time error detection
✅ **Easier Testing**: Mock providers easily for unit tests
✅ **Better DevTools**: Enhanced debugging experience
✅ **Future-Proof**: Riverpod is actively maintained and evolving

## **Timeline Estimate**
- **Phase 1-2**: 1-2 days (Create new providers & update main)
- **Phase 3**: 2-3 days (Update all widgets)  
- **Phase 4-5**: 1 day (Cleanup & testing)
- **Total**: ~1 week for complete migration

The migration will result in cleaner, more maintainable code with better performance and developer experience.
