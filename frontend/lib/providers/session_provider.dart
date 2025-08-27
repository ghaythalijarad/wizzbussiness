import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/app_auth_service.dart';

class Session {
  final String? businessId;
  final bool isAuthenticated;
  final DateTime? lastLoginTime;
  final Map<String, dynamic>? businessData; // Add this to store business data

  Session({
    this.businessId,
    this.isAuthenticated = false,
    this.lastLoginTime,
    this.businessData, // Add this parameter
  });

  Session copyWith({
    String? businessId,
    bool? isAuthenticated,
    DateTime? lastLoginTime,
    Map<String, dynamic>? businessData, // Add this parameter
  }) {
    return Session(
      businessId: businessId ?? this.businessId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      businessData: businessData ?? this.businessData, // Add this line
    );
  }
}

class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier() : super(Session()) {
    _log('🔧 SessionNotifier: Constructor called - initial state: authenticated=${state.isAuthenticated}, businessId=${state.businessId}');
  }

  // Lightweight logger gated by build mode
  void _log(String message) {
    if (kDebugMode) print(message);
  }

  void setSession(String businessId) {
    _log('🔧 SessionProvider.setSession called with businessId: $businessId');
    _log('🔧 SessionProvider.setSession BEFORE: authenticated=${state.isAuthenticated}, businessId=${state.businessId}');
    state = Session(
      businessId: businessId,
      isAuthenticated: true,
      lastLoginTime: DateTime.now(),
      businessData: state.businessData, // Preserve existing business data
    );
    _log('🔧 SessionProvider.setSession AFTER: authenticated=${state.isAuthenticated}, businessId=${state.businessId}');
    _log('🔧 SessionProvider.setSession completed successfully');
  }

  void setSessionWithBusinessData(String businessId, Map<String, dynamic> businessData) {
    _log('🔧 SessionProvider.setSessionWithBusinessData called with businessId: $businessId');
    _log('🔧 SessionProvider.setSessionWithBusinessData business data keys: ${businessData.keys}');
    state = Session(
      businessId: businessId,
      isAuthenticated: true,
      lastLoginTime: DateTime.now(),
      businessData: businessData,
    );
    _log('🔧 SessionProvider.setSessionWithBusinessData completed successfully');
  }

  void clearSession() {
    _log('🧹 SessionProvider.clearSession called');
    _log('🧹 SessionProvider.clearSession BEFORE: authenticated=${state.isAuthenticated}, businessId=${state.businessId}');
    state = Session();
    _log('🧹 SessionProvider.clearSession AFTER: authenticated=${state.isAuthenticated}, businessId=${state.businessId}');
    _log('🧹 SessionProvider.clearSession completed');
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
