import 'dart:convert';
import '../models/order.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class OrderService {
  final String baseUrl = AppConfig.baseUrl;

  Future<List<Order>> getMerchantOrders(String? businessId) async {
    if (businessId == null || businessId.isEmpty) {
      throw Exception('Business ID not provided');
    }

    try {
      final apiService = ApiService();
      final response = await apiService.makeAuthenticatedRequest(
        method: 'GET',
        path: '/merchant/orders/$businessId',
        preferIdToken: false, // Use access token for API Gateway authorizers
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Orders response: ${response.body}');
        final List<dynamic> ordersJson = data['orders'];
        return ordersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        print('❌ Orders API Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception(
            'Failed to load orders: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
      rethrow;
    }
  }

  Future<void> acceptMerchantOrder(String orderId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.makeAuthenticatedRequest(
        method: 'PUT',
        path: '/merchant/order/$orderId/confirm',
        preferIdToken: false, // Use access token for API Gateway authorizers
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to confirm order');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectMerchantOrder(String orderId, {String? reason}) async {
    try {
      final apiService = ApiService();
      final response = await apiService.makeAuthenticatedRequest(
        method: 'PUT',
        path: '/merchant/order/$orderId/reject',
        body: jsonEncode({'reason': reason ?? 'No reason provided'}),
        preferIdToken: false, // Use access token for API Gateway authorizers
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reject order');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMerchantOrderStatus(String orderId, String status) async {
    try {
      // Convert internal status to backend format
      String backendStatus = _convertStatusToBackend(status);

      final apiService = ApiService();
      final response = await apiService.makeAuthenticatedRequest(
        method: 'PUT',
        path: '/merchant/order/$orderId/status',
        body: jsonEncode({'status': backendStatus}),
        preferIdToken: false, // Use access token for API Gateway authorizers
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      rethrow;
    }
  }

  String _convertStatusToBackend(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'pending';
      case 'confirmed':
        return 'confirmed';
      case 'ready':
        return 'ready';
      case 'cancelled':
        return 'rejected'; // Backend expects 'rejected' for cancelled orders
      case 'returned':
        return 'returned';
      case 'expired':
        return 'expired';
      default:
        return status;
    }
  }
}
