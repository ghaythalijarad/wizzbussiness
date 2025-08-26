import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../services/app_auth_service.dart';
import 'initialization_provider.dart';

class Session {
  final String? businessId;
  final bool isAuthenticated;

  Session({this.businessId, this.isAuthenticated = false});
}

class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier() : super(Session());

  void setSession(String businessId) {
    print('🔧 SessionProvider.setSession called with businessId: $businessId');
    state = Session(businessId: businessId, isAuthenticated: true);
    print('🔧 SessionProvider.setSession completed - isAuthenticated: ${state.isAuthenticated}');
  }

  void clearSession() {
    print('🧹 SessionProvider.clearSession called');
    state = Session();
    print('🧹 SessionProvider.clearSession completed - isAuthenticated: ${state.isAuthenticated}');
  }

  Future<void> checkAuthStatus() async {
    bool signedIn = await AppAuthService.isSignedIn();
    if (signedIn) {
      try {
        final list = await ApiService().getUserBusinesses();
        if (list.isNotEmpty) {
          final business = Business.fromJson(list.first);
          setSession(business.id);
        } else {
          // User is signed in but has no business.
          // Don't clear session if they're actually signed in - this could be a temporary API issue
          print('User is signed in but no businesses found - keeping session active for now');
        }
      } catch (e) {
        print('Error fetching user businesses: $e');
        // Don't immediately clear session on API errors - could be temporary
        // Only clear if it's an authentication error (401)
        if (e.toString().contains('401') || e.toString().contains('Invalid or expired access token')) {
          print('Authentication error detected - clearing session');
          try {
            await Amplify.Auth.signOut();
          } catch (_) {}
          clearSession();
        } else {
          print('API error but keeping session - user may still be authenticated');
        }
      }
    } else {
      clearSession();
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, Session>((ref) {
  return SessionNotifier();
});

final authStatusProvider = FutureProvider<void>((ref) async {
  // Wait for initialization to complete
  await ref.watch(amplifyConfigurationProvider.future);
  // Then check auth status
  await ref.read(sessionProvider.notifier).checkAuthStatus();
});
