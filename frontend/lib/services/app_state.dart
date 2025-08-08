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
  bool _isToggling = false;
  final ApiService _apiService = ApiService();

  bool get isOnline => _isOnline;
  bool get isToggling => _isToggling;

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

  /// Update business online status via API
  Future<void> updateBusinessOnlineStatus(
    String businessId,
    String userId,
    bool isOnline,
  ) async {
    try {
      debugPrint('🔄 AppState: Updating business online status to ${isOnline ? 'ONLINE' : 'OFFLINE'}');
      await _apiService.updateBusinessOnlineStatus(businessId, userId, isOnline);
      debugPrint('✅ AppState: Successfully updated business online status');
    } catch (e) {
      debugPrint('❌ AppState: Failed to update business online status: $e');
      rethrow;
    }
  }

  /// Get business online status from API
  Future<bool> getBusinessOnlineStatus(String businessId) async {
    try {
      debugPrint('🔄 AppState: Getting business online status');
      final response = await _apiService.getBusinessOnlineStatus(businessId);
      final isOnline = response['isOnline'] ?? false;
      debugPrint('✅ AppState: Retrieved business online status: ${isOnline ? 'ONLINE' : 'OFFLINE'}');
      return isOnline;
    } catch (e) {
      debugPrint('❌ AppState: Failed to get business online status: $e');
      return false; // Default to offline if we can't determine status
    }
  }

  /// Load business online status from API and update local state
  Future<void> loadOnlineStatusFromAPI(String businessId) async {
    try {
      final apiStatus = await getBusinessOnlineStatus(businessId);
      _isOnline = apiStatus;
      await _savePersistedStatus(_isOnline);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AppState: Failed to load online status from API: $e');
      // Keep current persisted status if API fails
    }
  }

  Future<void> setOnline(
      bool isOnline, Future<void> Function(bool) onToggleCallback) async {
    if (_isToggling) return; // Prevent multiple simultaneous toggles

    _isToggling = true;
    notifyListeners();

    try {
      await onToggleCallback(isOnline);
      // Only update the state if the operation succeeds
      _isOnline = isOnline;
      await _savePersistedStatus(_isOnline);
    } catch (error) {
      // Don't update the state if the operation fails
      debugPrint('❌ AppState: Failed to toggle online status: $error');
      rethrow; // Let the UI handle the error
    } finally {
      _isToggling = false;
      notifyListeners();
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
    _isToggling = false;
    notifyListeners();
  }
}
