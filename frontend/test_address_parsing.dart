#!/usr/bin/env dart

/// Simple test to verify address parsing logic works correctly
void main() {
  print('🧪 Testing Address Parsing Logic');
  print('================================');
  
  // Test cases with various address formats
  final testAddresses = [
    'Street 14, Karrada District, Baghdad, Iraq',
    '123 Main Street, Erbil, Kurdistan, Iraq',
    'Al-Rashid Street, Al-Karkh, Baghdad',
    'University Street, Sulaymaniyah',
    'Palestine Street, Baghdad',
    'Najaf City Center, Najaf Province',
    'Market Street, Basra, Iraq',
    '',
  ];
  
  for (final address in testAddresses) {
    final result = parseAddress(address);
    print('\n📍 Address: "$address"');
    print('   Street: ${result['street'] ?? 'Not found'}');
    print('   City: ${result['city'] ?? 'Not found'}');
    print('   District: ${result['district'] ?? 'Not found'}');
    print('   Country: ${result['country'] ?? 'Not found'}');
  }
}

/// Simple address parsing to extract components
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

/// Check if a string contains a known city name
bool isKnownCity(String text) {
  final knownCities = [
    'baghdad', 'basra', 'mosul', 'erbil', 'najaf', 'karbala', 
    'kirkuk', 'sulaymaniyah', 'ramadi', 'fallujah', 'tikrit',
    'amarah', 'nasiriyah', 'kut', 'hilla', 'diwaniyah',
    'samarra', 'duhok', 'zakho', 'halabja'
  ];
  return knownCities.any((city) => text.contains(city));
}

/// Check if a string contains a known country name
bool isKnownCountry(String text) {
  final knownCountries = ['iraq', 'iraqi', 'kurdistan'];
  return knownCountries.any((country) => text.contains(country));
}
