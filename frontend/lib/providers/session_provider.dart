import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/app_auth_service.dart';

class Session {
  final String? businessId;
  final bool isAuthenticated;
  final DateTime? lastLoginTime;

  Session({
    this.businessId,
    this.isAuthenticated = false,
    this.lastLoginTime,
  });

  Session copyWith({
    String? businessId,
    bool? isAuthenticated,
    DateTime? lastLoginTime,
  }) {
    return Session(
      businessId: businessId ?? this.businessId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
    );
  }
}

class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier() : super(Session());

  // Lightweight logger gated by build mode
  void _log(String message) {
    if (kDebugMode) print(message);
  }

  void setSession(String businessId) {
    _log('🔧 SessionProvider.setSession called with businessId: $businessId');
    state = Session(
      businessId: businessId,
      isAuthenticated: true,
      lastLoginTime: DateTime.now(),
    );
    _log(
        '🔧 SessionProvider.setSession completed - isAuthenticated: ${state.isAuthenticated}');
  }

  void clearSession() {
    _log('🧹 SessionProvider.clearSession called');
    state = Session();
    _log(
        '🧹 SessionProvider.clearSession completed - isAuthenticated: ${state.isAuthenticated}');
  }

  Future<void> checkAuthStatus() async {
    _log('🔍 SessionProvider: Checking authentication status...');
    bool signedIn = await AppAuthService.isSignedIn();
    _log('🔍 SessionProvider: isSignedIn result: $signedIn');
    
    if (signedIn) {
      try {
        _log(
            '🔍 SessionProvider: User signed in, setting session as authenticated...');
        // For now, just set as authenticated without requiring business data
        state = state.copyWith(isAuthenticated: true);
        _log('✅ SessionProvider: Session validated as authenticated');
      } catch (e) {
        _log('❌ SessionProvider: Error checking authentication: $e');

        // GRACE PERIOD: If an API error happens within 15 seconds of login,
        // ignore it to prevent a race condition where the app logs out
        // before the new token is fully propagated.
        final gracePeriod = const Duration(seconds: 15);
        if (state.lastLoginTime != null &&
            DateTime.now().difference(state.lastLoginTime!) < gracePeriod) {
          _log(
              '⚠️ API error occurred shortly after login. Ignoring to prevent race condition logout.');
          // Re-affirm authenticated state and exit
          state = state.copyWith(isAuthenticated: true);
          return;
        }

        // For other errors, clear the session
        _log('🔒 SessionProvider: Clearing session due to error');
        clearSession();
      }
    } else {
      _log('❌ SessionProvider: User not signed in, clearing session');
      clearSession();
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, Session>((ref) {
  return SessionNotifier();
});
