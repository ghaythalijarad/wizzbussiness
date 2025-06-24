/// Represents a single item within an order
class OrderItem {
  final String dishId;
  final String dishName;
  final double price;
  final int quantity;
  final String? notes;

  OrderItem({
    required this.dishId,
    required this.dishName,
    required this.price,
    required this.quantity,
    this.notes,
  });
}
