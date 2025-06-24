import 'dart:convert';
import 'package:http/http.dart' as http;

enum PosSystemType {
  square,
  toast,
  clover,
  shopifyPos,
  genericApi,
}

class PosSettings {
  bool enabled;
  bool autoSendOrders;
  PosSystemType systemType;
  String apiEndpoint;
  String apiKey;
  String? accessToken;
  String? locationId;

  PosSettings({
    this.enabled = false,
    this.autoSendOrders = false,
    this.systemType = PosSystemType.genericApi,
    this.apiEndpoint = '',
    this.apiKey = '',
    this.accessToken,
    this.locationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'autoSendOrders': autoSendOrders,
      'systemType': systemType.toString().split('.').last,
      'apiEndpoint': apiEndpoint,
      'apiKey': apiKey,
      'accessToken': accessToken,
      'locationId': locationId,
    };
  }

  factory PosSettings.fromJson(Map<String, dynamic> json) {
    return PosSettings(
      enabled: json['enabled'] ?? false,
      autoSendOrders: json['autoSendOrders'] ?? false,
      systemType: PosSystemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['systemType'],
        orElse: () => PosSystemType.genericApi,
      ),
      apiEndpoint: json['apiEndpoint'] ?? '',
      apiKey: json['apiKey'] ?? '',
      accessToken: json['accessToken'],
      locationId: json['locationId'],
    );
  }
}

class PosService {
  static const Duration _connectionTimeout = Duration(seconds: 10);

  // Test connection to POS system
  static Future<bool> testConnection(PosSettings settings) async {
    try {
      if (settings.apiEndpoint.isEmpty || settings.apiKey.isEmpty) {
        return false;
      }

      final uri = Uri.parse(settings.apiEndpoint);
      if (!uri.isAbsolute) {
        return false;
      }

      final headers = _buildHeaders(settings);

      // Test with a basic GET request or health check endpoint
      final response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(_connectionTimeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // Send order to POS system
  static Future<bool> sendOrderToPos(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) async {
    try {
      if (!settings.enabled || settings.apiEndpoint.isEmpty) {
        return false;
      }

      final uri = Uri.parse('${settings.apiEndpoint}/orders');
      final headers = _buildHeaders(settings);
      headers['Content-Type'] = 'application/json';

      final orderPayload = _formatOrderForPos(orderData, settings);

      final response = await http
          .post(
            uri,
            headers: headers,
            body: json.encode(orderPayload),
          )
          .timeout(_connectionTimeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // Build authentication headers based on POS system type
  static Map<String, String> _buildHeaders(PosSettings settings) {
    final headers = <String, String>{};

    switch (settings.systemType) {
      case PosSystemType.square:
        headers['Authorization'] = 'Bearer ${settings.accessToken}';
        headers['Square-Version'] = '2023-10-18';
        break;
      case PosSystemType.toast:
        headers['Authorization'] = 'Bearer ${settings.accessToken}';
        headers['Toast-Restaurant-External-ID'] = settings.locationId ?? '';
        break;
      case PosSystemType.clover:
        headers['Authorization'] = 'Bearer ${settings.accessToken}';
        break;
      case PosSystemType.shopifyPos:
        headers['X-Shopify-Access-Token'] = settings.accessToken ?? '';
        break;
      case PosSystemType.genericApi:
        headers['Authorization'] = 'Bearer ${settings.apiKey}';
        headers['X-API-Key'] = settings.apiKey;
        break;
    }

    return headers;
  }

  // Format order data according to POS system requirements
  static Map<String, dynamic> _formatOrderForPos(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) {
    switch (settings.systemType) {
      case PosSystemType.square:
        return _formatForSquare(orderData, settings);
      case PosSystemType.toast:
        return _formatForToast(orderData, settings);
      case PosSystemType.clover:
        return _formatForClover(orderData, settings);
      case PosSystemType.shopifyPos:
        return _formatForShopify(orderData, settings);
      case PosSystemType.genericApi:
      default:
        return _formatForGenericApi(orderData, settings);
    }
  }

  // Square POS format
  static Map<String, dynamic> _formatForSquare(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) {
    return {
      'location_id': settings.locationId,
      'order': {
        'state': 'OPEN',
        'line_items': orderData['items']
            ?.map((item) => {
                  'name': item['name'],
                  'quantity': item['quantity'].toString(),
                  'base_price_money': {
                    'amount': (item['price'] * 100).round(), // Convert to cents
                    'currency': 'KWD',
                  },
                })
            ?.toList(),
        'fulfillments': [
          {
            'type': 'PICKUP',
            'state': 'PROPOSED',
            'pickup_details': {
              'recipient': {
                'display_name': orderData['customerName'],
              },
              'pickup_at': DateTime.now()
                  .add(const Duration(minutes: 30))
                  .toIso8601String(),
            },
          }
        ],
      },
    };
  }

  // Toast POS format
  static Map<String, dynamic> _formatForToast(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) {
    return {
      'restaurantExternalId': settings.locationId,
      'order': {
        'externalId': orderData['id'],
        'orderNumber': orderData['id'],
        'customer': {
          'firstName': orderData['customerName']?.split(' ').first ?? '',
          'lastName':
              orderData['customerName']?.split(' ').skip(1).join(' ') ?? '',
          'phone': orderData['customerPhone'],
        },
        'selections': orderData['items']
            ?.map((item) => {
                  'itemId': item['id'],
                  'quantity': item['quantity'],
                  'unitPrice': item['price'],
                })
            ?.toList(),
        'requiredTime':
            DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
      },
    };
  }

  // Clover POS format
  static Map<String, dynamic> _formatForClover(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) {
    return {
      'merchantId': settings.locationId,
      'state': 'open',
      'lineItems': orderData['items']
          ?.map((item) => {
                'name': item['name'],
                'price': (item['price'] * 100).round(), // Convert to cents
                'quantity': item['quantity'],
              })
          ?.toList(),
      'customer': {
        'name': orderData['customerName'],
        'phoneNumber': orderData['customerPhone'],
      },
    };
  }

  // Shopify POS format
  static Map<String, dynamic> _formatForShopify(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) {
    return {
      'order': {
        'line_items': orderData['items']
            ?.map((item) => {
                  'title': item['name'],
                  'quantity': item['quantity'],
                  'price': item['price'].toString(),
                })
            ?.toList(),
        'customer': {
          'first_name': orderData['customerName']?.split(' ').first ?? '',
          'last_name':
              orderData['customerName']?.split(' ').skip(1).join(' ') ?? '',
          'phone': orderData['customerPhone'],
        },
        'fulfillment_status': 'pending',
        'financial_status': 'pending',
      },
    };
  }

  // Generic API format
  static Map<String, dynamic> _formatForGenericApi(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) {
    return {
      'orderId': orderData['id'],
      'customerName': orderData['customerName'],
      'customerPhone': orderData['customerPhone'],
      'items': orderData['items'],
      'totalAmount': orderData['totalAmount'],
      'orderTime': orderData['createdAt'],
      'notes': orderData['notes'],
    };
  }

  // Get system type display name
  static String getSystemTypeName(PosSystemType type) {
    switch (type) {
      case PosSystemType.square:
        return 'Square';
      case PosSystemType.toast:
        return 'Toast';
      case PosSystemType.clover:
        return 'Clover';
      case PosSystemType.shopifyPos:
        return 'Shopify POS';
      case PosSystemType.genericApi:
        return 'Generic API';
    }
  }

  // Validate API endpoint URL
  static bool isValidApiEndpoint(String endpoint) {
    if (endpoint.isEmpty) return false;
    try {
      final uri = Uri.parse(endpoint);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
