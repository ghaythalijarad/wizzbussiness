import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hadhir_business/config/app_config.dart';
import 'app_auth_service.dart';

class ProductService {
  static String get baseUrl => AppConfig.baseUrl;

  /// Get all products for the authenticated business
  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'products': data['products'] ?? [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch products',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Create a new product
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    String? imageUrl,
    bool isAvailable = true,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final productData = {
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'isAvailable': isAvailable,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (additionalData != null) ...additionalData,
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
        return {
          'success': true,
          'product': data['product'],
          'message': 'Product created successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Update an existing product
  static Future<Map<String, dynamic>> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? imageUrl,
    bool? isAvailable,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (categoryId != null) updateData['categoryId'] = categoryId;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;
      if (additionalData != null) updateData.addAll(additionalData);

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
        return {
          'success': true,
          'product': data['product'],
          'message': 'Product updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Delete a product
  static Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      print('--- STARTING PRODUCT DELETION (BEARER TOKEN) ---');
      print('Product ID: $productId');

      // Use access token (not ID token) for API authorization
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        print('❌ No access token found');
        return {
          'success': false,
          'message': 'Authentication token not found. Please sign in again.',
        };
      }

      print('✅ Access Token retrieved');
      print('📝 Token length: ${token.length}');
      print('📝 Token preview: ${token.substring(0, 20)}...');

      final url = Uri.parse('$baseUrl/products/$productId');
      print('🌐 Request URL: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📋 Request headers:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          print('  $key: Bearer ${value.substring(7, 27)}...');
        } else {
          print('  $key: $value');
        }
      });

      final response = await http.delete(url, headers: headers);

      print('--- RESPONSE ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Success: Product deleted successfully.');
        return {
          'success': true,
          'message': 'Product deleted successfully',
        };
      } else {
        print('❌ Error: Failed to delete product.');
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ??
                'Failed to delete product. Status code: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to parse error response. Body: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('--- CATCH BLOCK ERROR ---');
      print('An unexpected error occurred: ${e.toString()}');
      return {
        'success': false,
        'message': 'An unexpected network error occurred. Please try again.',
      };
    } finally {
      print('--- PRODUCT DELETION PROCESS COMPLETE ---');
    }
  }

  /// Search for products by name
  static Future<Map<String, dynamic>> searchProducts(String query) async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products/search?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'products': data['products'] ?? []};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to search products'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get a specific product by ID
  static Future<Map<String, dynamic>> getProduct(String productId) async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'product': data['product'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get categories for a specific business type
  static Future<Map<String, dynamic>> getCategoriesForBusinessType(
      String businessType) async {
    print(
        '🔗 ProductService: Getting categories for business type: $businessType');

    try {
      final url = '$baseUrl/categories/business-type/$businessType';
      print('🌐 ProductService: Making request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📊 ProductService: API response status: ${response.statusCode}');
      print('📄 ProductService: API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiCategories = data['categories'] ?? [];

        print(
            '✅ ProductService: API returned ${apiCategories.length} categories');
        print('📦 ProductService: Categories data: $apiCategories');

        return {
          'success': true,
          'categories': apiCategories,
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ ProductService: API error: ${errorData['message']}');
        
        // Fallback to predefined categories when API fails
        print(
            '🔄 ProductService: Using fallback categories for business type: $businessType');
        final fallbackCategories = _getFallbackCategories(businessType);
        
        return {
          'success': true,
          'categories': fallbackCategories,
          'source': 'fallback',
          'message': 'API temporarily unavailable, using default categories',
        };
      }
    } catch (e) {
      print('ProductService: Network error: $e');
      
      // Fallback to predefined categories on network error
      print(
          '🔄 ProductService: Network error, using fallback categories for business type: $businessType');
      final fallbackCategories = _getFallbackCategories(businessType);
      
      return {
        'success': true,
        'categories': fallbackCategories,
        'source': 'fallback',
        'message': 'Network error, using default categories',
      };
    }
  }

  /// Get fallback categories when API is unavailable
  static List<Map<String, dynamic>> _getFallbackCategories(
      String businessType) {
    final fallbackCategories = <Map<String, dynamic>>[];

    switch (businessType.toLowerCase()) {
      case 'restaurant':
      case 'kitchen':
        fallbackCategories.addAll([
          {
            'categoryId': 'fb-appetizers-001',
            'name': 'Appetizers',
            'name_ar': 'المقبلات',
            'description': 'Starters and appetizers',
            'businessType': 'restaurant',
            'is_active': true,
          },
          {
            'categoryId': 'fb-main-courses-002',
            'name': 'Main Courses',
            'name_ar': 'الأطباق الرئيسية',
            'description': 'Main dishes and entrees',
            'businessType': 'restaurant',
            'is_active': true,
          },
          {
            'categoryId': 'fb-desserts-003',
            'name': 'Desserts',
            'name_ar': 'الحلويات',
            'description': 'Sweet desserts and treats',
            'businessType': 'restaurant',
            'is_active': true,
          },
          {
            'categoryId': 'fb-beverages-004',
            'name': 'Beverages',
            'name_ar': 'المشروبات',
            'description': 'Drinks and beverages',
            'businessType': 'restaurant',
            'is_active': true,
          },
          {
            'categoryId': 'fb-sides-005',
            'name': 'Sides',
            'name_ar': 'الأطباق الجانبية',
            'description': 'Side dishes',
            'businessType': 'restaurant',
            'is_active': true,
          },
        ]);
        break;

      case 'cloudkitchen':
        fallbackCategories.addAll([
          {
            'categoryId': 'fb-ck-appetizers-001',
            'name': 'Appetizers',
            'name_ar': 'المقبلات',
            'description': 'Starters and appetizers',
            'businessType': 'cloudkitchen',
            'is_active': true,
          },
          {
            'categoryId': 'fb-ck-main-002',
            'name': 'Main Courses',
            'name_ar': 'الأطباق الرئيسية',
            'description': 'Main dishes and entrees',
            'businessType': 'cloudkitchen',
            'is_active': true,
          },
          {
            'categoryId': 'fb-ck-desserts-003',
            'name': 'Desserts',
            'name_ar': 'الحلويات',
            'description': 'Sweet desserts and treats',
            'businessType': 'cloudkitchen',
            'is_active': true,
          },
          {
            'categoryId': 'fb-ck-beverages-004',
            'name': 'Beverages',
            'name_ar': 'المشروبات',
            'description': 'Drinks and beverages',
            'businessType': 'cloudkitchen',
            'is_active': true,
          },
        ]);
        break;

      case 'store':
        fallbackCategories.addAll([
          {
            'categoryId': 'fb-store-grocery-001',
            'name': 'Groceries',
            'name_ar': 'البقالة',
            'description': 'Daily groceries and essentials',
            'businessType': 'store',
            'is_active': true,
          },
          {
            'categoryId': 'fb-store-snacks-002',
            'name': 'Snacks',
            'name_ar': 'الوجبات الخفيفة',
            'description': 'Snacks and light meals',
            'businessType': 'store',
            'is_active': true,
          },
          {
            'categoryId': 'fb-store-beverages-003',
            'name': 'Beverages',
            'name_ar': 'المشروبات',
            'description': 'Drinks and beverages',
            'businessType': 'store',
            'is_active': true,
          },
          {
            'categoryId': 'fb-store-household-004',
            'name': 'Household Items',
            'name_ar': 'أدوات منزلية',
            'description': 'Household supplies and items',
            'businessType': 'store',
            'is_active': true,
          },
        ]);
        break;

      case 'pharmacy':
        fallbackCategories.addAll([
          {
            'categoryId': 'fb-pharm-prescription-001',
            'name': 'Prescription Medications',
            'name_ar': 'الأدوية الموصوفة',
            'description': 'Prescription drugs and medications',
            'businessType': 'pharmacy',
            'is_active': true,
          },
          {
            'categoryId': 'fb-pharm-otc-002',
            'name': 'Over-the-Counter',
            'name_ar': 'أدوية بدون وصفة',
            'description': 'Non-prescription medications',
            'businessType': 'pharmacy',
            'is_active': true,
          },
          {
            'categoryId': 'fb-pharm-vitamins-003',
            'name': 'Vitamins & Supplements',
            'name_ar': 'الفيتامينات والمكملات',
            'description': 'Health supplements and vitamins',
            'businessType': 'pharmacy',
            'is_active': true,
          },
          {
            'categoryId': 'fb-pharm-personal-004',
            'name': 'Personal Care',
            'name_ar': 'العناية الشخصية',
            'description': 'Personal care and hygiene products',
            'businessType': 'pharmacy',
            'is_active': true,
          },
        ]);
        break;

      case 'cafe':
      case 'caffe':
        fallbackCategories.addAll([
          {
            'categoryId': 'fb-cafe-coffee-001',
            'name': 'Coffee',
            'name_ar': 'القهوة',
            'description': 'Hot and cold coffee beverages',
            'businessType': 'cafe',
            'is_active': true,
          },
          {
            'categoryId': 'fb-cafe-tea-002',
            'name': 'Tea',
            'name_ar': 'الشاي',
            'description': 'Various types of tea',
            'businessType': 'cafe',
            'is_active': true,
          },
          {
            'categoryId': 'fb-cafe-pastries-003',
            'name': 'Pastries',
            'name_ar': 'المعجنات',
            'description': 'Fresh pastries and baked goods',
            'businessType': 'cafe',
            'is_active': true,
          },
          {
            'categoryId': 'fb-cafe-sandwiches-004',
            'name': 'Sandwiches',
            'name_ar': 'الساندويشات',
            'description': 'Light meals and sandwiches',
            'businessType': 'cafe',
            'is_active': true,
          },
        ]);
        break;

      case 'bakery':
        fallbackCategories.addAll([
          {
            'categoryId': 'fb-bakery-bread-001',
            'name': 'Bread',
            'name_ar': 'الخبز',
            'description': 'Fresh bread and rolls',
            'businessType': 'bakery',
            'is_active': true,
          },
          {
            'categoryId': 'fb-bakery-cakes-002',
            'name': 'Cakes',
            'name_ar': 'الكيك',
            'description': 'Cakes and celebration desserts',
            'businessType': 'bakery',
            'is_active': true,
          },
          {
            'categoryId': 'fb-bakery-pastries-003',
            'name': 'Pastries',
            'name_ar': 'المعجنات',
            'description': 'Sweet and savory pastries',
            'businessType': 'bakery',
            'is_active': true,
          },
          {
            'categoryId': 'fb-bakery-cookies-004',
            'name': 'Cookies',
            'name_ar': 'البسكويت',
            'description': 'Cookies and biscuits',
            'businessType': 'bakery',
            'is_active': true,
          },
        ]);
        break;

      default:
        // Default categories for unsupported business types
        fallbackCategories.addAll([
          {
            'categoryId': 'fb-general-001',
            'name': 'General Items',
            'name_ar': 'أصناف عامة',
            'description': 'General product category',
            'businessType': businessType,
            'is_active': true,
          },
          {
            'categoryId': 'fb-popular-002',
            'name': 'Popular Items',
            'name_ar': 'أصناف شائعة',
            'description': 'Popular and featured items',
            'businessType': businessType,
            'is_active': true,
          },
        ]);
    }

    print(
        '📦 ProductService: Generated ${fallbackCategories.length} fallback categories');
    return fallbackCategories;
  }

  /// Get all categories
  static Future<Map<String, dynamic>> getAllCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'categories': data['categories'] ?? [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch categories',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
