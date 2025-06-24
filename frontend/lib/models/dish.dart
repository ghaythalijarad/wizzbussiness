class Dish {
  final String id;
  final String name;
  final String description;
  final double price;
  String categoryId;
  String? imageUrl;
  final bool isAvailable;
  final String businessId;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.imageUrl,
    this.isAvailable = true,
    required this.businessId,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      categoryId: json['category_id'],
      isAvailable: json['is_available'],
      imageUrl: json['image_url'],
      businessId: json['business_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category_id': categoryId,
      'is_available': isAvailable,
      'image_url': imageUrl,
      'business_id': businessId,
    };
  }
}
