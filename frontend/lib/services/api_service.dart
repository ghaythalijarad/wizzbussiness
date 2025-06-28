import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dish.dart';
import '../models/item_category.dart';
import '../models/notification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiService {
  /// Base URL adjusts for Android emulator (10.0.2.2) vs iOS simulator (127.0.0.1)
  final String baseUrl = Platform.isAndroid
      ? "http://10.0.2.2:8000"
      : "http://127.0.0.1:8000";

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

  Future<List<ItemCategory>> getCategories(String businessId) async {
    final headers = await _getAuthHeaders();
    print('getCategories: businessId=$businessId');
    print('getCategories: headers=$headers');

    final response = await http.get(
      Uri.parse('$baseUrl/api/categories/?business_id=$businessId'),
      headers: headers,
    );

    print('getCategories: status=${response.statusCode}');
    print('getCategories: response=${response.body}');

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<ItemCategory> categories =
          body.map((dynamic item) => ItemCategory.fromJson(item)).toList();
      return categories;
    } else {
      throw Exception('Failed to load categories');
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

  Future<String> uploadItemImage(String itemId, XFile image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/items/$itemId/upload-image/'),
    );

    // Add auth headers
    final headers = await _getAuthHeaders();
    request.headers.addAll(headers);

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

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
      Uri.parse('$baseUrl/api/orders?business_id=$businessId'),
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
      throw Exception('Failed to update webhook configuration');
    }
  }

  /// Validate POS API credentials
  Future<Map<String, dynamic>> validatePosCredentials(
      String businessId, Map<String, dynamic> credentials) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/pos/$businessId/validate-credentials'),
      headers: headers,
      body: jsonEncode(credentials),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to validate POS credentials');
    }
  }

  /// Get user's businesses
  Future<List<Map<String, dynamic>>> getUserBusinesses() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/businesses/my-businesses'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load user businesses');
    }
  }

  /// Search items for a business with filtering options
  Future<Map<String, dynamic>> searchItems(
    String businessId, {
    String? query,
    String? categoryId,
    String? itemType,
    String? status,
    bool? isAvailable,
    double? minPrice,
    double? maxPrice,
    bool inStockOnly = false,
    String sortBy = 'name',
    String sortOrder = 'asc',
    int page = 1,
    int pageSize = 20,
  }) async {
    final headers = await _getAuthHeaders();

    // Build query parameters
    final queryParams = <String, String>{
      'business_id': businessId,
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (query != null && query.isNotEmpty) {
      queryParams['query'] = query;
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['category_id'] = categoryId;
    }
    if (itemType != null && itemType.isNotEmpty) {
      queryParams['item_type'] = itemType;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (isAvailable != null) {
      queryParams['is_available'] = isAvailable.toString();
    }
    if (minPrice != null) {
      queryParams['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['max_price'] = maxPrice.toString();
    }
    if (inStockOnly) {
      queryParams['in_stock_only'] = 'true';
    }

    // Build URI with query parameters
    final uri =
        Uri.parse('$baseUrl/api/items/').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error searching items: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to search items');
    }
  }

  // Discount Management Methods

  /// Create a new discount for a business
  Future<Map<String, dynamic>> createDiscount(
      String businessId, Map<String, dynamic> discountData) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/discounts?business_id=$businessId'),
      headers: headers,
      body: jsonEncode(discountData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Error creating discount: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to create discount');
    }
  }

  /// Get discounts for a business
  Future<List<Map<String, dynamic>>> getDiscounts(String businessId,
      {String? status, String? type}) async {
    final headers = await _getAuthHeaders();

    String url = '$baseUrl/api/discounts/$businessId';
    List<String> queryParams = [];
    
    if (status != null) {
      queryParams.add('status=$status');
    }
    if (type != null) {
      queryParams.add('type=$type');
    }
    
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load discounts');
    }
  }

  /// Update an existing discount
  Future<Map<String, dynamic>> updateDiscount(
      String businessId, String discountId, Map<String, dynamic> discountData) async {
    final headers = await _getAuthHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/api/discounts/$discountId?business_id=$businessId'),
      headers: headers,
      body: jsonEncode(discountData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error updating discount: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to update discount');
    }
  }

  /// Delete a discount
  Future<void> deleteDiscount(String businessId, String discountId) async {
    final headers = await _getAuthHeaders();

    final response = await http.delete(
      Uri.parse('$baseUrl/api/discounts/$discountId?business_id=$businessId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      print('Error deleting discount: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to delete discount');
    }
  }

  /// Apply discount to order
  Future<Map<String, dynamic>> applyDiscountToOrder(
      String businessId, String orderId, String discountId) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/discounts/$discountId/apply?business_id=$businessId'),
      headers: headers,
      body: jsonEncode({
        'order_id': orderId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to apply discount to order');
    }
  }

  /// Validate Buy X Get Y discount eligibility
  Future<Map<String, dynamic>> validateBuyXGetYDiscount(
      String businessId, String discountId, List<Map<String, dynamic>> orderItems) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/discounts/$discountId/validate-buyxgety?business_id=$businessId'),
      headers: headers,
      body: jsonEncode({
        'order_items': orderItems,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to validate Buy X Get Y discount');
    }
  }

  /// Get discount usage statistics
  Future<Map<String, dynamic>> getDiscountStats(String businessId, String discountId) async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/discounts/$discountId/stats?business_id=$businessId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load discount statistics');
    }
  }

  // Analytics and Reporting Methods

  /// Get comprehensive business analytics
  Future<Map<String, dynamic>> getBusinessAnalytics(String businessId, {
    String timeRange = 'month', // day, week, month, year
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final headers = await _getAuthHeaders();

    final queryParams = <String, String>{
      'time_range': timeRange,
    };

    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final uri = Uri.parse('$baseUrl/api/analytics/$businessId')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load business analytics');
    }
  }

  /// Get revenue analytics with detailed breakdown
  Future<Map<String, dynamic>> getRevenueAnalytics(String businessId, {
    String timeRange = 'month',
    bool includeComparison = true,
  }) async {
    final headers = await _getAuthHeaders();

    final queryParams = <String, String>{
      'time_range': timeRange,
      'include_comparison': includeComparison.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/analytics/$businessId/revenue')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load revenue analytics');
    }
  }

  /// Get top selling items analytics
  Future<List<Map<String, dynamic>>> getTopSellingItems(String businessId, {
    String timeRange = 'month',
    int limit = 10,
  }) async {
    final headers = await _getAuthHeaders();

    final queryParams = <String, String>{
      'time_range': timeRange,
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/analytics/$businessId/top-items')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load top selling items');
    }
  }

  /// Get performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics(String businessId, {
    String timeRange = 'month',
  }) async {
    final headers = await _getAuthHeaders();

    final queryParams = <String, String>{
      'time_range': timeRange,
    };

    final uri = Uri.parse('$baseUrl/api/analytics/$businessId/performance')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load performance metrics');
    }
  }

  /// Get order analytics and trends
  Future<Map<String, dynamic>> getOrderAnalytics(String businessId, {
    String timeRange = 'month',
    bool includeStatusBreakdown = true,
  }) async {
    final headers = await _getAuthHeaders();

    final queryParams = <String, String>{
      'time_range': timeRange,
      'include_status_breakdown': includeStatusBreakdown.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/analytics/$businessId/orders')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load order analytics');
    }
  }

  /// Get customer analytics
  Future<Map<String, dynamic>> getCustomerAnalytics(String businessId, {
    String timeRange = 'month',
  }) async {
    final headers = await _getAuthHeaders();

    final queryParams = <String, String>{
      'time_range': timeRange,
    };

    final uri = Uri.parse('$baseUrl/api/analytics/$businessId/customers')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load customer analytics');
    }
  }

  /// Get revenue chart data for visualization
  Future<List<Map<String, dynamic>>> getRevenueChartData(String businessId, {
    String timeRange = 'month',
    String chartType = 'line', // line, bar, area
  }) async {
    final headers = await _getAuthHeaders();

    final queryParams = <String, String>{
      'time_range': timeRange,
      'chart_type': chartType,
    };

    final uri = Uri.parse('$baseUrl/api/analytics/$businessId/revenue-chart')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load revenue chart data');
    }
  }

  /// Export analytics report
  Future<Map<String, dynamic>> exportAnalyticsReport(String businessId, {
    String format = 'pdf', // pdf, excel, csv
    String timeRange = 'month',
    List<String> sections = const ['revenue', 'orders', 'customers', 'performance'],
  }) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/analytics/$businessId/export'),
      headers: headers,
      body: jsonEncode({
        'format': format,
        'time_range': timeRange,
        'sections': sections,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to export analytics report');
    }
  }

  /// Get real-time analytics dashboard data
  Future<Map<String, dynamic>> getRealTimeAnalytics(String businessId) async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/analytics/$businessId/realtime'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load real-time analytics');
    }
  }

  /// Get comparative analytics (vs previous period)
  Future<Map<String, dynamic>> getComparativeAnalytics(String businessId, {
    String timeRange = 'month',
    String comparisonType = 'previous_period', // previous_period, same_period_last_year
  }) async {
    final headers = await _getAuthHeaders();

    final queryParams = <String, String>{
      'time_range': timeRange,
      'comparison_type': comparisonType,
    };

    final uri = Uri.parse('$baseUrl/api/analytics/$businessId/comparison')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load comparative analytics');
    }
  }

  /// Login user and store access token
  Future<void> login(String email, String password) async {
    // Use the real JWT login endpoint
    final uri = Uri.parse('$baseUrl/auth/jwt/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );
    // Debug logging
    print('ApiService.login -> POST $uri, status=${response.statusCode}');
    print('ApiService.login -> response=${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      print('✅ Login successful, token saved');
    } else if (response.statusCode == 400) {
      // Handle specific login errors
      final errorData = jsonDecode(response.body);
      if (errorData['detail'] == 'LOGIN_USER_NOT_VERIFIED') {
        throw Exception('Please verify your email address before logging in. Check your email for verification instructions.');
      } else if (errorData['detail'] == 'LOGIN_BAD_CREDENTIALS') {
        throw Exception('Invalid email or password. Please check your credentials and try again.');
      } else {
        throw Exception('Login failed: ${errorData['detail']}');
      }
    } else {
      throw Exception('Login failed: ${response.statusCode} ${response.body}');
    }
  }

  /// Register a new user
  Future<void> register(Map<String, dynamic> userData) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    // Debug logging
    print('ApiService.register -> POST $uri, status=${response.statusCode}');
    print('ApiService.register -> response=${response.body}');

    if (response.statusCode != 201) {
      throw Exception('Registration failed: ${response.statusCode} ${response.body}');
    }
  }
}
