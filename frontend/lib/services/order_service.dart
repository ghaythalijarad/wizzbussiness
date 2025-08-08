import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../config/app_config.dart';

class OrderService {
  final String baseUrl = AppConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<Order>> getMerchantOrders(String? businessId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    if (businessId == null || businessId.isEmpty) {
      throw Exception('Business ID not provided');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/merchant/orders/$businessId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> ordersJson = data['orders'];
      return ordersJson.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<void> acceptMerchantOrder(String orderId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/merchant/order/$orderId/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to confirm order');
    }
  }

  Future<void> rejectMerchantOrder(String orderId, {String? reason}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/merchant/order/$orderId/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reason': reason ?? 'No reason provided'}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject order');
    }
  }

  Future<void> updateMerchantOrderStatus(String orderId, String status) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    // Convert internal status to backend format
    String backendStatus = _convertStatusToBackend(status);

    final response = await http.put(
      Uri.parse('$baseUrl/merchant/order/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': backendStatus}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update order status');
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
