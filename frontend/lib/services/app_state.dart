import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AppState with ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    _loadPersistedStatus();
  }

  bool _isOnline = true;

  bool get isOnline => _isOnline;

  /// Load persisted online status from SharedPreferences
  Future<void> _loadPersistedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnline = prefs.getBool('business_online_status') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AppState: Failed to load persisted status: $e');
    }
  }

  /// Save online status to SharedPreferences for persistence
  Future<void> _savePersistedStatus(bool isOnline) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('business_online_status', isOnline);
    } catch (e) {
      debugPrint('❌ AppState: Failed to save persisted status: $e');
    }
  }

  void updateOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    _savePersistedStatus(_isOnline);
    notifyListeners();
  }

  void logout() {
    // Reset app state on logout
    _isOnline = true;
    notifyListeners();
  }

  /// Force online status when user logs in
  /// This ensures the business is automatically set to online after successful login
  Future<void> forceOnlineOnLogin(String businessId, String userId) async {
    try {
      debugPrint('🟢 AppState: Forcing online status ON after login');
      debugPrint('   Business ID: $businessId');
      debugPrint('   User ID: $userId');

      // Update local state to online
      _isOnline = true;
      await _savePersistedStatus(true);

      // Update backend status via API
      final apiService = ApiService();
      await apiService.updateBusinessOnlineStatus(businessId, userId, true);

      // Notify listeners of the state change
      notifyListeners();

      debugPrint('✅ AppState: Successfully forced online status ON after login');
    } catch (e) {
      debugPrint('❌ AppState: Failed to force online status after login: $e');
      // Don't throw error to prevent login failure
    }
  }
}
