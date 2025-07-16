import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Category Loading for Different Business Types...\n');
  
  final businessTypes = ['store', 'restaurant', 'pharmacy', 'cloudkitchen', 'caffe'];
  final baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
  
  for (final businessType in businessTypes) {
    print('🏪 Testing business type: $businessType');
    print('─' * 50);
    
    try {
      final url = '$baseUrl/categories/business-type/$businessType';
      print('📡 Making request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📊 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = data['categories'] as List? ?? [];
        
        print('✅ Success: ${categories.length} categories found');
        for (int i = 0; i < categories.length; i++) {
          final category = categories[i];
          print('   ${i + 1}. ${category['name']} (${category['categoryId']})');
        }
      } else {
        print('❌ Error: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          print('   Message: ${errorData['message']}');
        } catch (e) {
          print('   Body: ${response.body}');
        }
      }
    } catch (e) {
      print('💥 Network Error: $e');
    }
    
    print('');
  }

  // Test the enum conversion logic
  print('🔄 Testing Business Type Enum Conversion...');
  print('─' * 50);
  
  final testBusinessTypes = [
    'BusinessType.kitchen',
    'BusinessType.cloudkitchen', 
    'BusinessType.store',
    'BusinessType.pharmacy',
    'BusinessType.caffe'
  ];
  
  for (final enumString in testBusinessTypes) {
    final typeStr = enumString.split('.').last.toLowerCase();
    String apiString;
    
    switch (typeStr) {
      case 'kitchen':
        apiString = 'restaurant';
        break;
      case 'cloudkitchen':
        apiString = 'cloudkitchen';
        break;
      case 'store':
        apiString = 'store';
        break;
      case 'pharmacy':
        apiString = 'pharmacy';
        break;
      case 'caffe':
        apiString = 'caffe';
        break;
      default:
        apiString = 'restaurant';
    }
    
    print('$enumString → $apiString');
  }
}
