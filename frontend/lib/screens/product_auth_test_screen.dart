import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/app_auth_service.dart';
import '../services/product_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

/// Interactive Product Management Authentication Test Widget
///
/// This widget tests the authentication flow for product management
/// and displays detailed results for debugging purposes.
class ProductAuthTestWidget extends StatefulWidget {
  const ProductAuthTestWidget({Key? key}) : super(key: key);

  @override
  _ProductAuthTestWidgetState createState() => _ProductAuthTestWidgetState();
}

class _ProductAuthTestWidgetState extends State<ProductAuthTestWidget> {
  String _testResults = 'Ready to test authentication...';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Auth Test'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Product Management Authentication Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testAuthentication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Authentication'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testProductAPI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Product API'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testTokens,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Tokens'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testFullFlow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Full Flow'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Results Display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Running authentication tests...'),
                            ],
                          ),
                        )
                      : Text(
                          _testResults,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                ),
              ),
            ),

            // Clear Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _testResults = 'Ready to test authentication...';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Results'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testAuthentication() async {
    setState(() {
      _isLoading = true;
      _testResults = '🔍 Testing Authentication Status...\n\n';
    });

    try {
      final buffer = StringBuffer();
      buffer.writeln('🔐 AUTHENTICATION STATUS TEST');
      buffer.writeln('=' * 50);

      // Test 1: Check if user is signed in
      buffer.writeln('\n📋 Test 1: Sign-in Status');
      final isSignedIn = await AppAuthService.isSignedIn();
      buffer.writeln(
          '   Result: ${isSignedIn ? "✅ SIGNED IN" : "❌ NOT SIGNED IN"}');

      // Test 2: Get current user
      buffer.writeln('\n📋 Test 2: Current User Data');
      final currentUser = await AppAuthService.getCurrentUser();
      if (currentUser != null) {
        buffer.writeln('   ✅ User data found:');
        buffer.writeln('   Email: ${currentUser['email'] ?? 'N/A'}');
        buffer.writeln('   Sub: ${currentUser['sub'] ?? 'N/A'}');
        buffer.writeln('   Name: ${currentUser['name'] ?? 'N/A'}');
      } else {
        buffer.writeln('   ❌ No user data found');
      }

      // Test 3: Get tokens
      buffer.writeln('\n📋 Test 3: Token Availability');
      final accessToken = await AppAuthService.getAccessToken();
      final idToken = await AppAuthService.getIdToken();

      buffer.writeln(
          '   Access Token: ${accessToken != null ? "✅ AVAILABLE (${accessToken.length} chars)" : "❌ NOT AVAILABLE"}');
      buffer.writeln(
          '   ID Token: ${idToken != null ? "✅ AVAILABLE (${idToken.length} chars)" : "❌ NOT AVAILABLE"}');

      if (accessToken != null) {
        buffer.writeln(
            '   Access Token Format: ${_isValidJWT(accessToken) ? "✅ Valid JWT" : "❌ Invalid JWT"}');
      }
      if (idToken != null) {
        buffer.writeln(
            '   ID Token Format: ${_isValidJWT(idToken) ? "✅ Valid JWT" : "❌ Invalid JWT"}');
      }

      setState(() {
        _testResults = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = 'Authentication test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testProductAPI() async {
    setState(() {
      _isLoading = true;
      _testResults = '🛒 Testing Product API Access...\n\n';
    });

    try {
      final buffer = StringBuffer();
      buffer.writeln('🛒 PRODUCT API ACCESS TEST');
      buffer.writeln('=' * 50);

      // Test 1: Get products
      buffer.writeln('\n📋 Test 1: Get Products');
      buffer.writeln('   API URL: ${AppConfig.baseUrl}/products');

      final productsResult = await ProductService.getProducts();

      if (productsResult['success'] == true) {
        final products = productsResult['products'] as List? ?? [];
        buffer.writeln('   ✅ SUCCESS: ${products.length} products retrieved');

        if (products.isNotEmpty) {
          buffer.writeln('   Sample product:');
          final sample = products.first;
          buffer.writeln('     - Name: ${sample['name'] ?? 'N/A'}');
          buffer.writeln('     - Price: ${sample['price'] ?? 'N/A'}');
          buffer.writeln('     - Available: ${sample['isAvailable'] ?? 'N/A'}');
        }
      } else {
        buffer.writeln(
            '   ❌ FAILED: ${productsResult['message'] ?? 'Unknown error'}');
        buffer.writeln('   Status: ${productsResult['status'] ?? 'N/A'}');
        buffer.writeln('   Error: ${productsResult['error'] ?? 'N/A'}');
      }

      // Test 2: Get categories
      buffer.writeln('\n📋 Test 2: Get Categories');
      final categoriesResult = await ProductService.getAllCategories();

      if (categoriesResult['success'] == true) {
        final categories = categoriesResult['categories'] as List? ?? [];
        buffer
            .writeln('   ✅ SUCCESS: ${categories.length} categories retrieved');
      } else {
        buffer.writeln(
            '   ❌ FAILED: ${categoriesResult['message'] ?? 'Unknown error'}');
      }

      setState(() {
        _testResults = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = 'Product API test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testTokens() async {
    setState(() {
      _isLoading = true;
      _testResults = '🔑 Testing Token Processing...\n\n';
    });

    try {
      final buffer = StringBuffer();
      buffer.writeln('🔑 TOKEN PROCESSING TEST');
      buffer.writeln('=' * 50);

      // Get tokens
      final accessToken = await AppAuthService.getAccessToken();
      final idToken = await AppAuthService.getIdToken();

      if (accessToken != null) {
        buffer.writeln('\n📋 Access Token Analysis:');
        buffer.writeln('   Length: ${accessToken.length}');
        final accessPreview = accessToken.length > 50
            ? '${accessToken.substring(0, 50)}...'
            : accessToken;
        buffer.writeln('   Preview: $accessPreview');
        buffer.writeln('   Valid JWT: ${_isValidJWT(accessToken)}');
        buffer.writeln(
            '   Has whitespace: ${accessToken.contains(' ') || accessToken.contains('\n') || accessToken.contains('\r')}');

        if (_isValidJWT(accessToken)) {
          final payload = _decodeJWTPayload(accessToken);
          if (payload != null) {
            buffer.writeln('   Token Use: ${payload['token_use'] ?? 'N/A'}');
            buffer.writeln('   Issuer: ${payload['iss'] ?? 'N/A'}');
            buffer.writeln('   Subject: ${payload['sub'] ?? 'N/A'}');
            buffer.writeln('   Email: ${payload['email'] ?? 'N/A'}');

            if (payload.containsKey('exp')) {
              final exp = payload['exp'] as int?;
              if (exp != null) {
                final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
                final isExpired = DateTime.now().isAfter(expDate);
                buffer.writeln('   Expires: $expDate');
                buffer
                    .writeln('   Is Expired: ${isExpired ? "❌ YES" : "✅ NO"}');
              }
            }
          }
        }
      } else {
        buffer.writeln('\n❌ No access token available');
      }

      if (idToken != null) {
        buffer.writeln('\n📋 ID Token Analysis:');
        buffer.writeln('   Length: ${idToken.length}');
        final idPreview =
            idToken.length > 50 ? '${idToken.substring(0, 50)}...' : idToken;
        buffer.writeln('   Preview: $idPreview');
        buffer.writeln('   Valid JWT: ${_isValidJWT(idToken)}');

        if (_isValidJWT(idToken)) {
          final payload = _decodeJWTPayload(idToken);
          if (payload != null) {
            buffer.writeln('   Token Use: ${payload['token_use'] ?? 'N/A'}');
            buffer.writeln('   Email: ${payload['email'] ?? 'N/A'}');
            buffer.writeln(
                '   Email Verified: ${payload['email_verified'] ?? 'N/A'}');
          }
        }
      } else {
        buffer.writeln('\n❌ No ID token available');
      }

      setState(() {
        _testResults = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = 'Token test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testFullFlow() async {
    setState(() {
      _isLoading = true;
      _testResults = '🔄 Running Full Authentication Flow Test...\n\n';
    });

    try {
      final buffer = StringBuffer();
      buffer.writeln('🔄 FULL AUTHENTICATION FLOW TEST');
      buffer.writeln('=' * 50);

      // Step 1: Authentication check
      buffer.writeln('\n📋 Step 1: Authentication Check');
      final isSignedIn = await AppAuthService.isSignedIn();
      buffer.writeln('   Signed In: ${isSignedIn ? "✅" : "❌"}');

      if (!isSignedIn) {
        buffer.writeln('   ❌ Cannot proceed - user not authenticated');
        setState(() {
          _testResults = buffer.toString();
          _isLoading = false;
        });
        return;
      }

      // Step 2: Token retrieval
      buffer.writeln('\n📋 Step 2: Token Retrieval');
      final accessToken = await AppAuthService.getAccessToken();
      final idToken = await AppAuthService.getIdToken();

      buffer.writeln('   Access Token: ${accessToken != null ? "✅" : "❌"}');
      buffer.writeln('   ID Token: ${idToken != null ? "✅" : "❌"}');

      // Step 3: Business data
      buffer.writeln('\n📋 Step 3: Business Data');
      try {
        final apiService = ApiService();
        final businesses = await apiService.getUserBusinesses();
        buffer.writeln('   Businesses Found: ${businesses.length}');

        if (businesses.isNotEmpty) {
          final business = businesses.first;
          buffer.writeln('   Business ID: ${business['businessId'] ?? 'N/A'}');
          buffer.writeln('   Business Name: ${business['name'] ?? 'N/A'}');
          buffer.writeln('   Business Email: ${business['email'] ?? 'N/A'}');
        }
      } catch (e) {
        buffer.writeln('   ❌ Failed to get business data: $e');
      }

      // Step 4: Product API test
      buffer.writeln('\n📋 Step 4: Product API Test');
      final productsResult = await ProductService.getProducts();

      if (productsResult['success'] == true) {
        final products = productsResult['products'] as List? ?? [];
        buffer.writeln('   ✅ Products API: ${products.length} products');
      } else {
        buffer
            .writeln('   ❌ Products API failed: ${productsResult['message']}');
        buffer
            .writeln('   Error type: ${productsResult['error'] ?? 'unknown'}');
      }

      // Step 5: Categories test
      buffer.writeln('\n📋 Step 5: Categories API Test');
      final categoriesResult =
          await ProductService.getCategoriesForBusinessType('restaurant');

      if (categoriesResult['success'] == true) {
        final categories = categoriesResult['categories'] as List? ?? [];
        buffer.writeln('   ✅ Categories API: ${categories.length} categories');
      } else {
        buffer.writeln(
            '   ❌ Categories API failed: ${categoriesResult['message']}');
        buffer.writeln(
            '   Error type: ${categoriesResult['error'] ?? 'unknown'}');
      }

      // Summary
      buffer.writeln('\n📋 SUMMARY:');
      buffer.writeln('Authentication flow test completed.');
      buffer.writeln('Check individual test results above for issues.');

      setState(() {
        _testResults = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = 'Full flow test failed: $e';
        _isLoading = false;
      });
    }
  }

  bool _isValidJWT(String token) {
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  Map<String, dynamic>? _decodeJWTPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];

      // Add padding if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      // Replace URL-safe characters
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      // Decode
      final bytes = base64Decode(payload);
      final jsonString = utf8.decode(bytes);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
