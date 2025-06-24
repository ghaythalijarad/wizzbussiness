// filepath: /Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/models/businesses/pharmacy.dart
import '../business.dart';
import '../business_type.dart';
import '../discount.dart';
import '../offer.dart';
import '../order_item.dart';

class Pharmacy implements Business {
  @override
  final String id;
  @override
  String name;
  @override
  String email;
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
  String? ownerName;

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

  Pharmacy({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.website,
    this.ownerName,
    required this.offers,
    required this.businessHours,
    required this.settings,
    required this.businessType,
    required this.discounts,
  });

  @override
  void updateProfile({
    String? name,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? email,
    String? description,
    String? website,
    String? ownerName,
  }) {
    if (name != null) this.name = name;
    if (phone != null) this.phone = phone;
    if (address != null) this.address = address;
    if (latitude != null) this.latitude = latitude;
    if (longitude != null) this.longitude = longitude;
    if (email != null) this.email = email;
    if (description != null) this.description = description;
    if (website != null) this.website = website;
    if (ownerName != null) this.ownerName = ownerName;
  }

  @override
  void updateSettings(String category, String key, dynamic value) {
    if (settings[category] != null) settings[category][key] = value;
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
    final i = discounts.indexWhere((d) => d.id == discount.id);
    if (i != -1) discounts[i] = discount;
  }

  @override
  void removeDiscount(String discountId) {
    discounts.removeWhere((d) => d.id == discountId);
  }

  void toggleDiscountStatus(String discountId) {
    final i = discounts.indexWhere((d) => d.id == discountId);
    if (i != -1) {
      final d = discounts[i];
      final s = d.status == DiscountStatus.active
          ? DiscountStatus.paused
          : DiscountStatus.active;
      discounts[i] = d.copyWith(status: s);
    }
  }

  List<Discount> getActiveDiscounts() =>
      discounts.where((d) => d.isActive).toList();

  double calculateOrderDiscount(double orderTotal, List<OrderItem> items) {
    double total = 0;
    for (final d in getActiveDiscounts()) {
      double amt = 0;
      switch (d.applicability) {
        case DiscountApplicability.allItems:
          amt = orderTotal;
          break;
        case DiscountApplicability.specificItems:
          for (final item in items) {
            if (d.applicableItemIds.contains(item.dishId)) {
              amt += item.price * item.quantity;
            }
          }
          break;
        case DiscountApplicability.specificCategories:
          // Note: Category-based discounts may need to be handled differently
          // without menu structure. For now, this returns 0 for category-based discounts.
          amt = 0;
          break;
        case DiscountApplicability.minimumOrder:
          amt = orderTotal;
          break;
      }
      total += d.type == DiscountType.percentage
          ? amt * (d.value / 100)
          : d.value.clamp(0, amt);
    }
    return total;
  }
}
