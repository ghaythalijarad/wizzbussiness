enum BusinessType { restaurant, cloudKitchen, pharmacy, store }

class Business {
  String id;
  String name;
  String email;
  String? phone;
  String? ownerName;
  BusinessType businessType;
  String? address;
  String? city;
  String? district;
  String? street;
  String? country;
  double? latitude;
  double? longitude;
  String? description;
  String? website;
  String? businessPhotoUrl;
  String status;
  DateTime? createdAt;
  DateTime? updatedAt;

  Business({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.ownerName,
    required this.businessType,
    this.address,
    this.city,
    this.district,
    this.street,
    this.country,
    this.latitude,
    this.longitude,
    this.description,
    this.website,
    this.businessPhotoUrl,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    // Parse address components
    final addressData = _parseAddressComponents(json['address']);
    
    return Business(
      id: json['businessId'] ?? json['id'] ?? '',
      name: json['businessName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phoneNumber'] ?? json['phone'] ?? json['phone_number'],
      ownerName: json['ownerName'] ?? json['owner_name'],
      businessType: _parseBusinessType(
          json['businessType'] ?? json['business_type'] ?? 'restaurant'),
      address: addressData['fullAddress'],
      city: addressData['city'],
      district: addressData['district'],
      street: addressData['street'],
      country: addressData['country'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      description: json['description'],
      website: json['website'],
      businessPhotoUrl: json['businessPhotoUrl'] ?? json['business_photo_url'],
      status: json['status'] ?? 'pending',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  static BusinessType _parseBusinessType(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return BusinessType.restaurant;
      case 'cloudkitchen':
      case 'cloud_kitchen':
        return BusinessType.cloudKitchen;
      case 'pharmacy':
        return BusinessType.pharmacy;
      case 'store':
        return BusinessType.store;
      default:
        return BusinessType.restaurant;
    }
  }

  static Map<String, String?> _parseAddressComponents(dynamic address) {
    final result = {
      'fullAddress': null as String?,
      'city': null as String?,
      'district': null as String?,
      'street': null as String?,
      'country': null as String?,
    };
    
    if (address == null) return result;
    
    // If it's already a string, return it as full address
    if (address is String) {
      result['fullAddress'] = address;
      return result;
    }
    
    // If it's a complex object (like from DynamoDB), extract components
    if (address is Map<String, dynamic>) {
      // Handle DynamoDB format with nested maps like { "S": "value" }
      String extractValue(dynamic value) {
        if (value is String) return value;
        if (value is Map<String, dynamic> && value.containsKey('S')) {
          return value['S']?.toString() ?? '';
        }
        return value?.toString() ?? '';
      }

      final street = extractValue(address['street']);
      final district = extractValue(address['district']);
      final city = extractValue(address['city']);
      final country = extractValue(address['country']);

      // Store individual components
      result['street'] = street.isNotEmpty ? street : null;
      result['district'] = district.isNotEmpty ? district : null;
      result['city'] = city.isNotEmpty ? city : null;
      result['country'] = country.isNotEmpty ? country : null;

      // Build full address string from components
      final parts = <String>[];
      if (street.isNotEmpty) parts.add(street);
      if (district.isNotEmpty) parts.add(district);
      if (city.isNotEmpty) parts.add(city);
      if (country.isNotEmpty) parts.add(country);

      result['fullAddress'] = parts.isNotEmpty ? parts.join(', ') : null;
      return result;
    }

    // Fallback: convert to string
    result['fullAddress'] = address.toString();
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': id,
      'businessName': name,
      'email': email,
      'phoneNumber': phone,
      'ownerName': ownerName,
      'businessType': businessType.name,
      'address': address,
      'city': city,
      'district': district,
      'street': street,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'website': website,
      'businessPhotoUrl': businessPhotoUrl,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  void updateProfile({
    String? name,
    String? ownerName,
    String? phone,
    String? address,
    String? city,
    String? district,
    String? street,
    String? country,
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
    if (city != null) this.city = city;
    if (district != null) this.district = district;
    if (street != null) this.street = street;
    if (country != null) this.country = country;
    if (latitude != null) this.latitude = latitude;
    if (longitude != null) this.longitude = longitude;
    if (email != null) this.email = email;
    if (description != null) this.description = description;
    if (website != null) this.website = website;
    if (businessPhotoUrl != null) this.businessPhotoUrl = businessPhotoUrl;
    updatedAt = DateTime.now();
  }

  Business copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? ownerName,
    BusinessType? businessType,
    String? address,
    String? city,
    String? district,
    String? street,
    String? country,
    double? latitude,
    double? longitude,
    String? description,
    String? website,
    String? businessPhotoUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      ownerName: ownerName ?? this.ownerName,
      businessType: businessType ?? this.businessType,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      street: street ?? this.street,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      website: website ?? this.website,
      businessPhotoUrl: businessPhotoUrl ?? this.businessPhotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Business(id: $id, name: $name, email: $email, businessType: $businessType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Business && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
