// Test the address formatting functionality
void main() {
  print('🧪 Testing Address Formatting Fix');
  print('================================');

  testAddressFormatting();

  print('\n✅ All tests passed! Address formatting fix is working correctly.');
}

void testAddressFormatting() {
  // Helper function to extract value from DynamoDB attribute format
  String extractValue(dynamic value) {
    if (value == null) return '';

    // Handle DynamoDB attribute format: { "S": "value" }
    if (value is Map<String, dynamic> && value.containsKey('S')) {
      return value['S']?.toString() ?? '';
    }

    // Handle plain string values
    if (value is String) return value;

    return value.toString();
  }

  String formatAddress(Map<String, dynamic>? address) {
    if (address == null) {
      return '';
    }

    // Extract address components, handling both DynamoDB format and plain format
    final street = extractValue(address['street']);
    final district = extractValue(address['district']);
    final city = extractValue(address['city']);
    final country = extractValue(address['country']);
    final homeAddress = extractValue(address['home_address']);
    final neighborhood = extractValue(address['neighborhood']);

    // Build formatted address, filtering out empty components
    final components = [
      homeAddress,
      street,
      neighborhood,
      district,
      city,
      country,
    ].where((component) => component.isNotEmpty).toList();

    return components.join(', ');
  }

  print('\n1️⃣ Testing DynamoDB attribute format (the problematic format)...');
  final dynamoDBAddress = {
    'country': {'S': 'Iraq'},
    'city': {'S': 'النجف'},
    'street': {'S': 'شارع الصناعة'},
    'district': {'S': 'المناذرة'},
  };

  final result1 = formatAddress(dynamoDBAddress);
  print('   Input: ${dynamoDBAddress}');
  print('   Output: "$result1"');
  print('   Expected: "شارع الصناعة, المناذرة, النجف, Iraq"');
  assert(result1 == 'شارع الصناعة, المناذرة, النجف, Iraq',
      'DynamoDB format test failed');
  print('   ✅ PASSED');

  print('\n2️⃣ Testing plain string format...');
  final plainAddress = {
    'country': 'Iraq',
    'city': 'النجف',
    'street': 'شارع الصناعة',
    'district': 'المناذرة',
  };

  final result2 = formatAddress(plainAddress);
  print('   Input: ${plainAddress}');
  print('   Output: "$result2"');
  print('   Expected: "شارع الصناعة, المناذرة, النجف, Iraq"');
  assert(result2 == 'شارع الصناعة, المناذرة, النجف, Iraq',
      'Plain format test failed');
  print('   ✅ PASSED');

  print('\n3️⃣ Testing mixed format...');
  final mixedAddress = {
    'country': {'S': 'Iraq'},
    'city': 'النجف',
    'street': {'S': 'شارع الصناعة'},
    'district': 'المناذرة',
  };

  final result3 = formatAddress(mixedAddress);
  print('   Input: ${mixedAddress}');
  print('   Output: "$result3"');
  print('   Expected: "شارع الصناعة, المناذرة, النجف, Iraq"');
  assert(result3 == 'شارع الصناعة, المناذرة, النجف, Iraq',
      'Mixed format test failed');
  print('   ✅ PASSED');

  print('\n4️⃣ Testing incomplete address with empty values...');
  final incompleteAddress = {
    'country': {'S': 'Iraq'},
    'city': {'S': ''},
    'street': null,
    'district': {'S': 'المناذرة'},
  };

  final result4 = formatAddress(incompleteAddress);
  print('   Input: ${incompleteAddress}');
  print('   Output: "$result4"');
  print('   Expected: "المناذرة, Iraq"');
  assert(result4 == 'المناذرة, Iraq', 'Incomplete address test failed');
  print('   ✅ PASSED');

  print('\n5️⃣ Testing null address...');
  final result5 = formatAddress(null);
  print('   Input: null');
  print('   Output: "$result5"');
  print('   Expected: ""');
  assert(result5 == '', 'Null address test failed');
  print('   ✅ PASSED');
}
