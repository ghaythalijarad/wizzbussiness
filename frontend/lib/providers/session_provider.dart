import 'package:amplify_flutter/amplify_flutter.dart';
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
    print('🔍 SessionProvider: Checking authentication status...');
    bool signedIn = await AppAuthService.isSignedIn();
    print('🔍 SessionProvider: isSignedIn result: $signedIn');
    
    if (signedIn) {
      try {
        print('🔍 SessionProvider: User signed in, fetching businesses...');
        // Add a small delay to ensure tokens are ready
        await Future.delayed(const Duration(milliseconds: 50));
        
        final list = await ApiService().getUserBusinesses();
        print(
            '🔍 SessionProvider: getUserBusinesses returned ${list.length} businesses');
        
        if (list.isNotEmpty) {
          final business = Business.fromJson(list.first);
          setSession(business.id);
          print(
              '✅ SessionProvider: Session validated with business ${business.id}');
        } else {
          // User is signed in but has no business.
          // Don't clear session if they're actually signed in - this could be a temporary API issue
          print(
              '⚠️ SessionProvider: User signed in but no businesses found - keeping session active');
          // Keep the session authenticated even without business data
          if (state.businessId != null) {
            // If we already have a businessId, keep it
            print('🔄 SessionProvider: Maintaining existing session state');
          } else {
            // Set authenticated state without businessId
            state = Session(businessId: null, isAuthenticated: true);
          }
        }
      } catch (e) {
        print('❌ SessionProvider: Error fetching user businesses: $e');
        print('❌ SessionProvider: Error type: ${e.runtimeType}');
        print(
            '❌ SessionProvider: Error string contains 401: ${e.toString().contains('401')}');

        // Be more conservative about clearing session - only clear on definitive auth errors
        // and avoid clearing immediately after login attempts
        if (e.toString().contains('401') ||
            e.toString().contains('Invalid or expired access token') ||
            e.toString().contains('Missing or invalid authorization header')) {
          print(
              '🧹 SessionProvider: Authentication error detected - clearing session');
          try {
            await Amplify.Auth.signOut();
          } catch (signOutError) {
            print(
                '⚠️ SessionProvider: Error during Amplify signOut: $signOutError');
          }
          clearSession();
        } else {
          print(
              'ℹ️ SessionProvider: API error but keeping session - may be temporary issue');
          // For non-authentication errors, keep the session active
          // If we already have a session, maintain it
          if (state.businessId != null) {
            print(
                '🔄 SessionProvider: Maintaining existing authenticated session despite API error');
          } else {
            // Set authenticated state without businessId for now
            state = Session(businessId: null, isAuthenticated: true);
          }
        }
      }
    } else {
      print('❌ SessionProvider: User not signed in, clearing session');
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
