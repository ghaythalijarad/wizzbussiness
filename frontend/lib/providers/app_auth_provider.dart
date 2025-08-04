import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_auth_service.dart';

class AppAuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<void> initialize() async {
    try {
      final isSignedIn = await AppAuthService.isSignedIn();
      if (isSignedIn) {
        final currentUser = await AppAuthService.getCurrentUser();
        if (currentUser != null) {
          _currentUser = currentUser;
          _isAuthenticated = true;
          print('✅ AppAuthProvider: User authenticated on initialization');
        } else {
          // User appears signed in but can't get user data - token might be expired
          print(
              '⚠️ AppAuthProvider: Signed in but cannot get user data, clearing session');
          await AppAuthService.signOut();
          _isAuthenticated = false;
          _currentUser = null;
        }
      } else {
        _isAuthenticated = false;
        _currentUser = null;
        print('ℹ️ AppAuthProvider: User not signed in');
      }
    } catch (e) {
      print('❌ AppAuthProvider: Error during initialization: $e');
      _isAuthenticated = false;
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final result =
        await AppAuthService.signIn(email: email, password: password);
    if (result.success) {
      _currentUser = result.user;
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
      _currentUser = null;
    }
    notifyListeners();
  }

  /// Validate if the current authentication is still valid
  /// Returns true if valid, false if needs re-authentication
  Future<bool> validateAuthentication() async {
    print('🔍 AppAuthProvider.validateAuthentication() - Starting');
    print('🔍 Current _isAuthenticated state: $_isAuthenticated');

    if (!_isAuthenticated) {
      print('❌ Not authenticated according to provider state');
      print('🔄 Attempting to reinitialize provider...');

      // Try to reinitialize in case the provider state is stale
      await initialize();

      if (!_isAuthenticated) {
        print('❌ Still not authenticated after reinitialize');
        return false;
      } else {
        print('✅ Authentication state recovered after reinitialize');
      }
    }

    try {
      // Use the same validation logic as AppAuthService.isSignedIn() to ensure consistency
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      print(
          '🔍 Access token check: ${accessToken != null && accessToken.isNotEmpty}');

      if (accessToken == null || accessToken.isEmpty) {
        print('⚠️ AppAuthProvider: No access token found during validation');
        await signOut();
        return false;
      }

      print('🔍 Calling AppAuthService.getCurrentUser() for validation...');
      // Try to get current user to validate if tokens are still valid
      final currentUser = await AppAuthService.getCurrentUser();

      print('🔍 getCurrentUser result: ${currentUser != null}');
      if (currentUser != null) {
        print('🔍 User data keys: ${currentUser.keys}');
      }

      if (currentUser != null) {
        _currentUser = currentUser;
        print('✅ AppAuthProvider: Authentication validation successful');
        return true;
      } else {
        // Tokens might be expired, clear authentication
        print('⚠️ AppAuthProvider: Token validation failed, clearing session');
        await signOut();
        return false;
      }
    } catch (e) {
      print('❌ AppAuthProvider: Error validating authentication: $e');
      // If we get a 401 error, the token is likely expired
      if (e.toString().contains('401') ||
          e.toString().contains('Invalid or expired access token')) {
        print('🧹 AppAuthProvider: Clearing expired tokens due to 401 error');
        await signOut();
      }
      return false;
    }
  }

  /// Force refresh authentication state
  Future<void> refreshAuthenticationState() async {
    await initialize();
  }

  Future<void> signOut() async {
    await AppAuthService.signOut();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
