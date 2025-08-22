// Simplified diagnostic without complex provider setup
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SimpleDiagnosticApp());
}

class SimpleDiagnosticApp extends StatelessWidget {
  const SimpleDiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simple Product Diagnostic'),
          backgroundColor: Colors.blue,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: DiagnosticWidget(),
        ),
      ),
    );
  }
}

class DiagnosticWidget extends StatefulWidget {
  const DiagnosticWidget({super.key});

  @override
  State<DiagnosticWidget> createState() => _DiagnosticWidgetState();
}

class _DiagnosticWidgetState extends State<DiagnosticWidget> {
  String _log = 'Ready to test...';
  bool _testing = false;

  void _append(String message) {
    setState(() {
      _log += '\n$message';
    });
    print(message);
  }

  Future<void> _runTest() async {
    setState(() {
      _testing = true;
      _log = 'Starting diagnostic test...\n';
    });

    try {
      _append('📱 Testing from iOS simulator');
      _append('🔗 Testing API connectivity...');

      // Test basic connectivity to API Gateway
      const apiUrl =
          'https://s8nf89antk.execute-api.us-east-1.amazonaws.com/Prod';
      _append('🌐 API URL: $apiUrl');

      // Test unauthenticated endpoint first
      try {
        final healthResponse = await http.get(
          Uri.parse('$apiUrl/auth/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        _append('✅ Health check: ${healthResponse.statusCode}');
        if (healthResponse.statusCode == 200) {
          _append('📡 API Gateway is reachable');
        }
      } catch (e) {
        _append('⚠️ Health check failed: $e');
      }

      // Test /products endpoint (should fail with auth error, not white screen)
      _append('🛒 Testing /products endpoint without auth...');
      try {
        final productsResponse = await http.get(
          Uri.parse('$apiUrl/products'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        _append('📊 Products endpoint status: ${productsResponse.statusCode}');
        _append('📄 Response body: ${productsResponse.body}');

        if (productsResponse.body.contains('Invalid key=value pair')) {
          _append('✅ CONFIRMED: Products endpoint has AWS_IAM auth issue');
          _append('🔧 FIX NEEDED: Deploy backend with JWT authorizer');
        } else {
          _append('❓ Unexpected response from products endpoint');
        }
      } catch (e) {
        _append('❌ Products test failed: $e');
      }

      _append('🏁 Diagnostic complete');
    } catch (e) {
      _append('💥 Test failed: $e');
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_testing) const LinearProgressIndicator(),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _testing ? null : _runTest,
          child: Text(_testing ? 'Testing...' : 'Run Diagnostic'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                _log,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
