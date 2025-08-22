import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_service.dart';
import 'app_auth_service.dart';

class ProductService {
  static String get baseUrl => AppConfig.baseUrl;

  // --- Added centralized diagnostic + request helper ---
  static Future<http.Response> _diagRequest({
    required String method,
    required String path,
    String? body,
    bool preferIdToken = true,
  }) async {
    final apiService = ApiService();
    final started = DateTime.now();
    print('🛒 [ProductService] → $method $path  preferIdToken=$preferIdToken');
    if (body != null) {
      final preview = body.length > 240 ? body.substring(0, 240) + '…' : body;
      print('🛒 [ProductService]   Body(${body.length}): $preview');
    }
    try {
      final resp = await apiService.makeAuthenticatedRequest(
        method: method,
        path: path,
        body: body,
        preferIdToken: preferIdToken,
      );
      final dur = DateTime.now().difference(started).inMilliseconds;
      String contentType = resp.headers['content-type'] ?? 'unknown';
      print(
          '🛒 [ProductService] ← $method $path  status=${resp.statusCode}  in ${dur}ms  content-type=$contentType  len=${resp.body.length}');
      if (resp.statusCode >= 400) {
        final snippet = resp.body.length > 300
            ? resp.body.substring(0, 300) + '…'
            : resp.body;
        print('🛒 [ProductService]   Error body: $snippet');
      }
      return resp;
    } catch (e) {
      print('🛒 [ProductService] ✖ Request error $method $path: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _mapError(dynamic e, {http.Response? response}) {
    // Normalize various failure modes into user actionable messages
    final errStr = e.toString();
    if (errStr.contains('Failed host lookup') ||
        errStr.contains('SocketException')) {
      return {
        'success': false,
        'message': 'Network unreachable. Check internet connection.'
      };
    }
    if (errStr.contains('CERTIFICATE')) {
      return {
        'success': false,
        'message': 'SSL certificate error. Please retry later.'
      };
    }
    if (errStr.contains('CORS') || errStr.contains('No Access-Control-Allow')) {
      return {
        'success': false,
        'message':
            'CORS restriction encountered. Verify API Gateway CORS configuration.'
      };
    }
    if (errStr.contains('401') || (response?.statusCode == 401)) {
      return {
        'success': false,
        'message': 'Authentication expired (401). Please sign in again.'
      };
    }
    return {'success': false, 'message': 'Unexpected error: $errStr'};
  }

  static Map<String, dynamic> _parseJsonSafely(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': body};
    }
  }

  static Map<String, dynamic> _standardizeResponse({
    required http.Response response,
    required String successKey,
    String? listKey,
    String? singleKey,
  }) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _parseJsonSafely(response.body);
      return {
        'success': true,
        if (listKey != null) listKey: data[listKey] ?? [],
        if (singleKey != null) singleKey: data[singleKey],
        'status': response.statusCode,
      };
    }
    final data = _parseJsonSafely(response.body);
    return {
      'success': false,
      'status': response.statusCode,
      'message': data['message'] ??
          'Failed ($successKey) status ${response.statusCode}',
      'body': response.body.length > 400
          ? response.body.substring(0, 400) + '…'
          : response.body,
    };
  }

  /// Get all products for the authenticated business with robust retry logic
  static Future<Map<String, dynamic>> getProducts({int maxRetries = 3}) async {
    int retryCount = 0;

    // Enhanced debugging - check authentication state first
    print('🔍 [ProductService] Starting getProducts - checking auth state...');

    try {
      // Check if user is authenticated
      final isSignedIn = await AppAuthService.isSignedIn();
      print('🔍 [ProductService] User signed in: $isSignedIn');

      if (!isSignedIn) {
        return {
          'success': false,
          'error': 'not_authenticated',
          'message': 'User is not authenticated. Please sign in.',
          'userAction': 'sign_in_required',
        };
      }
      
      // Check available tokens
      final accessToken = await AppAuthService.getAccessToken();
      final idToken = await AppAuthService.getIdToken();
      print(
          '🔍 [ProductService] Access token available: ${accessToken != null}');
      print('🔍 [ProductService] ID token available: ${idToken != null}');

      if (accessToken == null && idToken == null) {
        return {
          'success': false,
          'error': 'no_tokens',
          'message':
              'No authentication tokens available. Please sign in again.',
          'userAction': 'sign_in_required',
        };
      }
    } catch (authCheckError) {
      print('❌ [ProductService] Auth check failed: $authCheckError');
      return {
        'success': false,
        'error': 'auth_check_failed',
        'message': 'Failed to verify authentication status: $authCheckError',
        'userAction': 'try_again',
      };
    }

    while (retryCount < maxRetries) {
      try {
        print(
            '🛒 [ProductService] getProducts attempt ${retryCount + 1}/$maxRetries');

        // Now using ID token by default for Cognito User Pool authorizers
        final response = await _diagRequest(
          method: 'GET',
          path: '/products',
        );

        final standardized = _standardizeResponse(
          response: response,
          successKey: 'products',
          listKey: 'products',
        );

        if (standardized['success']) {
          final products = standardized['products'] as List? ?? [];
          print(
              '🛒 [ProductService] ✅ Successfully fetched ${products.length} products');
          return standardized;
        }

        // Check if this is an authorization error that suggests backend misconfiguration
        final errorMsg = standardized['message']?.toString() ?? '';
        final statusCode = standardized['status'] ?? 0;

        if (statusCode == 403 ||
            errorMsg.contains('Invalid key=value pair') ||
            errorMsg.contains('missing equal-sign') ||
            errorMsg.contains('Authorization header') ||
            errorMsg.contains('AWS_IAM')) {
          print(
              '🛒 [ProductService] 🔧 Authorization error detected (backend needs serverless.yml deployment)');

          // Try alternative approaches before giving up
          if (retryCount == 0) {
            print(
                '🛒 [ProductService] 🔄 Retrying with access token fallback...');
            retryCount++;

            final altResponse = await _diagRequest(
              method: 'GET',
              path: '/products',
              preferIdToken: false, // Try access token as fallback
            );

            final altStandardized = _standardizeResponse(
              response: altResponse,
              successKey: 'products',
              listKey: 'products',
            );

            if (altStandardized['success']) {
              final products = altStandardized['products'] as List? ?? [];
              print(
                  '🛒 [ProductService] ✅ Access token fallback worked! Fetched ${products.length} products');
              return altStandardized;
            }
          }

          // If we've tried both tokens and still failing, it's a backend config issue
          return {
            'success': false,
            'error': 'authorization_misconfigured',
            'message':
                'Product endpoints require backend deployment. The /products endpoints in serverless.yml are missing the cognitoAuthorizer configuration.',
            'technicalDetails':
                'API Gateway is defaulting to AWS_IAM authorization instead of JWT Cognito authorizer',
            'status': statusCode,
            'suggestedAction':
                'Deploy the updated serverless.yml configuration',
            'retryAfter': 300, // Suggest retry in 5 minutes
          };
        }

        // For other errors, increment retry count and continue
        print(
            '🛒 [ProductService] ❌ Attempt ${retryCount + 1} failed: ${standardized['message']}');
        retryCount++;

        if (retryCount < maxRetries) {
          final delayMs = (retryCount * 1000) +
              (DateTime.now().millisecondsSinceEpoch % 1000);
          print('🛒 [ProductService] ⏳ Waiting ${delayMs}ms before retry...');
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } catch (e) {
        retryCount++;
        final mapped = _mapError(e);
        print('🛒 [ProductService] 💥 Exception on attempt $retryCount: $e');

        if (retryCount >= maxRetries) {
          return {
            ...mapped,
            'retryCount': retryCount,
            'lastError': e.toString(),
          };
        }

        // Brief delay before retry
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    // All retries exhausted
    return {
      'success': false,
      'error': 'max_retries_exceeded',
      'message': 'Failed to fetch products after $maxRetries attempts',
      'retryCount': retryCount,
      'suggestedAction': 'Check network connection and try again later',
    };
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
      final productData = {
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'isAvailable': isAvailable,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (additionalData != null) ...additionalData,
      };

      final response = await _diagRequest(
        method: 'POST',
        path: '/products',
        body: jsonEncode(productData),
        preferIdToken: true,
      );
      final standardized = _standardizeResponse(
        response: response,
        successKey: 'product',
        singleKey: 'product',
      );
      return standardized['success']
          ? {
              ...standardized,
              'message': 'Product created successfully',
            }
          : standardized;
    } catch (e) {
      return _mapError(e);
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
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (categoryId != null) updateData['categoryId'] = categoryId;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;
      if (additionalData != null) updateData.addAll(additionalData);

      final response = await _diagRequest(
        method: 'PUT',
        path: '/products/$productId',
        body: jsonEncode(updateData),
        preferIdToken: true,
      );
      final standardized = _standardizeResponse(
        response: response,
        successKey: 'product',
        singleKey: 'product',
      );
      return standardized['success']
          ? {
              ...standardized,
              'message': 'Product updated successfully',
            }
          : standardized;
    } catch (e) {
      return _mapError(e);
    }
  }

  /// Delete a product
  static Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      final response = await _diagRequest(
        method: 'DELETE',
        path: '/products/$productId',
        preferIdToken: true,
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Product deleted successfully',
        };
      }
      final data = _parseJsonSafely(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete product',
        'status': response.statusCode,
      };
    } catch (e) {
      return _mapError(e);
    }
  }

  /// Search products
  static Future<Map<String, dynamic>> searchProducts(String query) async {
    try {
      final response = await _diagRequest(
        method: 'GET',
        path: '/products/search?q=${Uri.encodeComponent(query)}',
        preferIdToken: true,
      );
      final standardized = _standardizeResponse(
        response: response,
        successKey: 'products',
        listKey: 'products',
      );
      return standardized['success']
          ? standardized
          : {
              ...standardized,
              'message': standardized['message'] ?? 'Failed to search products',
            };
    } catch (e) {
      return _mapError(e);
    }
  }

  /// Get a specific product
  static Future<Map<String, dynamic>> getProduct(String productId) async {
    try {
      final response = await _diagRequest(
        method: 'GET',
        path: '/products/$productId',
        preferIdToken: true,
      );
      final standardized = _standardizeResponse(
        response: response,
        successKey: 'product',
        singleKey: 'product',
      );
      return standardized['success']
          ? standardized
          : {
              ...standardized,
              'message': standardized['message'] ?? 'Failed to fetch product',
            };
    } catch (e) {
      return _mapError(e);
    }
  }

  /// Get categories for a specific business type
  static Future<Map<String, dynamic>> getCategoriesForBusinessType(
      String businessType) async {
    try {
      print(
          '🔗 ProductService: Getting categories for business type: $businessType');
      print(
          '🌐 ProductService: Making request to: ${AppConfig.baseUrl}/categories/business-type/$businessType');
      
      final response = await _diagRequest(
        method: 'GET',
        path: '/categories/business-type/$businessType',
        preferIdToken: true,
      );

      print('📊 ProductService: API response status: ${response.statusCode}');
      print(
          '📄 ProductService: API response body len: ${response.body.length}');

      final standardized = _standardizeResponse(
        response: response,
        successKey: 'categories',
        listKey: 'categories',
      );

      if (standardized['success']) {
        final categories = standardized['categories'] as List? ?? [];
        print(
            '✅ ProductService: Successfully got ${categories.length} categories for $businessType');
        return standardized;
      } else {
        print(
            '❌ ProductService: Failed to get categories: ${standardized['message']}');

        // Check for CloudFront cache issues first
        if (response.headers.containsKey('x-cache') &&
            response.headers.containsKey('via') &&
            response.headers['via']?.contains('cloudfront') == true) {
          final cacheStatus = response.headers['x-cache'] ?? 'unknown';
          final cfPopId = response.headers['x-amz-cf-pop'] ?? 'unknown';

          return {
            'success': false,
            'error': 'cloudfront_cache_error',
            'message': '''CloudFront Cache Issue (Categories)

The API server is behind CloudFront which is serving cached error responses.

Details:
• Cache Status: $cacheStatus
• CloudFront POP: $cfPopId
• Status Code: ${response.statusCode}
• Business Type: $businessType

This typically resolves automatically within 24 hours. Please try again later or contact support if the issue persists.''',
            'status': response.statusCode,
            'userAction': 'wait_and_retry',
            'businessType': businessType,
          };
        }
        
        // Check if this is an authorization error
        final statusCode = standardized['status'] ?? 0;
        if (statusCode == 401 || statusCode == 403) {
          return {
            'success': false,
            'error': 'authorization_required',
            'message':
                'Authentication required to access categories. Please sign in again.',
            'status': statusCode,
            'userAction': 'sign_in_required',
          };
        }
        
        // Check if this is a backend configuration error
        if (statusCode == 403 &&
            (standardized['message']?.toString().contains('AWS_IAM') ??
                false)) {
          return {
            'success': false,
            'error': 'backend_misconfigured',
            'message':
                'Categories service is temporarily unavailable due to configuration issues.',
            'technicalDetails':
                'Category endpoints require backend deployment with proper authorization',
            'status': statusCode,
            'userAction': 'retry_later',
            'retryAfter': 300,
          };
        }
        
        // Generic API error
        return {
          'success': false,
          'error': 'api_error',
          'message': standardized['message'] ??
              'Failed to load categories for $businessType',
          'status': statusCode,
          'userAction': 'retry_or_contact_support',
          'businessType': businessType,
        };
      }
    } catch (e) {
      print('❌ ProductService: Exception getting categories: $e');
      final mapped = _mapError(e);
      return {
        ...mapped,
        'error': 'network_error',
        'businessType': businessType,
        'userAction': 'check_connection_and_retry',
      };
    }
  }



  /// Get all categories
  static Future<Map<String, dynamic>> getAllCategories() async {
    try {
      final url = '${AppConfig.baseUrl}/categories';
      final started = DateTime.now();
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      final ms = DateTime.now().difference(started).inMilliseconds;
      print(
          '🛒 [ProductService] GET /categories status=${response.statusCode} in ${ms}ms');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'categories': data['categories'] ?? [],
        };
      } else {
        final data = _parseJsonSafely(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch categories',
          'status': response.statusCode,
        };
      }
    } catch (e) {
      return _mapError(e);
    }
  }
}
