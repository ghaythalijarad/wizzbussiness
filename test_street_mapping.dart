void main() {
  print('🧪 Testing Street Field Mapping from DynamoDB...');

  // Test with the exact data structure from DynamoDB
  print('\n=== Test 1: business_1756220656049_ee98qktepks ===');
  final testData1 = {
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

  print('Raw data:');
  print('  city: ${testData1['city']}');
  print('  district: ${testData1['district']}');
  print('  street: ${testData1['street']}');
  print('  country: ${testData1['country']}');

  print('\n=== Test 2: business_1756222089290_s94ullqqn8d ===');
  final testData2 = {
    'businessId': 'business_1756222089290_s94ullqqn8d',
    'businessName': 'Complete Document Test Business',
    'email': 'test-complete-docs-1756222087@example.com',
    'city': 'Baghdad',
    'district': 'Karrada',
    'street': '123 Test Street',
    'country': 'Iraq',
    'status': 'pending',
  };

  print('Raw data:');
  print('  city: ${testData2['city']}');
  print('  district: ${testData2['district']}');
  print('  street: ${testData2['street']}');
  print('  country: ${testData2['country']}');

  print('\n✅ Street Field Mapping Test Completed');
}
