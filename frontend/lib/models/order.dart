// Models for orders in Hadhir Business app

import 'order_item.dart';
import 'delivery_address.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  onTheWay,
  delivered,
  cancelled,
  returned,
  expired
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final DeliveryAddress deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime createdAt;
  OrderStatus status;
  final String? notes;
  final int? estimatedPreparationTimeMinutes;
  final DateTime? estimatedCompletionTime;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.status = OrderStatus.pending,
    this.notes,
    this.estimatedPreparationTimeMinutes,
    this.estimatedCompletionTime,
  });

  /// Create an Order from JSON response from backend
  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse status from string
    OrderStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'pending':
          return OrderStatus.pending;
        case 'confirmed':
        case 'accepted':
          return OrderStatus.confirmed;
        case 'preparing':
          return OrderStatus.preparing;
        case 'ready':
          return OrderStatus.ready;
        case 'on_the_way':
        case 'ontheway':
        case 'on-the-way':
          return OrderStatus.onTheWay;
        case 'delivered':
        case 'pickedup':
        case 'picked_up':
          return OrderStatus.delivered;
        case 'cancelled':
          return OrderStatus.cancelled;
        case 'returned':
          return OrderStatus.returned;
        case 'expired':
          return OrderStatus.expired;
        default:
          return OrderStatus.pending;
      }
    }

    // Parse items from JSON
    List<OrderItem> parseItems(dynamic itemsData) {
      if (itemsData == null) return [];
      if (itemsData is List) {
        return itemsData.map((item) {
          if (item is Map<String, dynamic>) {
            return OrderItem(
              dishId: item['dishId'] ?? item['dish_id'] ?? '',
              dishName:
                  item['dishName'] ?? item['dish_name'] ?? item['name'] ?? '',
              price: (item['price'] ?? 0).toDouble(),
              quantity: item['quantity'] ?? 1,
              notes: item['notes'],
            );
          }
          return OrderItem(
            dishId: '',
            dishName: 'Unknown Item',
            price: 0.0,
            quantity: 1,
          );
        }).toList();
      }
      return [];
    }

    final deliveryAddressData =
        json['deliveryAddress'] ?? json['delivery_address'];
    final DeliveryAddress deliveryAddress;
    if (deliveryAddressData is Map<String, dynamic>) {
      deliveryAddress = DeliveryAddress.fromJson(deliveryAddressData);
    } else if (deliveryAddressData is String) {
      deliveryAddress = DeliveryAddress(street: deliveryAddressData, city: '');
    } else {
      deliveryAddress = DeliveryAddress(street: 'N/A', city: 'N/A');
    }

    final order = Order(
      id: json['orderId'] ?? json['id'] ?? '',
      customerId: json['customerId'] ?? json['customer_id'] ?? '',
      customerName: json['customerName'] ?? json['customer_name'] ?? '',
      customerPhone: json['customerPhone'] ?? json['customer_phone'] ?? '',
      deliveryAddress: deliveryAddress,
      items: parseItems(json['items']),
      totalAmount:
          (json['totalAmount'] ?? json['total_amount'] ?? 0).toDouble(),
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
      status: parseStatus(json['status']),
      notes: json['notes'],
      estimatedPreparationTimeMinutes: json['estimatedPreparationTime'] ??
          json['estimated_preparation_time'],
      estimatedCompletionTime: json['estimatedCompletionTime'] != null
          ? DateTime.tryParse(json['estimatedCompletionTime'])
          : null,
    );

    return order;
  }

  double get subtotal =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get deliveryFee => 5.0; // Fixed delivery fee
  double get tax => subtotal * 0.1; // 10% tax

  static int calculateEstimatedPreparationTime({
    required String businessType,
    required List<OrderItem> items,
    required double totalAmount,
  }) {
    int baseTime;
    int complexityTime;

    switch (businessType.toLowerCase()) {
      case 'kitchen':
        baseTime = 25;
        complexityTime = items.length * 4;
        break;
      case 'cloudkitchen':
      case 'cloud kitchen':
        baseTime = 20;
        complexityTime = items.length * 3;
        break;
      case 'store':
        baseTime = 10;
        complexityTime = items.length * 2;
        break;
      case 'pharmacy':
        baseTime = 15;
        complexityTime = items.length * 2;
        break;
      case 'caffe':
      case 'cafe':
        baseTime = 18;
        complexityTime = items.length * 3;
        break;
      default:
        baseTime = 20;
        complexityTime = items.length * 3;
    }

    if (totalAmount > 50) complexityTime += 5;
    if (totalAmount > 100) complexityTime += 10;

    int totalTime = baseTime + complexityTime;
    return ((totalTime + 4) ~/ 5) * 5;
  }

  DateTime getEstimatedCompletionTime() {
    if (estimatedCompletionTime != null) {
      return estimatedCompletionTime!;
    }
    final prepTime = estimatedPreparationTimeMinutes ?? 15;
    return createdAt.add(Duration(minutes: prepTime));
  }

  Duration? getRemainingTime() {
    if (status == OrderStatus.delivered || status == OrderStatus.cancelled) {
      return null;
    }
    final remaining = getEstimatedCompletionTime().difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isOverdue {
    if (status == OrderStatus.delivered || status == OrderStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(getEstimatedCompletionTime());
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    DeliveryAddress? deliveryAddress,
    List<OrderItem>? items,
    double? totalAmount,
    DateTime? createdAt,
    OrderStatus? status,
    String? notes,
    int? estimatedPreparationTimeMinutes,
    DateTime? estimatedCompletionTime,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      estimatedPreparationTimeMinutes: estimatedPreparationTimeMinutes ??
          this.estimatedPreparationTimeMinutes,
      estimatedCompletionTime:
          estimatedCompletionTime ?? this.estimatedCompletionTime,
    );
  }
}
