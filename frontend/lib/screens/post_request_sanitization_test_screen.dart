import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/product_service.dart';
import '../services/app_auth_service.dart';

/// Debugging screen to test POST request sanitization
class PostRequestSanitizationTestScreen extends ConsumerStatefulWidget {
  const PostRequestSanitizationTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PostRequestSanitizationTestScreen> createState() =>
      _PostRequestSanitizationTestScreenState();
}

class _PostRequestSanitizationTestScreenState
    extends ConsumerState<PostRequestSanitizationTestScreen> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
    print(result); // Also log to console
  }

  Future<void> _runPostRequestTest() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    _addResult('🧪 Starting POST Request Sanitization Test');
    _addResult('============================================');

    try {
      // Check authentication state
      _addResult('\n🔑 Checking authentication...');
      final accessToken = await AppAuthService.getAccessToken();
      final idToken = await AppAuthService.getIdToken();

      if (accessToken == null && idToken == null) {
        _addResult('❌ No tokens found. Please sign in first.');
        setState(() => _isRunning = false);
        return;
      }

      _addResult(
          '✅ Access token: ${accessToken != null ? "${accessToken.length} chars" : "none"}');
      _addResult(
          '✅ ID token: ${idToken != null ? "${idToken.length} chars" : "none"}');

      // Check for corruption patterns in stored tokens
      final tokenToCheck = idToken ?? accessToken ?? '';
      if (tokenToCheck.isNotEmpty) {
        _addResult('\n🔍 Token corruption analysis:');

        final hasCyrillic = RegExp(r'[\u0400-\u04FF]').hasMatch(tokenToCheck);
        final hasLineBreaks =
            tokenToCheck.contains('\n') || tokenToCheck.contains('\r');
        final hasSpaces = tokenToCheck.contains(' ');
        final hasQuotes =
            tokenToCheck.contains('"') || tokenToCheck.contains("'");

        _addResult('  - Contains Cyrillic chars: $hasCyrillic');
        _addResult('  - Contains line breaks: $hasLineBreaks');
        _addResult('  - Contains spaces: $hasSpaces');
        _addResult('  - Contains quotes: $hasQuotes');

        if (hasCyrillic || hasLineBreaks || hasSpaces || hasQuotes) {
          _addResult(
              '⚠️ Token shows corruption patterns - sanitization will be tested');
        } else {
          _addResult('✅ Token appears clean');
        }
      }

      // Test product creation POST request
      _addResult('\n🛒 Testing Product Creation POST Request...');

      final testProductData = {
        'name':
            'Test Product - POST Sanitization ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Testing if POST requests use sanitized tokens properly',
        'price': 19.99,
        'categoryId':
            'test-category-id-${DateTime.now().millisecondsSinceEpoch}',
        'isAvailable': true,
      };

      _addResult('📤 Making POST request to create product...');
      _addResult('📋 Product name: ${testProductData['name']}');

      try {
        final result = await ProductService.createProduct(
          name: testProductData['name'] as String,
          description: testProductData['description'] as String,
          price: testProductData['price'] as double,
          categoryId: testProductData['categoryId'] as String,
          isAvailable: testProductData['isAvailable'] as bool,
        );

        _addResult('\n📤 ProductService Response:');
        _addResult('Success: ${result['success']}');

        if (result['success'] == true) {
          _addResult('✅ SUCCESS! Product created successfully');
          _addResult('✅ Token sanitization is working for POST requests');
          _addResult(
              '📝 Created product: ${result['product']?['name'] ?? 'Unknown'}');
        } else {
          _addResult('❌ Product creation failed');
          _addResult('❌ Error: ${result['message']}');
          _addResult('❌ Error type: ${result['error']}');

          // Check for the specific corruption error
          final errorMessage = result['message']?.toString() ?? '';
          if (errorMessage.contains('Invalid key=value pair')) {
            _addResult('🚨 CORRUPTION ERROR DETECTED!');
            _addResult(
                '🚨 The "Invalid key=value pair" error is still occurring');
            _addResult('🚨 POST requests are NOT using enhanced sanitization');
          } else if (errorMessage.contains('401') ||
              errorMessage.contains('Unauthorized')) {
            _addResult(
                '⚠️ Authorization error - token may be expired but format is OK');
          } else {
            _addResult('⚠️ Other error - but no corruption error detected');
          }
        }
      } catch (e) {
        _addResult('\n💥 Exception during product creation: $e');

        if (e.toString().contains('Invalid key=value pair')) {
          _addResult('🚨 CORRUPTION ERROR in exception!');
          _addResult(
              '🚨 The token sanitization is NOT working for POST requests');
        } else if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          _addResult(
              '⚠️ Authorization exception - token may be expired but format is OK');
        } else {
          _addResult('⚠️ Other exception - but no corruption error detected');
        }
      }
    } catch (e) {
      _addResult('\n💥 Test failed with error: $e');
    }

    _addResult('\n✅ Test completed');
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POST Request Sanitization Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This test checks if POST requests for product creation are using the enhanced token sanitization that fixes the "Invalid key=value pair" error.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRunning ? null : _runPostRequestTest,
              child: _isRunning
                  ? const Text('Running Test...')
                  : const Text('Run POST Sanitization Test'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty
                        ? 'No test results yet. Run the test to see results.'
                        : _testResults.join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
