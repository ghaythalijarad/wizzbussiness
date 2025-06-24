import '../business.dart';
import '../business_type.dart';
import '../discount.dart';
import '../offer.dart';
import '../order_item.dart';

class Store implements Business {
  @override
  final String id;
  @override
  String name;
  @override
  String email;
  @override
  String? ownerName;
  @override
  String? phone;
  @override
  String? address;
  @override
  double? latitude;
  @override
  double? longitude;
  @override
  String? description;
  @override
  String? website;

  @override
  final List<Offer> offers;
  @override
  final Map<String, String> businessHours;
  @override
  final Map<String, dynamic> settings;
  @override
  final BusinessType businessType;
  @override
  final List<Discount> discounts;

  Store({
    required this.id,
    required this.name,
    required this.email,
    this.ownerName,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.website,
    required this.offers,
    required this.businessHours,
    required this.settings,
    required this.businessType,
    required this.discounts,
  });

  @override
  void updateProfile({
    String? name,
    String? ownerName,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? email,
    String? description,
    String? website,
  }) {
    if (name != null) this.name = name;
    if (ownerName != null) this.ownerName = ownerName;
    if (phone != null) this.phone = phone;
    if (address != null) this.address = address;
    if (latitude != null) this.latitude = latitude;
    if (longitude != null) this.longitude = longitude;
    if (email != null) this.email = email;
    if (description != null) this.description = description;
    if (website != null) this.website = website;
  }

  @override
  void updateSettings(String category, String key, dynamic value) {
    if (settings[category] != null) {
      settings[category][key] = value;
    }
  }

  @override
  void updateBusinessHours(String day, String hours) {
    businessHours[day] = hours;
  }

  @override
  void addDiscount(Discount discount) {
    discounts.add(discount);
  }

  @override
  void updateDiscount(Discount discount) {
    final index = discounts.indexWhere((d) => d.id == discount.id);
    if (index != -1) {
      discounts[index] = discount;
    }
  }

  @override
  void removeDiscount(String discountId) {
    discounts.removeWhere((d) => d.id == discountId);
  }

  void toggleDiscountStatus(String discountId) {
    final index = discounts.indexWhere((d) => d.id == discountId);
    if (index != -1) {
      final discount = discounts[index];
      final newStatus = discount.status == DiscountStatus.active
          ? DiscountStatus.paused
          : DiscountStatus.active;
      discounts[index] = discount.copyWith(status: newStatus);
    }
  }

  List<Discount> getActiveDiscounts() {
    return discounts.where((discount) => discount.isActive).toList();
  }

  @override
  double calculateOrderDiscount(double orderTotal, List<OrderItem> items) {
    double totalDiscount = 0.0;
    final activeDiscounts = getActiveDiscounts();

    for (final discount in activeDiscounts) {
      totalDiscount +=
          _calculateDiscountWithCategoryMapping(discount, orderTotal, items);
    }

    return totalDiscount;
  }

  double _calculateDiscountWithCategoryMapping(
      Discount discount, double orderTotal, List<OrderItem> items) {
    if (!discount.isActive) return 0.0;

    if (orderTotal < discount.minimumOrderAmount) return 0.0;

    double discountableAmount = 0.0;

    switch (discount.applicability) {
      case DiscountApplicability.allItems:
        discountableAmount = orderTotal;
        break;
      case DiscountApplicability.specificItems:
        for (final item in items) {
          if (discount.applicableItemIds.contains(item.dishId)) {
            discountableAmount += item.price * item.quantity;
          }
        }
        break;
      case DiscountApplicability.specificCategories:
        for (final item in items) {
          // For simplified implementation, we'll treat all items as eligible
          // In a real app, you'd need a way to map dishId to categoryId
          if (discount.applicableCategoryIds.isNotEmpty) {
            discountableAmount += item.price * item.quantity;
          }
        }
        break;
      case DiscountApplicability.minimumOrder:
        discountableAmount = orderTotal;
        break;
    }

    if (discount.type == DiscountType.percentage) {
      return discountableAmount * (discount.value / 100);
    } else {
      return discount.value.clamp(0.0, discountableAmount);
    }
  }
}
