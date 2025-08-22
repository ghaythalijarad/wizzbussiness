// Diagnostic entrypoint to test product fetching end-to-end.
// Usage:
// flutter run -d iPhone 16 Pro -t lib/diagnostics/product_fetch_diagnostic.dart \
//   --dart-define=AUTH_MODE=cognito \
//   --dart-define=COGNITO_USER_POOL_ID=us-east-1_PHPkG78b5 \
//   --dart-define=APP_CLIENT_ID=1tl9g7nk2k2chtj5fg960fgdth \
//   --dart-define=COGNITO_REGION=us-east-1 \
//   --dart-define=ENVIRONMENT=development \
//   --dart-define=API_URL=https://s8nf89antk.execute-api.us-east-1.amazonaws.com/Prod \
//   --dart-define=WEBSOCKET_URL=wss://mnbzrgc0o4.execute-api.us-east-1.amazonaws.com/dev
//
// NOTE: Contains test credentials for controlled diagnostic only.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_auth_service.dart';
import '../services/product_service.dart';
import '../services/api_service.dart';

const _email = 'g87_a@yahoo.com';
const _password = 'Gha@551987';

void main() {
  // Global error capture to surface sync errors causing white screen
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🧪 [DiagMain] Initializing app');
    runApp(const ProviderScope(child: ProductFetchDiagnosticApp()));
  }, (e, st) {
    // Print full error so it appears in flutter logs
    // ignore: avoid_print
    print('💥 Uncaught zone error: $e');
    // ignore: avoid_print
    print(st);
  });
}

class ProductFetchDiagnosticApp extends StatefulWidget {
  const ProductFetchDiagnosticApp({super.key});
  @override
  State<ProductFetchDiagnosticApp> createState() =>
      _ProductFetchDiagnosticAppState();
}

class _ProductFetchDiagnosticAppState extends State<ProductFetchDiagnosticApp> {
  String _log = 'Starting...';
  bool _loading = true;
  bool _hasStarted = false;

  void _append(String line) {
    debugPrint(line);
    setState(() => _log += '\n' + line);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStarted) {
      _hasStarted = true;
      _run();
    }
  }

  Future<void> _run() async {
    _append('🧪 Begin run()');
    try {
      AppAuthService.setProviderContainer(ProviderScope.containerOf(context));
      _append('🚀 Product Fetch Diagnostic started');
      final signIn =
          await AppAuthService.signIn(email: _email, password: _password);
      _append(
          '🔐 Sign-in attempt complete success=${signIn.success} msg=${signIn.message}');
      final authState = await ApiService.debugAuthState();
      _append('🔎 Auth state: $authState');
      if (!signIn.success) {
        _append('❌ Sign-in failed: ${signIn.message}');
        setState(() => _loading = false);
        return;
      }
      _append('✅ Sign-in success. Businesses: ${signIn.businesses.length}');

      _append('🌐 Fetching products...');
      final productsResp = await ProductService.getProducts();
      _append(
          '🌐 Products response success=${productsResp['success']} status=${productsResp['status']}');
      if (productsResp['success'] == true) {
        final products = productsResp['products'] as List? ?? [];
        _append('✅ Products fetched: count=${products.length}');
        for (int i = 0; i < (products.length > 5 ? 5 : products.length); i++) {
          final p = products[i];
          _append('  • ${p['productId'] ?? p['id']}: ${p['name']}');
        }
      } else {
        _append('❌ Failed to fetch products: ${productsResp['message']}');
        _append('   Raw: ${productsResp['body'] ?? productsResp}');
      }
      _append('🏁 Diagnostic complete');
    } catch (e, st) {
      _append('💥 Exception in _run: $e');
      _append(st.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Product Fetch Diagnostic')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_log,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 13)),
                ),
              ),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _log = '';
                          _loading = true;
                          _hasStarted = false;
                        });
                      },
                child: const Text('Re-run'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
