// Models for orders in Hadhir Business app

import 'order_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  pickedUp,
  cancelled,
  returned,
  expired
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
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
    if (status == OrderStatus.pickedUp || status == OrderStatus.cancelled) {
      return null;
    }
    final remaining = getEstimatedCompletionTime().difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isOverdue {
    if (status == OrderStatus.pickedUp || status == OrderStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(getEstimatedCompletionTime());
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
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
