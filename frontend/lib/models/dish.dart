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
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      categoryId: json['category_id'] ?? '',
      isAvailable: json['is_available'] ?? true,
      imageUrl: json['images'] != null && json['images'].isNotEmpty
          ? json['images'][0]
          : json['thumbnail'],
      businessId: json['business_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category_id': categoryId,
      'is_available': isAvailable,
      'images': imageUrl != null ? [imageUrl] : [],
      'item_type': 'dish',
      'track_inventory': false,
    };
  }
}
