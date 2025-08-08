import '../business.dart';
import '../business_type.dart';
import '../discount.dart';
import '../offer.dart';
import '../order_item.dart';

class CloudKitchen implements Business {
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
  String? businessPhotoUrl;
  @override
  final String status;

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

  CloudKitchen({
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
    this.businessPhotoUrl,
    required this.status,
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
    String? businessPhotoUrl,
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
    if (businessPhotoUrl != null) this.businessPhotoUrl = businessPhotoUrl;
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

  @override
  double calculateOrderDiscount(double orderTotal, List<OrderItem> items) {
    double total = 0;
    for (final d in discounts.where((d) => d.isActive)) {
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
          amt = 0; // Category-based discounts need menu structure
          break;
        case DiscountApplicability.minimumOrder:
          amt = orderTotal;
          break;
      }
      total += d.type == DiscountType.percentage
          ? amt * (d.value / 100)
          : d.type == DiscountType.freeDelivery
              ? 0.0 // Free delivery handled separately
              : 0.0; // Other types require backend calculation
    }
    return total;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': id,
      'name': name,
      'businessName': name,
      'email': email,
      'ownerName': ownerName,
      'owner_name': ownerName,
      'phone': phone,
      'phone_number': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'website': website,
      'businessPhotoUrl': businessPhotoUrl,
      'business_photo_url': businessPhotoUrl,
      'status': status,
      'offers': offers.map((o) => o.toJson()).toList(),
      'businessHours': businessHours,
      'settings': settings,
      'businessType': businessType.toString().split('.').last,
      'business_type': businessType.toString().split('.').last,
    };
  }
}
