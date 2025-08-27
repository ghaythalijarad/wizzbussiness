import 'dart:convert';

// Test with actual data from DynamoDB
void main() {
  print('🔍 Testing Street Field Mapping...');

  // Test with the actual business data from DynamoDB
  print('\n=== Test: Actual Business Data from DynamoDB ===');
  final actualData = {
    'businessId': 'business_1756220656049_ee98qktepks',
    'businessName': 'فتوش',
    'email': 'g87_a@yahoo.com',
    'city': 'النجف',
    'district': 'الجمعية',
    'street': 'شارع الصناعة',
    'country': 'Iraq',
    'address': 'شارع الصناعة, الجمعية, النجف, Iraq',
    'latitude': 24.7136,
    'longitude': 46.6753,
    'status': 'approved',
  };

  print('Raw data - street field: "${actualData['street']}"');
  print('Raw data - city field: "${actualData['city']}"');
  print('Raw data - district field: "${actualData['district']}"');

  // Test parsing with our Business model logic
  final addressData = _parseAddressComponents(actualData['address']);
  print('\nParsed address components:');
  print('  Street from address: ${addressData['street']}');
  print('  City from address: ${addressData['city']}');
  print('  District from address: ${addressData['district']}');

  // Test the full Business fromJson logic
  final street = actualData['street'] ?? addressData['street'];
  final city = actualData['city'] ?? addressData['city'];
  final district = actualData['district'] ?? addressData['district'];
  final country = actualData['country'] ?? addressData['country'];

  print('\nFinal mapped values:');
  print('  Street: "$street"');
  print('  City: "$city"');
  print('  District: "$district"');
  print('  Country: "$country"');

  print('\n✅ Street Field Mapping Test Completed');
}

// Copy of the address parsing logic from Business model
Map<String, String?> _parseAddressComponents(dynamic address) {
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
