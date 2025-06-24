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
  int? timeoutSeconds;
  int? retryAttempts;
  bool? testMode;

  PosSettings({
    this.enabled = false,
    this.autoSendOrders = false,
    this.systemType = PosSystemType.genericApi,
    this.apiEndpoint = '',
    this.apiKey = '',
    this.accessToken,
    this.locationId,
    this.timeoutSeconds = 30,
    this.retryAttempts = 3,
    this.testMode = false,
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
      'timeoutSeconds': timeoutSeconds,
      'retryAttempts': retryAttempts,
      'testMode': testMode,
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
      timeoutSeconds: json['timeoutSeconds'] ?? 30,
      retryAttempts: json['retryAttempts'] ?? 3,
      testMode: json['testMode'] ?? false,
    );
  }
}

class PosService {
  static String getSystemTypeName(PosSystemType type) {
    switch (type) {
      case PosSystemType.square:
        return 'Square';
      case PosSystemType.toast:
        return 'Toast POS';
      case PosSystemType.clover:
        return 'Clover';
      case PosSystemType.shopifyPos:
        return 'Shopify POS';
      case PosSystemType.genericApi:
        return 'Generic API';
    }
  }

  static bool isValidApiEndpoint(String endpoint) {
    if (endpoint.isEmpty) return false;

    try {
      final uri = Uri.parse(endpoint);
      if (!uri.isAbsolute) {
        return false;
      }
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  // Send order to POS system
  static Future<bool> sendOrderToPos(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) async {
    if (!settings.enabled) return false;

    try {
      final uri = Uri.parse(settings.apiEndpoint);
      if (!uri.isAbsolute) {
        return false;
      }

      final headers = _buildHeaders(settings);
      final formattedData = _formatOrderForPos(orderData, settings);

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(formattedData),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error sending order to POS: $e');
      return false;
    }
  }

  // Build authentication headers for each POS system
  static Map<String, String> _buildHeaders(PosSettings settings) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

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
                  'item': {
                    'name': item['name'],
                  },
                  'quantity': item['quantity'],
                  'unitPrice': item['price'],
                })
            ?.toList(),
      },
    };
  }

  // Clover POS format
  static Map<String, dynamic> _formatForClover(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) {
    return {
      'note': 'Order from mobile app',
      'lineItems': orderData['items']
          ?.map((item) => {
                'name': item['name'],
                'unitQty': item['quantity'],
                'price': (item['price'] * 100).round(), // Convert to cents
              })
          ?.toList(),
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
        'financial_status': 'pending',
        'fulfillment_status': null,
      },
    };
  }

  // Generic API format
  static Map<String, dynamic> _formatForGenericApi(
    Map<String, dynamic> orderData,
    PosSettings settings,
  ) {
    // Keep the original format for generic APIs
    return orderData;
  }

  // Test connection to POS system
  static Future<bool> testConnection(PosSettings settings) async {
    if (settings.apiEndpoint.isEmpty || settings.apiKey.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse('${settings.apiEndpoint}/health');
      final headers = _buildHeaders(settings);

      final response = await http.get(uri, headers: headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
