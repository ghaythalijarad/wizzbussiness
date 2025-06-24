class Item {
  final String id;
  String name;
  String? description;
  double price;
  String? imageUrl;
  bool isAvailable;
  String? category;
  String? sku;
  bool? requiresPrescription;

  Item({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.category,
    this.sku,
    this.requiresPrescription,
  });
}
