import 'dart:convert';

Order orderFromJson(String str) => Order.fromJson(json.decode(str));

String orderToJson(Order data) => json.encode(data.toJson());

class Order {
  final String id;
  final String businessId;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final String customerName;
  final String customerEmail;

  Order({
    required this.id,
    required this.businessId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json["id"],
        businessId: json["businessId"],
        items: List<OrderItem>.from(
            json["items"].map((x) => OrderItem.fromJson(x))),
        total: json["total"]?.toDouble(),
        status: json["status"],
        createdAt: DateTime.parse(json["createdAt"]),
        customerName: json["customerName"],
        customerEmail: json["customerEmail"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "businessId": businessId,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
        "total": total,
        "status": status,
        "createdAt": createdAt.toIso8601String(),
        "customerName": customerName,
        "customerEmail": customerEmail,
      };
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json["productId"],
        name: json["name"],
        quantity: json["quantity"],
        price: json["price"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "productId": productId,
        "name": name,
        "quantity": quantity,
        "price": price,
      };
}
