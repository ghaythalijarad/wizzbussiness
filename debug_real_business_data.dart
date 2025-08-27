void main() {
  print('🔍 Testing Real Business Data Structure...');

  // Test with data structure that matches what we see in the auth handler
  print('\n=== Test 1: Auth Handler Format ===');
  final authHandlerData = {
    'businessId': 'business_1756220656049_ee98qktepks',
    'businessName': 'فتوش',
    'email': 'g87_a@yahoo.com',
    'ownerId': '94585418-1021-7021-cd9e-6d9c8784a299',
    'cognitoUserId': '94585418-1021-7021-cd9e-6d9c8784a299',
    'status': 'approved',
    'businessType': 'restaurant',
    'address': 'شارع الصناعة, الجمعية, النجف, Iraq',
    'phoneNumber': '+9647812345678',
    'city': 'النجف',
    'district': 'الجمعية',
    'country': 'Iraq',
    // Note: no street field at top level
  };

  testBusinessParsing(authHandlerData, 'Auth Handler Format');

  print('\n=== Test 2: Full Database Format ===');
  final databaseData = {
    'businessId': 'business_1756220656049_ee98qktepks',
    'businessName': 'فتوش',
    'email': 'g87_a@yahoo.com',
    'ownerId': '94585418-1021-7021-cd9e-6d9c8784a299',
    'cognitoUserId': '94585418-1021-7021-cd9e-6d9c8784a299',
    'status': 'approved',
    'businessType': 'restaurant',
    'address': 'شارع الصناعة, الجمعية, النجف, Iraq',
    'phoneNumber': '+9647812345678',
    'city': 'النجف',
    'district': 'الجمعية',
    'street': 'شارع الصناعة', // Top-level street field
    'country': 'Iraq',
    'latitude': 24.7136,
    'longitude': 46.6753,
  };

  testBusinessParsing(databaseData, 'Full Database Format');

  print('\n=== Test 3: Location API Format ===');
  final locationApiData = {
    'settings': {
      'city': 'النجف',
      'district': 'الجمعية',
      'street': 'شارع الصناعة',
      'country': 'Iraq',
      'latitude': 24.7136,
      'longitude': 46.6753,
      'address': 'شارع الصناعة, الجمعية, النجف, Iraq',
    },
  };

  print('Location API Data:');
  print('  City: ${locationApiData['settings']?['city']}');
  print('  District: ${locationApiData['settings']?['district']}');
  print('  Street: ${locationApiData['settings']?['street']}');
  print('  Country: ${locationApiData['settings']?['country']}');
}

void testBusinessParsing(Map<String, dynamic> data, String testName) {
  print('Testing: $testName');

  // Direct field access (how the Business model works)
  final directCity = data['city'];
  final directDistrict = data['district'];
  final directStreet = data['street'];
  final directCountry = data['country'];

  print('  Direct access:');
  print('    City: $directCity');
  print('    District: $directDistrict');
  print('    Street: $directStreet');
  print('    Country: $directCountry');

  // Address parsing (fallback)
  final address = data['address'];
  print('  Address field: $address');

  // Check if street is missing and needs to be parsed from address
  if (directStreet == null && address != null) {
    print('  Street field missing - would need address parsing');
  } else if (directStreet != null) {
    print('  Street field present: $directStreet');
  }
}
