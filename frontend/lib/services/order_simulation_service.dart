import 'dart:math';
import 'api_service.dart';

class OrderSimulationService {
  final ApiService _apiService = ApiService();
  final Random _random = Random();

  // Sample customer names
  static const List<String> _customerNames = [
    'Ahmed Al-Rashid',
    'Fatima Hassan',
    'Mohammed Ali',
    'Sara Abdullah',
    'Omar Khalil'
  ];

  // Sample phone numbers
  static const List<String> _phoneNumbers = [
    '+971501234567',
    '+971502345678',
    '+971503456789'
  ];

  // Sample addresses
  static const List<String> _deliveryAddresses = [
    'Downtown Dubai, Burj Khalifa District, Tower 1, Apt 501',
    'Dubai Marina, Marina Walk, Building A, Floor 15',
    'Business Bay, Executive Towers, Tower B, Office 1205'
  ];

  // Sample dishes
  static const Map<String, double> _dishCatalog = {
    'Hummus with Pita': 25.0,
    'Chicken Shawarma Wrap': 45.0,
    'Grilled Chicken': 52.0,
    'Caesar Salad': 38.0,
    'Fresh Orange Juice': 18.0
  };

  Map<String, dynamic> generateOrderData(String businessId) {
    final customerName = _customerNames[_random.nextInt(_customerNames.length)];
    final customerPhone = _phoneNumbers[_random.nextInt(_phoneNumbers.length)];
    final deliveryAddress =
        _deliveryAddresses[_random.nextInt(_deliveryAddresses.length)];

    final itemCount = _random.nextInt(3) + 1;
    final List<Map<String, dynamic>> items = [];
    final dishNames = _dishCatalog.keys.toList();

    for (int i = 0; i < itemCount; i++) {
      final dishName = dishNames[_random.nextInt(dishNames.length)];
      final unitPrice = _dishCatalog[dishName]!;
      final quantity = _random.nextInt(2) + 1;
      final totalPrice = unitPrice * quantity;

      items.add({
        'item_id': 'sim_${_random.nextInt(1000)}',
        'item_name': dishName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'special_instructions': null,
      });
    }

    final subtotal = items.fold<double>(
        0.0, (sum, item) => sum + (item['total_price'] as double));
    final taxAmount = subtotal * 0.05;
    final deliveryFee = 10.0;
    final totalAmount = subtotal + taxAmount + deliveryFee;

    return {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email':
          '${customerName.toLowerCase().replaceAll(' ', '.')}@example.com',
      'customer_id': 'sim_customer_${_random.nextInt(10000)}',
      'items': items,
      'delivery_type': 'delivery',
      'delivery_address': {
        'street': deliveryAddress,
        'district': 'Dubai District',
        'city': 'Dubai',
        'country': 'UAE',
        'zip_code': '00000',
        'latitude': 25.2048,
        'longitude': 55.2708,
      },
      'delivery_notes': 'Please call when you arrive',
      'special_instructions': 'Handle with care',
      'payment_info': {
        'payment_method': 'cash_on_delivery',
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'delivery_fee': deliveryFee,
        'total_amount': totalAmount,
      }
    };
  }

  Future<Map<String, dynamic>> createSimulatedOrder(String businessId) async {
    final orderData = generateOrderData(businessId);
    return await _apiService.createOrder(businessId, orderData);
  }
}
