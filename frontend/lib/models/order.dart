import 'delivery_address.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready, 
  completed,
  cancelled,
  expired,
  onTheWay,
  delivered,
  returned,
}

class OrderItem {
  String id;
  String name;
  double price;
  int quantity;
  String? notes;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
    };
  }

  double get totalPrice => price * quantity;
}

class Order {
  String id;
  String businessId;
  String customerId;
  String customerName;
  String? customerPhone;
  String? customerAddress;
  DeliveryAddress? deliveryAddress;
  List<OrderItem> items;
  double totalAmount;
  OrderStatus status;
  DateTime createdAt;
  DateTime? updatedAt;
  String? notes;

  Order({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      customerId: json['customerId'] ?? json['customer_id'] ?? 'unknown',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      customerAddress: json['customerAddress'],
      deliveryAddress: json['deliveryAddress'] != null ? DeliveryAddress.fromJson(json['deliveryAddress']) : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: _parseOrderStatus(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      notes: json['notes'],
    );
  }

  static OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'ontheway':
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'completed':
        return OrderStatus.completed;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  Order copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  bool shouldAutoReject() {
    // Auto-reject orders that are older than 30 minutes
    final now = DateTime.now();
    final orderAge = now.difference(createdAt);
    return orderAge.inMinutes > 30;
  }

  @override
  String toString() {
    return 'Order(id: $id, customerName: $customerName, status: $status, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
