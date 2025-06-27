import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CentralizedPlatformService {
  final String baseUrl = "http://localhost:8001"; // Backend server URL

  /// Get authorization headers with stored token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Test connection to the centralized platform
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/platform/test-connection'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to test platform connection: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error testing platform connection: $e');
    }
  }

  /// Get list of apps from the centralized platform
  Future<Map<String, dynamic>> getPlatformApps() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/platform/apps'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get platform apps: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting platform apps: $e');
    }
  }

  /// Deploy or update the centralized platform app
  Future<Map<String, dynamic>> deployCentralizedApp(
      Map<String, dynamic> appConfig) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/platform/deploy'),
        headers: headers,
        body: jsonEncode(appConfig),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to deploy centralized app: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deploying centralized app: $e');
    }
  }

  /// Sync a specific business to the centralized platform
  Future<Map<String, dynamic>> syncBusinessToPlatform(String businessId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/platform/sync-business/$businessId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to sync business to platform: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error syncing business to platform: $e');
    }
  }

  /// Sync all businesses to the centralized platform
  Future<Map<String, dynamic>> syncAllBusinessesToPlatform() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/platform/sync-all-businesses'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to sync all businesses to platform: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error syncing all businesses to platform: $e');
    }
  }

  /// Get the current sync status with the centralized platform
  Future<Map<String, dynamic>> getPlatformSyncStatus() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/platform/sync-status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get platform sync status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting platform sync status: $e');
    }
  }

  /// Set up the complete centralized platform integration
  Future<Map<String, dynamic>> setupCentralizedPlatform(
      Map<String, dynamic> setupConfig) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/platform/setup-platform'),
        headers: headers,
        body: jsonEncode(setupConfig),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to setup centralized platform: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error setting up centralized platform: $e');
    }
  }
}
