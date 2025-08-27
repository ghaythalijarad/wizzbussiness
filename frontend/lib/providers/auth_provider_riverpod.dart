import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/cognito_auth_service.dart' as cognito;

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
  
  final cognito.CognitoAuthService _authService = cognito.CognitoAuthService();

  Future<void> initialize(String amplifyConfig) async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _authService.configure(amplifyConfig);
      final status = _authService.authStatus;
      
      AuthUser? currentUser;
      if (status == cognito.AuthStatus.authenticated) {
        currentUser = await _authService.getCurrentUser();
      }
      
      // Convert from service AuthStatus to provider AuthStatus
      AuthStatus providerStatus;
      switch (status) {
        case cognito.AuthStatus.authenticated:
          providerStatus = AuthStatus.authenticated;
          break;
        case cognito.AuthStatus.unauthenticated:
          providerStatus = AuthStatus.unauthenticated;
          break;
        case cognito.AuthStatus.unconfirmed:
          providerStatus = AuthStatus.unconfirmed;
          break;
        default:
          providerStatus = AuthStatus.unknown;
      }
      
      state = state.copyWith(
        status: providerStatus,
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

  /// Manually set authentication state (used when login is handled externally)
  void setAuthenticatedState({AuthUser? user}) {
    debugPrint('🔐 AuthNotifier: setAuthenticatedState() called');
    debugPrint('🔐 AuthNotifier: Current state before: ${state.status}');
    state = state.copyWith(
      status: AuthStatus.authenticated,
      currentUser: user,
      isLoading: false,
      errorMessage: null,
    );
    debugPrint('🔐 AuthNotifier: New state after: ${state.status}');
    debugPrint('🔐 AuthNotifier: setAuthenticatedState() completed');
  }

  Future<bool> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final result = await _authService.resetPassword(email: email);
      state = state.copyWith(isLoading: false);
      return result.isPasswordReset;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<Map<String, String>> getUserAttributes() async {
    try {
      final attributes = await _authService.getUserAttributes();
      // Convert List<AuthUserAttribute> to Map<String, String>
      final attributeMap = <String, String>{};
      for (final attr in attributes) {
        attributeMap[attr.userAttributeKey.key] = attr.value;
      }
      return attributeMap;
    } catch (e) {
      return {};
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProviderRiverpod = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
