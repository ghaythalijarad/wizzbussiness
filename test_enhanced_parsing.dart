void main() {
  print('🧪 Testing Enhanced Business Model Address Parsing...');

  // Test the string parsing enhancement
  print('\n=== Test: String Address Parsing ===');
  final testData = {
    'businessId': 'test-123',
    'businessName': 'Test Restaurant',
    'email': 'test@example.com',
    'city': 'Baghdad', // This should take priority
    'district': 'Karrada', // This should take priority
    'country': 'Iraq', // This should take priority
    // No street field provided
    'address':
        'شارع الصناعة, الجمعية, النجف, Iraq', // Street should be parsed from here
  };

  print('Input data:');
  print('  Individual city: ${testData['city']}');
  print('  Individual district: ${testData['district']}');
  print('  Individual street: ${testData['street']}');
  print('  Individual country: ${testData['country']}');
  print('  Address string: ${testData['address']}');

  // Simulate Business.fromJson logic
  final addressData = _parseAddressComponents(testData['address']);

  print('\nParsed address components:');
  print('  Parsed city: ${addressData['city']}');
  print('  Parsed district: ${addressData['district']}');
  print('  Parsed street: ${addressData['street']}');
  print('  Parsed country: ${addressData['country']}');

  // Final Business object values (with priority logic)
  final finalCity = testData['city'] ?? addressData['city'];
  final finalDistrict = testData['district'] ?? addressData['district'];
  final finalStreet = testData['street'] ?? addressData['street'];
  final finalCountry = testData['country'] ?? addressData['country'];

  print('\nFinal Business object values:');
  print('  Final city: $finalCity');
  print('  Final district: $finalDistrict');
  print('  Final street: $finalStreet');
  print('  Final country: $finalCountry');

  print('\n✅ Enhanced Address Parsing Test Completed');
}

Map<String, String?> _parseAddressComponents(dynamic address) {
  final result = {
    'fullAddress': null as String?,
    'city': null as String?,
    'district': null as String?,
    'street': null as String?,
    'country': null as String?,
  };

  if (address == null) return result;

  // If it's already a string, parse it intelligently
  if (address is String) {
    result['fullAddress'] = address;

    // Try to parse individual components from the string
    // Common format: "Street, District, City, Country"
    final parts = address.split(',').map((part) => part.trim()).toList();

    if (parts.length >= 1) {
      result['street'] = parts[0].isNotEmpty ? parts[0] : null;
    }
    if (parts.length >= 2) {
      result['district'] = parts[1].isNotEmpty ? parts[1] : null;
    }
    if (parts.length >= 3) {
      result['city'] = parts[2].isNotEmpty ? parts[2] : null;
    }
    if (parts.length >= 4) {
      result['country'] = parts[3].isNotEmpty ? parts[3] : null;
    }

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
