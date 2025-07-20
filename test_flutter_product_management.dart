import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ProductManagementTest {
  static const String baseUrl =
      'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

  // Test product data
  static const String testProductId = '253809e2-dabc-4d3b-b11e-01522c600933';
  static const String testCategoryId = '285fee8f-9f99-48bf-8559-1d0235686f9f';

  static Future<void> runAllTests() async {
    print('🧪 Starting Flutter Product Management Tests...');
    print('=' * 50);

    // Read access token from file
    final token = await getAccessToken();
    if (token == null) {
      print('❌ Failed to get access token');
      return;
    }

    // Test 1: Get all products
    await testGetProducts(token);

    // Test 2: Get specific product
    await testGetProduct(token, testProductId);

    // Test 3: Test product creation
    await testCreateProduct(token);

    // Test 4: Test product update
    await testUpdateProduct(token, testProductId);

    // Test 5: Test categories
    await testGetCategories(token);

    print('=' * 50);
    print('✅ All Flutter Product Management Tests Completed!');
  }

  static Future<String?> getAccessToken() async {
    try {
      final file = await File(
              '/Users/ghaythallaheebi/order-receiver-app-2/access_token.txt')
          .readAsString();
      return file.trim();
    } catch (e) {
      print('❌ Error reading access token: $e');
      return null;
    }
  }

  static Future<void> testGetProducts(String token) async {
    print('🔍 Testing GET /products...');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final products = data['products'] as List;
          print(
              '✅ GET /products successful - Found ${products.length} products');

          // Check if products have correct field names
          if (products.isNotEmpty) {
            final product = products.first;
            final hasProductId = product.containsKey('productId');
            final hasCategoryId = product.containsKey('category_id');

            print('   📋 Field validation:');
            print('   - productId field: ${hasProductId ? "✅" : "❌"}');
            print('   - category_id field: ${hasCategoryId ? "✅" : "❌"}');
            print('   - Sample product: ${product['name']}');
          }
        } else {
          print('❌ GET /products failed: ${data['message']}');
        }
      } else {
        print('❌ GET /products failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in GET /products: $e');
    }
  }

  static Future<void> testGetProduct(String token, String productId) async {
    print('🔍 Testing GET /products/$productId...');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final product = data['product'];
          print('✅ GET /products/$productId successful');
          print('   - Name: ${product['name']}');
          print('   - ProductId: ${product['productId']}');
          print('   - CategoryId: ${product['category_id']}');
          print('   - Price: ${product['price']}');
        } else {
          print('❌ GET /products/$productId failed: ${data['message']}');
        }
      } else {
        print(
            '❌ GET /products/$productId failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in GET /products/$productId: $e');
    }
  }

  static Future<void> testCreateProduct(String token) async {
    print('🔍 Testing POST /products...');

    try {
      final productData = {
        'name': 'Flutter Test Product 2',
        'description': 'Created via Flutter test script',
        'price': 12.99,
        'categoryId': testCategoryId,
        'isAvailable': true,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final product = data['product'];
          print('✅ POST /products successful');
          print('   - New ProductId: ${product['productId']}');
          print('   - Name: ${product['name']}');
          print('   - Price: ${product['price']}');

          // Clean up - delete the test product
          await deleteProduct(token, product['productId']);
        } else {
          print('❌ POST /products failed: ${data['message']}');
        }
      } else {
        print('❌ POST /products failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in POST /products: $e');
    }
  }

  static Future<void> testUpdateProduct(String token, String productId) async {
    print('🔍 Testing PUT /products/$productId...');

    try {
      final updateData = {
        'name': 'Updated Flutter Test Product',
        'description': 'Updated via Flutter test script',
        'price': 30.99,
        'isAvailable': false,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final product = data['product'];
          print('✅ PUT /products/$productId successful');
          print('   - Updated Name: ${product['name']}');
          print('   - Updated Price: ${product['price']}');
          print('   - Available: ${product['is_available']}');
        } else {
          print('❌ PUT /products/$productId failed: ${data['message']}');
        }
      } else {
        print(
            '❌ PUT /products/$productId failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in PUT /products/$productId: $e');
    }
  }

  static Future<void> testGetCategories(String token) async {
    print('🔍 Testing GET /categories...');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final categories = data['categories'] as List;
          print(
              '✅ GET /categories successful - Found ${categories.length} categories');

          // Check if categories have correct field names
          if (categories.isNotEmpty) {
            final category = categories.first;
            final hasCategoryId = category.containsKey('categoryId');
            final hasBusinessType = category.containsKey('businessType');

            print('   📋 Field validation:');
            print('   - categoryId field: ${hasCategoryId ? "✅" : "❌"}');
            print('   - businessType field: ${hasBusinessType ? "✅" : "❌"}');
            print('   - Sample category: ${category['name']}');
          }
        } else {
          print('❌ GET /categories failed: ${data['message']}');
        }
      } else {
        print('❌ GET /categories failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in GET /categories: $e');
    }
  }

  static Future<void> deleteProduct(String token, String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('   🗑️ Test product cleaned up successfully');
      }
    } catch (e) {
      print('   ⚠️ Failed to clean up test product: $e');
    }
  }
}

void main() async {
  await ProductManagementTest.runAllTests();
}
