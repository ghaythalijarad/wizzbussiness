import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:http/http.dart' as http;
import '../models/dish.dart';
import '../models/item_category.dart';
import '../models/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/app_auth_service.dart';

class ApiService {
  /// Base URL from app configuration (supports AWS deployment)
  final String baseUrl = AppConfig.baseUrl;

  /// Get authorization headers with stored token
  Future<Map<String, String>> _getAuthHeaders({bool isPublic = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (isPublic) {
      return headers;
    }

    if (AppConfig.useCognito && AppConfig.isCognitoConfigured) {
      // Use ID Token for Cognito User Pool authorizer (not Access Token)
      String? authToken = await AppAuthService.getIdToken();
      print(
          'ApiService: Cognito ID token retrieved: ${authToken != null ? "Yes" : "No"}');
      if (authToken == null) {
        final prefs = await SharedPreferences.getInstance();
        authToken = prefs.getString('access_token');
        print(
            'ApiService: Fallback token from SharedPreferences: ${authToken != null ? "Yes" : "No"}');
      }
      if (authToken != null) {
        // Truncate token for logging: show first/last 6 chars
        final truncated = authToken.length > 12
            ? '${authToken.substring(0, 6)}...${authToken.substring(authToken.length - 6)}'
            : authToken;
        headers['Authorization'] =
            'Bearer $authToken'; // Re-add "Bearer" prefix
        print('ApiService: Authorization header set with ID token: $truncated');
      } else {
        print('ApiService: No ID token available for Authorization header');
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token'; // Re-add "Bearer" prefix
        print('ApiService: Authorization header set (custom auth): $token');
      } else {
        print('ApiService: No custom auth token in SharedPreferences');
      }
    }

    return headers;
  }

  Future<List<ItemCategory>> getCategories(String businessId) async {
    try {
      print('getCategories (Amplify): businessId=$businessId');
      final restOperation = Amplify.API.get(
        '/api/categories/',
        apiName: 'haddir-api',
        queryParameters: {'business_id': businessId},
      );

      final response = await restOperation.response;
      print('getCategories (Amplify): status=${response.statusCode}');
      print('getCategories (Amplify): response=${response.decodeBody()}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.decodeBody());
        if (body is List) {
          return body
              .map((dynamic item) => ItemCategory.fromJson(item))
              .toList();
        } else {
          throw Exception(
              'Failed to load categories: Unexpected response format');
        }
      } else {
        final errorBody = response.decodeBody();
        print(
            'Failed to load categories. Status: ${response.statusCode}, Body: $errorBody');
        throw Exception(
            'Failed to load categories (Status ${response.statusCode}): $errorBody');
      }
    } on ApiException catch (e) {
      print('Failed to load categories with Amplify: ${e.message}');
      throw Exception('Failed to load categories: ${e.message}');
    }
  }

  Future<ItemCategory> createCategory(String businessId, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/categories/?business_id=$businessId'),
      headers: await _getAuthHeaders(),
      body: jsonEncode(<String, String>{
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      return ItemCategory.fromJson(jsonDecode(response.body));
    } else {
      print(
          'Error creating category: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to create category.');
    }
  }

  Future<List<Dish>> getItems(String categoryId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/categories/$categoryId/items'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Dish> items =
          body.map((dynamic item) => Dish.fromJson(item)).toList();
      return items;
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<Dish> createItem(String businessId, Dish item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/items/?business_id=$businessId'),
      headers: await _getAuthHeaders(),
      body: jsonEncode(item.toJson()),
    );

    if (response.statusCode == 200) {
      return Dish.fromJson(jsonDecode(response.body));
    } else {
      print('Error creating item: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to create item.');
    }
  }

  Future<Dish> updateItem(String businessId, Dish item) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/items/${item.id}/?business_id=$businessId'),
      headers: await _getAuthHeaders(),
      body: jsonEncode(item.toJson()),
    );

    if (response.statusCode == 200) {
      return Dish.fromJson(jsonDecode(response.body));
    } else {
      print('Error updating item: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to update item.');
    }
  }

  Future<void> deleteItem(String businessId, String itemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/items/$itemId/?business_id=$businessId'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode != 200) {
      print('Error deleting item: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to delete item.');
    }
  }

  Future<String> uploadItemImage(String itemId, String imagePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/items/$itemId/upload-image/'),
    );

    // Add auth headers
    final headers = await _getAuthHeaders();
    request.headers.addAll(headers);

    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final decodedData = jsonDecode(responseData);
      return decodedData['image_url'];
    } else {
      print('Error uploading image: ${response.statusCode}');
      throw Exception('Failed to upload image.');
    }
  }

  // Notification Management Methods

  /// Get notification history for a business
  Future<List<NotificationModel>> getNotificationHistory(
      String businessId) async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/notifications/history/$businessId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body
          .map((dynamic item) => NotificationModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load notification history');
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(
      String businessId, String notificationId) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/notifications/mark-read/$businessId/$notificationId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  /// Send a test notification
  Future<void> sendTestNotification(String businessId) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/notifications/test/$businessId'),
      headers: headers,
      body: jsonEncode({
        'title': 'Test Notification',
        'message': 'This is a test notification from the Flutter app',
        'type': 'test',
        'priority': 'normal'
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send test notification');
    }
  }

  // Order Management Methods

  /// Create a new order (typically called by customer app)
  Future<Map<String, dynamic>> createOrder(
      String businessId, Map<String, dynamic> orderData) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/?business_id=$businessId'),
      headers: headers,
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create order');
    }
  }

  /// Get orders for a business
  Future<List<Map<String, dynamic>>> getOrders(String businessId,
      {String? status}) async {
    final headers = await _getAuthHeaders();

    String url = '$baseUrl/api/orders/$businessId';
    if (status != null) {
      url += '?status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  /// Update order status
  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    final headers = await _getAuthHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/api/orders/$orderId/status'),
      headers: headers,
      body: jsonEncode({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update order status');
    }
  }

  // POS Settings Management Methods

  /// Get supported POS systems
  Future<List<Map<String, dynamic>>> getSupportedPosSystems() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/pos/systems'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load supported POS systems');
    }
  }

  /// Get POS settings for a business
  Future<Map<String, dynamic>> getPosSettings(String businessId) async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/pos/$businessId/settings'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load POS settings');
    }
  }

  /// Create POS settings for a business
  Future<Map<String, dynamic>> createPosSettings(
      String businessId, Map<String, dynamic> settings) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/pos/$businessId/settings'),
      headers: headers,
      body: jsonEncode(settings),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create POS settings');
    }
  }

  /// Update POS settings for a business
  Future<Map<String, dynamic>> updatePosSettings(
      String businessId, Map<String, dynamic> settings) async {
    final headers = await _getAuthHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/api/pos/$businessId/settings'),
      headers: headers,
      body: jsonEncode(settings),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update POS settings');
    }
  }

  /// Delete POS settings for a business
  Future<void> deletePosSettings(String businessId) async {
    final headers = await _getAuthHeaders();

    final response = await http.delete(
      Uri.parse('$baseUrl/api/pos/$businessId/settings'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete POS settings');
    }
  }

  /// Test POS connection
  Future<Map<String, dynamic>> testPosConnection(
      String businessId, Map<String, dynamic> testConfig) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/pos/$businessId/test-connection'),
      headers: headers,
      body: jsonEncode(testConfig),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to test POS connection');
    }
  }

  /// Get POS sync logs for a business
  Future<List<Map<String, dynamic>>> getPosSyncLogs(String businessId,
      {int limit = 50, int skip = 0}) async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse(
          '$baseUrl/api/pos/$businessId/sync-logs?limit=$limit&skip=$skip'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load POS sync logs');
    }
  }

  /// Manually sync an order to POS
  Future<Map<String, dynamic>> syncOrderToPos(
      String businessId, String orderId) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/pos/$businessId/sync-order'),
      headers: headers,
      body: jsonEncode({
        'order_id': orderId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sync order to POS');
    }
  }

  /// Get POS system health status
  Future<Map<String, dynamic>> getPosSystemHealth(String businessId) async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/pos/$businessId/health'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get POS system health');
    }
  }

  /// Retry failed POS sync
  Future<Map<String, dynamic>> retryPosSync(
      String businessId, String syncLogId) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/pos/$businessId/retry-sync'),
      headers: headers,
      body: jsonEncode({
        'sync_log_id': syncLogId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to retry POS sync');
    }
  }

  /// Get POS integration statistics
  Future<Map<String, dynamic>> getPosIntegrationStats(String businessId) async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/pos/$businessId/stats'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load POS integration statistics');
    }
  }

  /// Bulk sync multiple orders to POS
  Future<Map<String, dynamic>> bulkSyncOrdersToPos(
      String businessId, List<String> orderIds) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/pos/$businessId/bulk-sync'),
      headers: headers,
      body: jsonEncode({
        'order_ids': orderIds,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to bulk sync orders to POS');
    }
  }

  /// Update POS webhook configuration
  Future<Map<String, dynamic>> updatePosWebhookConfig(
      String businessId, Map<String, dynamic> webhookConfig) async {
    final headers = await _getAuthHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/api/pos/$businessId/webhook'),
      headers: headers,
      body: jsonEncode(webhookConfig),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update POS webhook configuration');
    }
  }

  /// Simple registration endpoint
  Future<Map<String, dynamic>> registerSimple({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-simple'),
      headers: await _getAuthHeaders(isPublic: true),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      print(
          'Error in registerSimple: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  /// Register a new business
  Future<Map<String, dynamic>> registerBusiness(
      Map<String, dynamic> businessData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-with-business'),
      headers: await _getAuthHeaders(isPublic: true),
      body: jsonEncode(businessData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print(
          'Error in registerBusiness: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to register business: ${response.body}');
    }
  }

  /// Register with business (alternative method signature)
  Future<Map<String, dynamic>> registerWithBusiness({
    required String email,
    required String password,
    required Map<String, dynamic> businessData,
  }) async {
    // Combine the parameters into a single businessData object
    final combinedData = {
      'email': email,
      'password': password,
      ...businessData,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-with-business'),
      headers: await _getAuthHeaders(isPublic: true),
      body: jsonEncode(combinedData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print(
          'Error in registerWithBusiness: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to register with business: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> confirmUser({
    required String email,
    required String confirmationCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/confirm'),
      headers: await _getAuthHeaders(isPublic: true),
      body: jsonEncode({
        'email': email,
        'verificationCode': confirmationCode,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      print(
          'Error in confirmRegistration: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to confirm registration: ${response.body}');
    }
  }

  /// Confirm registration (alternative method name)
  Future<Map<String, dynamic>> confirmRegistration({
    required String email,
    required String confirmationCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/confirm'),
      headers: await _getAuthHeaders(isPublic: true),
      body: jsonEncode({
        'email': email,
        'verificationCode': confirmationCode,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      print(
          'Error in confirmRegistration: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to confirm registration: ${response.body}');
    }
  }

  /// Resend registration verification code
  Future<void> resendRegistrationCode({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-code'),
      headers: await _getAuthHeaders(isPublic: true),
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print(
          'Error in resendRegistrationCode: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to resend verification code: ${response.body}');
    }
  }

  /// Check if email is already registered
  Future<Map<String, dynamic>> checkEmailExists({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/check-email'),
      headers: await _getAuthHeaders(isPublic: true),
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      print(
          'Error in checkEmailExists: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to check email: ${response.body}');
    }
  }

  /// Get user businesses for authenticated user
  Future<List<Map<String, dynamic>>> getUserBusinesses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/user-businesses'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['businesses'] != null) {
        return List<Map<String, dynamic>>.from(data['businesses']);
      }
      return [];
    } else {
      print(
          'Error in getUserBusinesses: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to get user businesses: ${response.body}');
    }
  }

  /// Fallback method for getting user businesses (using different endpoint or approach)
  Future<List<Map<String, dynamic>>> getUserBusinessesFallback() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/businesses'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['businesses'] != null) {
        return List<Map<String, dynamic>>.from(data['businesses']);
      }
      return [];
    } else {
      print(
          'Error in getUserBusinessesFallback: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Failed to get user businesses (fallback): ${response.body}');
    }
  }

  Future<List<Dish>> searchItems(String businessId, String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/items/search?business_id=$businessId&q=$query'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Dish.fromJson(item)).toList();
    } else {
      print('Error searching items: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to search items.');
    }
  }
}
