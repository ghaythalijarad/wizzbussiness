import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Working Hours API...');
  
  // Test data that matches the simplified Flutter app format
  final testData = {
    'workingHours': {
      'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
      'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
      'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
      'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
      'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
      'saturday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
      'sunday': {'isOpen': false, 'openTime': '09:00', 'closeTime': '21:00'},
    },
  };
  
  print('📤 Test data: ${jsonEncode(testData)}');
  
  try {
    final response = await http.put(
      Uri.parse('https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/business_1756220656049_ee98qktepks/working-hours'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token', // This will fail but show us the error format
      },
      body: jsonEncode(testData),
    );
    
    print('📋 Response status: ${response.statusCode}');
    print('📋 Response body: ${response.body}');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
