// Quick test of the location settings address parsing logic
import 'dart:convert';

void main() {
  print('🧪 TESTING LOCATION SETTINGS ADDRESS PARSING');
  print('==============================================');
  
  // Test DynamoDB format parsing
  testDynamoDBFormatParsing();
  
  // Test address string parsing  
  testAddressStringParsing();
  
  // Test address construction
  testAddressConstruction();
  
  print('\n✅ All tests completed!');
}

void testDynamoDBFormatParsing() {
  print('\n1️⃣ Testing DynamoDB Format Parsing');
  print('-----------------------------------');
  
  // Simulate the DynamoDB format from the database table
  final addressData = {
    "country": {"S": "Iraq"},
    "city": {"S": "Baghdad"}, 
    "street": {"S": "123 Test Street"},
    "district": {"S": "Karrada"}
  };
  
  // Extract values (mimicking _extractDynamoValue function)
  final city = extractDynamoValue(addressData['city']);
  final district = extractDynamoValue(addressData['district']);
  final street = extractDynamoValue(addressData['street']);
  final country = extractDynamoValue(addressData['country']);
  
  print('✅ City: "$city" (expected: "Baghdad")');
  print('✅ District: "$district" (expected: "Karrada")');
  print('✅ Street: "$street" (expected: "123 Test Street")');
  print('✅ Country: "$country" (expected: "Iraq")');
  
  assert(city == 'Baghdad', 'City extraction failed');
  assert(district == 'Karrada', 'District extraction failed');
  assert(street == '123 Test Street', 'Street extraction failed');
  assert(country == 'Iraq', 'Country extraction failed');
}

void testAddressStringParsing() {
  print('\n2️⃣ Testing Address String Parsing');
  print('----------------------------------');
  
  final testAddresses = [
    '123 Test Street, Karrada, Baghdad, Iraq',
    'شارع الصناعة, الجمعية, النجف',
    'Test Street, Baghdad',
    'Karrada District, Baghdad, Iraq'
  ];
  
  for (final address in testAddresses) {
    print('📍 Parsing: "$address"');
    final components = parseAddress(address);
    print('   → Street: "${components['street']}"');
    print('   → District: "${components['district']}"');
    print('   → City: "${components['city']}"');
    print('   → Country: "${components['country']}"');
    print('');
  }
}

void testAddressConstruction() {
  print('\n3️⃣ Testing Address Construction');
  print('-------------------------------');
  
  final testComponents = [
    {
      'street': '123 Test Street',
      'district': 'Karrada',
      'city': 'Baghdad',
      'country': 'Iraq'
    },
    {
      'street': 'شارع الصناعة',
      'district': 'الجمعية', 
      'city': 'النجف',
      'country': 'Iraq'
    },
    {
      'street': '',
      'district': 'Downtown',
      'city': 'Baghdad',
      'country': 'Iraq'
    }
  ];
  
  for (final components in testComponents) {
    final constructedAddress = buildAddressString(components);
    print('📍 Components: ${components}');
    print('   → Address: "$constructedAddress"');
    print('');
  }
}

// Helper functions (mimicking the actual implementation)
String? extractDynamoValue(dynamic dynamoField) {
  if (dynamoField == null) return null;
  
  if (dynamoField is Map<String, dynamic>) {
    // DynamoDB format: {"S": "value"}
    return dynamoField['S']?.toString();
  } else if (dynamoField is String) {
    // Plain string value
    return dynamoField;
  }
  
  return dynamoField?.toString();
}

Map<String, String?> parseAddress(String address) {
  final Map<String, String?> components = {
    'street': null,
    'city': null,
    'district': null,
    'country': null,
  };
  
  if (address.isEmpty) return components;
  
  // Split address by common separators
  final parts = address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  
  if (parts.isNotEmpty) {
    // First part is usually street address
    components['street'] = parts[0];
    
    // Look for common Iraqi city names
    for (final part in parts) {
      final lowerPart = part.toLowerCase();
      if (isKnownCity(lowerPart)) {
        components['city'] = part;
        break;
      }
    }
    
    // If more than one part, use last part as country (if it looks like a country)
    if (parts.length > 1) {
      final lastPart = parts.last.toLowerCase();
      if (isKnownCountry(lastPart)) {
        components['country'] = parts.last;
      }
    }
    
    // Try to identify district (usually middle parts that aren't city or country)
    for (final part in parts) {
      if (part != components['street'] && 
          part != components['city'] && 
          part != components['country']) {
        components['district'] = part;
        break;
      }
    }
  }
  
  return components;
}

String buildAddressString(Map<String, String> components) {
  final parts = <String>[];
  
  if (components['street']?.trim().isNotEmpty == true) {
    parts.add(components['street']!.trim());
  }
  if (components['district']?.trim().isNotEmpty == true) {
    parts.add(components['district']!.trim());
  }
  if (components['city']?.trim().isNotEmpty == true) {
    parts.add(components['city']!.trim());
  }
  if (components['country']?.trim().isNotEmpty == true) {
    parts.add(components['country']!.trim());
  }
  
  return parts.join(', ');
}

bool isKnownCity(String text) {
  final knownCities = [
    'baghdad', 'basra', 'mosul', 'erbil', 'najaf', 'karbala', 
    'kirkuk', 'sulaymaniyah', 'ramadi', 'fallujah', 'tikrit',
    'amarah', 'nasiriyah', 'kut', 'hilla', 'diwaniyah',
    'samarra', 'duhok', 'zakho', 'halabja', 'النجف'
  ];
  return knownCities.any((city) => text.contains(city));
}

bool isKnownCountry(String text) {
  final knownCountries = ['iraq', 'iraqi', 'kurdistan'];
  return knownCountries.any((country) => text.contains(country));
}
