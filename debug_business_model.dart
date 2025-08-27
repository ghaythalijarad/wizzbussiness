import 'dart:convert';

// Copy of Business model for testing
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
        json['businessType'] ?? json['business_type'] ?? 'restaurant',
      ),
      address: json['address'] is String
          ? json['address']
          : addressData['fullAddress'],
      // Prioritize individual fields from JSON, fallback to parsed address components
      city: json['city'] ?? addressData['city'],
      district: json['district'] ?? addressData['district'],
      street: json['street'] ?? addressData['street'],
      country: json['country'] ?? addressData['country'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      description: json['description'],
      website: json['website'],
      businessPhotoUrl: json['businessPhotoUrl'] ?? json['business_photo_url'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
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
}

void main() {
  print('🧪 Testing Business Model Address Parsing...');

  // Test 1: Business with individual address fields (like in real database)
  print('\n=== Test 1: Individual Address Fields (Real DB Format) ===');
  final testData1 = {
    'businessId': 'business_1756220656049_ee98qktepks',
    'businessName': 'فتوش',
    'email': 'g87_a@yahoo.com',
    'city': 'النجف',
    'district': 'الجمعية',
    'street': 'شارع الصناعة',
    'country': 'Iraq',
    'latitude': 24.7136,
    'longitude': 46.6753,
    'address': 'شارع الصناعة, الجمعية, النجف, Iraq',
  };

  final business1 = Business.fromJson(testData1);
  print('City: ${business1.city}');
  print('District: ${business1.district}');
  print('Street: ${business1.street}');
  print('Country: ${business1.country}');
  print('Address: ${business1.address}');

  // Test 2: Business with individual address fields (English)
  print('\n=== Test 2: Individual Address Fields (English) ===');
  final testData2 = {
    'businessId': 'business_1756222089290_s94ullqqn8d',
    'businessName': 'Complete Document Test Business',
    'email': 'test-complete-docs-1756222087@example.com',
    'city': 'Baghdad',
    'district': 'Karrada',
    'street': '123 Test Street',
    'country': 'Iraq',
    'address': '123 Test Street, Karrada, Baghdad, Iraq',
  };

  final business2 = Business.fromJson(testData2);
  print('City: ${business2.city}');
  print('District: ${business2.district}');
  print('Street: ${business2.street}');
  print('Country: ${business2.country}');
  print('Address: ${business2.address}');

  // Test 3: Business with only address field (no individual fields)
  print('\n=== Test 3: Only Address Field ===');
  final testData3 = {
    'businessId': 'test-456',
    'businessName': 'Test Restaurant 3',
    'email': 'test3@example.com',
    'address': 'Al-Mansour Street, Al-Mansour, Baghdad, Iraq',
  };

  final business3 = Business.fromJson(testData3);
  print('City: ${business3.city}');
  print('District: ${business3.district}');
  print('Street: ${business3.street}');
  print('Country: ${business3.country}');
  print('Address: ${business3.address}');

  // Test 4: Business with empty individual fields but string address
  print('\n=== Test 4: Empty Individual Fields, String Address ===');
  final testData4 = {
    'businessId': 'business_1756230671495_lwppn8vnmwg',
    'businessName': 'Test',
    'email': 'test@example.com',
    'city': '',
    'district': '',
    'street': '',
    'country': 'Iraq',
    'address': 'Test Business Street, Test District, Baghdad, Iraq',
  };

  final business4 = Business.fromJson(testData4);
  print('City: ${business4.city}');
  print('District: ${business4.district}');
  print('Street: ${business4.street}');
  print('Country: ${business4.country}');
  print('Address: ${business4.address}');

  print('\n✅ Business Model Address Parsing Test Completed');
}
