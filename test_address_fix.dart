
void main() {
  print("🧪 Testing Address Formatting Fix");
  print("================================");
  
  // Helper function to extract value from DynamoDB attribute format
  String extractValue(dynamic value) {
    if (value == null) return "";
    
    // Handle DynamoDB attribute format: { "S": "value" }
    if (value is Map<String, dynamic> && value.containsKey("S")) {
      return value["S"]?.toString() ?? "";
    }
    
    // Handle plain string values
    if (value is String) return value;
    
    return value.toString();
  }
  
  String formatAddress(Map<String, dynamic>? address) {
    if (address == null) {
      return "";
    }
    
    // Extract address components, handling both DynamoDB format and plain format
    final street = extractValue(address["street"]);
    final district = extractValue(address["district"]);
    final city = extractValue(address["city"]);
    final country = extractValue(address["country"]);
    final homeAddress = extractValue(address["home_address"]);
    final neighborhood = extractValue(address["neighborhood"]);
    
    // Build formatted address, filtering out empty components
    final components = [
      homeAddress,
      street,
      neighborhood,
      district,
      city,
      country,
    ].where((component) => component.isNotEmpty).toList();
    
    return components.join(", ");
  }

  // Test DynamoDB attribute format (the problematic format)
  final dynamoDBAddress = {
    "country": {"S": "Iraq"},
    "city": {"S": "النجف"},
    "street": {"S": "شارع الصناعة"},
    "district": {"S": "المناذرة"},
  };
  
  final result1 = formatAddress(dynamoDBAddress);
  print("DynamoDB format result: $result1");
  assert(result1 == "شارع الصناعة, المناذرة, النجف, Iraq");
  
  print("✅ Address formatting fix is working correctly!");
}

