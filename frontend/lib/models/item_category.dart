
import 'dish.dart';

class ItemCategory {
  final String id;
  final String name;
  final String businessId;
  List<Dish> items;

  ItemCategory({
    required this.id,
    required this.name,
    required this.businessId,
    required this.items,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<Dish> items = itemsList.map((i) => Dish.fromJson(i)).toList();
    
    return ItemCategory(
      id: json['id'],
      name: json['name'],
      businessId: json['business_id'],
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'business_id': businessId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
