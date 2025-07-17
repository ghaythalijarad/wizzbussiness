// Business model implementation

import 'business_type.dart';
import 'discount.dart';
import 'offer.dart';
import 'order_item.dart';

class Business {
  final String id;
  String name;
  String email;
  String? ownerName;
  String? phone;
  String? address;
  double? latitude;
  double? longitude;
  String? description;
  String? website;
  String? businessPhotoUrl; // Added business photo URL field
  final List<Offer> offers;
  final Map<String, String> businessHours;
  final Map<String, dynamic> settings;
  final BusinessType businessType;

  Business({
    required this.id,
    required this.name,
    this.email = '',
    this.ownerName,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.website,
    this.businessPhotoUrl, // Added business photo URL parameter
    required this.offers,
    required this.businessHours,
    required this.settings,
    required this.businessType,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    // Helper to safely extract address components
    dynamic addressData = json['address'];
    String street = '';
    double? lat, lon;

    if (addressData is Map<String, dynamic>) {
      street = addressData['street'] ?? '';
      lat = (addressData['latitude'] as num?)?.toDouble();
      lon = (addressData['longitude'] as num?)?.toDouble();
    } else if (addressData is String) {
      street = addressData;
    }

    // Debug logging for business ID extraction
    print('Business.fromJson: Full JSON data: $json');
    final businessId = json['businessId'] ?? json['id'] ?? json['business_id'];
    print('Business.fromJson: Extracted business ID: $businessId');

    // Validate business ID
    if (businessId == null || businessId.toString().isEmpty) {
      print('Business.fromJson: WARNING - No valid business ID found in JSON');
      print('Business.fromJson: Available keys: ${json.keys.toList()}');
      throw Exception(
          'Invalid business data: Missing business ID. Available keys: ${json.keys.toList()}');
    }

    return Business(
      id: businessId.toString(),
      name: json['businessName'] ??
          json['name'] ??
          json['business_name'] ??
          'Unknown Business',
      email: json['email'] ?? '',
      ownerName: json['ownerName'] ?? json['owner_name'],
      phone: json['phone_number'] ?? json['phone'],
      address: street,
      latitude: lat,
      longitude: lon,
      description: json['description'],
      website: json['website'],
      businessPhotoUrl: json['businessPhotoUrl'] ?? json['business_photo_url'], // Added business photo URL parsing
      offers: (json['offers'] as List<dynamic>?)
              ?.map((offerJson) => Offer.fromJson(offerJson))
              .toList() ??
          [],
      businessHours: Map<String, String>.from(json['businessHours'] ?? {}),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      businessType: _getBusinessTypeFromString(
          json['businessType'] ?? json['business_type']),
    );
  }

  static BusinessType _getBusinessTypeFromString(String? businessTypeString) {
    switch (businessTypeString?.toLowerCase().replaceAll(' ', '')) {
      case 'restaurant':
      case 'kitchen':
        return BusinessType.kitchen;
      case 'cloudkitchen':
        return BusinessType.cloudkitchen;
      case 'store':
        return BusinessType.store;
      case 'pharmacy':
        return BusinessType.pharmacy;
      case 'caffe':
      case 'cafe':
        return BusinessType.caffe;
      default:
        return BusinessType.kitchen; // Default fallback
    }
  }

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
    String? businessPhotoUrl, // Added business photo URL parameter
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
    if (businessPhotoUrl != null) this.businessPhotoUrl = businessPhotoUrl; // Added business photo URL update
  }

  void updateSettings(String category, String key, dynamic value) {
    // Implement settings update logic
  }

  void updateBusinessHours(String day, String hours) {
    // Implement business hours update logic
  }

  List<Discount> get discounts {
    // Implement discounts retrieval logic
    return [];
  }

  void addDiscount(Discount discount) {
    // Implement add discount logic
  }

  void updateDiscount(Discount discount) {
    // Implement update discount logic
  }

  void removeDiscount(String discountId) {
    // Implement remove discount logic
  }

  double calculateOrderDiscount(double orderTotal, List<OrderItem> items) {
    return 0.0;
  }
}
