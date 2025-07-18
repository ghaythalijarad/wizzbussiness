import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('🧪 Testing Category Loading...\n');

  // Test the API endpoint directly
  final url =
      'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/categories/business-type/store';

  try {
    print('📡 Making HTTP request to: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    print('📊 Response Status: ${response.statusCode}');
    print('📋 Response Headers: ${response.headers}');
    print('📄 Response Body: ${response.body}\n');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ API Response Success: ${data['success']}');

      if (data['categories'] != null) {
        final categories = data['categories'] as List;
        print('🏷️  Found ${categories.length} categories:');

        for (int i = 0; i < categories.length; i++) {
          final category = categories[i];
          print(
              '   ${i + 1}. ${category['name']} (ID: ${category['categoryId']})');
        }

        // Test ProductCategory.fromJson parsing
        print('\n🔄 Testing ProductCategory.fromJson parsing...');
        for (final categoryJson in categories) {
          try {
            // Simulate the ProductCategory.fromJson method
            final parsedCategory = {
              'id': categoryJson['categoryId'] ??
                  categoryJson['category_id'] ??
                  categoryJson['id'] ??
                  '',
              'name': categoryJson['name'] ?? '',
              'businessType': categoryJson['businessType'] ??
                  categoryJson['business_type'] ??
                  '',
              'description': categoryJson['description'],
              'sortOrder': categoryJson['sort_order'] ?? 0,
            };

            print(
                '   ✅ Parsed: ${parsedCategory['name']} (ID: ${parsedCategory['id']})');
          } catch (e) {
            print('   ❌ Parse Error for ${categoryJson['name']}: $e');
          }
        }
      } else {
        print('❌ No categories in response');
      }
    } else {
      print('❌ API Error: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Network Error: $e');
  }
}
