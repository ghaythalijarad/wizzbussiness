import 'package:http/http.dart' as http;

/// A custom HTTP client for the application.
class AppHttpClient {
  static const int _logPreviewLimit = 400;

  // Add cache-busting parameters to bypass CloudFront cache
  static Uri _addCacheBusting(Uri originalUri) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomSuffix = (DateTime.now().microsecond % 9999).toString();
    final Map<String, String> queryParams = Map.from(originalUri.queryParameters);
    queryParams['_cb'] = timestamp;        // Cache buster
    queryParams['_v'] = '2.0.2';          // Version parameter
    queryParams['_t'] = timestamp;         // Additional timestamp
    queryParams['_r'] = randomSuffix;      // Random component
    queryParams['nocache'] = 'true';      // No cache flag
    queryParams['bypass'] = 'cf';         // CloudFront bypass hint
    
    return originalUri.replace(queryParameters: queryParams);
  }

  // Add cache-busting headers that CloudFront typically respects
  static Map<String, String> _addCacheBustingHeaders(Map<String, String> headers) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomId = (DateTime.now().microsecond % 99999).toString();
    return {
      ...headers,
      'Cache-Control': 'no-cache, no-store, must-revalidate, max-age=0',
      'Pragma': 'no-cache',
      'Expires': '0',
      'X-Requested-With': 'XMLHttpRequest',
      'X-Cache-Buster': timestamp,
      'X-Request-ID': 'flutter-${timestamp}-${randomId}',
      'X-CloudFront-Bypass': 'true',
      'X-Forwarded-For': '127.0.0.1',
      'If-None-Match': '*',
      'X-Custom-Header': randomId,
    };
  }

  static Map<String, String> _maskedHeaders(Map<String, String> original) {
    final copy = Map<String, String>.from(original);
    if (copy.containsKey('Authorization')) {
      final v = copy['Authorization']!;
      // Handle both Bearer tokens and direct JWT tokens
      if (v.toLowerCase().startsWith('bearer ')) {
        final token = v.substring(7);
        final preview =
            token.length > 12 ? token.substring(0, 12) + '…' : token;
        copy['Authorization'] = 'Bearer $preview';
      } else {
        // Direct JWT token without Bearer prefix
        final preview = v.length > 12 ? v.substring(0, 12) + '…' : v;
        copy['Authorization'] = preview;
      }
    }
    return copy;
  }

  static String _truncate(String input) {
    if (input.length <= _logPreviewLimit) return input;
    return input.substring(0, _logPreviewLimit) + '…';
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    // Add cache-busting parameters to bypass CloudFront cache
    final cacheBustedUrl = _addCacheBusting(url);
    
    final baseHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    // Add cache-busting headers that CloudFront typically respects
    final allHeaders = _addCacheBustingHeaders(baseHeaders);

    // Note: Authorization header is now passed directly from ApiService
    // without Bearer prefix for AWS API Gateway Cognito Authorizer

    final masked = _maskedHeaders(allHeaders);
    final bodyStr = body?.toString() ?? '(null)';
    final bodyPreview = _truncate(bodyStr);

    print('🌐 [AppHttpClient] --------------------------------------------------');
    print('🌐 [AppHttpClient] ➡️ POST $cacheBustedUrl');
    if (cacheBustedUrl != url) {
      print('🌐 [AppHttpClient]    ⚡ Cache-busting enabled (URL + Headers)');
    }
    print('🌐 [AppHttpClient]    Headers: $masked');
    print('🌐 [AppHttpClient]    Body: $bodyPreview');
    print('🌐 [AppHttpClient] --------------------------------------------------');

    try {
      final response = await http
          .post(
        cacheBustedUrl,
        headers: allHeaders,
        body: body,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      final respBodyPreview = _truncate(response.body);
      final maskedRespHeaders = _maskedHeaders(response.headers);
      print('🌐 [AppHttpClient] --------------------------------------------------');
      print('🌐 [AppHttpClient] ⬅️ ${response.statusCode} POST $cacheBustedUrl');
      
      // Check for CloudFront cache headers
      if (response.headers.containsKey('x-cache')) {
        final cacheStatus = response.headers['x-cache'];
        if (cacheStatus?.contains('Hit') == true) {
          print('🌐 [AppHttpClient]    ⚠️ CloudFront Cache HIT: $cacheStatus');
        } else if (cacheStatus?.contains('Miss') == true) {
          print('🌐 [AppHttpClient]    ✅ CloudFront Cache MISS: $cacheStatus');
        } else {
          print('🌐 [AppHttpClient]    🔍 CloudFront Status: $cacheStatus');
        }
      }
      
      print('🌐 [AppHttpClient]    Response Headers: $maskedRespHeaders');
      print('🌐 [AppHttpClient]    Response Body: $respBodyPreview');
      print('🌐 [AppHttpClient] --------------------------------------------------');

      return response;
    } catch (e) {
      print('🌐 [AppHttpClient] --------------------------------------------------');
      print('🌐 [AppHttpClient] ❌ ERROR on POST $cacheBustedUrl');
      print('🌐 [AppHttpClient]    Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    // Add cache-busting parameters to bypass CloudFront cache
    final cacheBustedUrl = _addCacheBusting(url);
    
    final baseHeaders = {
      'Accept': 'application/json',
      ...?headers,
    };

    // Add cache-busting headers that CloudFront typically respects
    final allHeaders = _addCacheBustingHeaders(baseHeaders);

    // Note: Authorization header is now passed directly from ApiService
    // without Bearer prefix for AWS API Gateway Cognito Authorizer

    try {
      final masked = _maskedHeaders(allHeaders);
      print('🌐 [AppHttpClient] Making GET request to: $cacheBustedUrl');
      if (cacheBustedUrl != url) {
        print('🌐 [AppHttpClient] ⚡ Cache-busting enabled');
      }
      print('🌐 [AppHttpClient] Headers: $masked');

      final response = await http
          .get(
        cacheBustedUrl,
        headers: allHeaders,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      final maskedRespHeaders = _maskedHeaders(response.headers);
      print('🌐 [AppHttpClient] Response status: ${response.statusCode}');
      
      // Check for CloudFront cache headers
      if (response.headers.containsKey('x-cache')) {
        final cacheStatus = response.headers['x-cache'];
        if (cacheStatus?.contains('Hit') == true) {
          print('🌐 [AppHttpClient] ⚠️ CloudFront Cache HIT: $cacheStatus');
        } else if (cacheStatus?.contains('Miss') == true) {
          print('🌐 [AppHttpClient] ✅ CloudFront Cache MISS: $cacheStatus');
        } else {
          print('🌐 [AppHttpClient] 🔍 CloudFront Status: $cacheStatus');
        }
      }
      
      print('🌐 [AppHttpClient] Response headers: $maskedRespHeaders');
      final respBodyPreview = _truncate(response.body);
      print('🌐 [AppHttpClient] Response body: $respBodyPreview');
      return response;
    } catch (e) {
      print('🌐 [AppHttpClient] Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    // Add cache-busting parameters to bypass CloudFront cache
    final cacheBustedUrl = _addCacheBusting(url);
    
    final baseHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    // Add cache-busting headers that CloudFront typically respects
    final allHeaders = _addCacheBustingHeaders(baseHeaders);

    // Note: Authorization header is now passed directly from ApiService
    // without Bearer prefix for AWS API Gateway Cognito Authorizer

    final masked = _maskedHeaders(allHeaders);
    final bodyStr = body?.toString() ?? '(null)';
    final bodyPreview = _truncate(bodyStr);

    print('🌐 [AppHttpClient] --------------------------------------------------');
    print('🌐 [AppHttpClient] ➡️ PUT $cacheBustedUrl');
    if (cacheBustedUrl != url) {
      print('🌐 [AppHttpClient]    ⚡ Cache-busting enabled');
    }
    print('🌐 [AppHttpClient]    Headers: $masked');
    print('🌐 [AppHttpClient]    Body: $bodyPreview');
    print('🌐 [AppHttpClient] --------------------------------------------------');

    try {
      final response = await http
          .put(
        cacheBustedUrl,
        headers: allHeaders,
        body: body,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      final respBodyPreview = _truncate(response.body);
      final maskedRespHeaders = _maskedHeaders(response.headers);
      print('🌐 [AppHttpClient] --------------------------------------------------');
      print('🌐 [AppHttpClient] ⬅️ ${response.statusCode} PUT $cacheBustedUrl');
      
      // Check for CloudFront cache headers
      if (response.headers.containsKey('x-cache')) {
        final cacheStatus = response.headers['x-cache'];
        if (cacheStatus?.contains('Hit') == true) {
          print('🌐 [AppHttpClient]    ⚠️ CloudFront Cache HIT: $cacheStatus');
        } else if (cacheStatus?.contains('Miss') == true) {
          print('🌐 [AppHttpClient]    ✅ CloudFront Cache MISS: $cacheStatus');
        } else {
          print('🌐 [AppHttpClient]    🔍 CloudFront Status: $cacheStatus');
        }
      }
      
      print('🌐 [AppHttpClient]    Response Headers: $maskedRespHeaders');
      print('🌐 [AppHttpClient]    Response Body: $respBodyPreview');
      print('🌐 [AppHttpClient] --------------------------------------------------');

      return response;
    } catch (e) {
      print('🌐 [AppHttpClient] --------------------------------------------------');
      print('🌐 [AppHttpClient] ❌ ERROR on PUT $cacheBustedUrl');
      print('🌐 [AppHttpClient]    Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    // Add cache-busting parameters to bypass CloudFront cache
    final cacheBustedUrl = _addCacheBusting(url);
    
    final baseHeaders = {
      'Accept': 'application/json',
      ...?headers,
    };

    // Add cache-busting headers that CloudFront typically respects
    final allHeaders = _addCacheBustingHeaders(baseHeaders);

    // Note: Authorization header is now passed directly from ApiService
    // without Bearer prefix for AWS API Gateway Cognito Authorizer

    try {
      final masked = _maskedHeaders(allHeaders);
      print('🌐 [AppHttpClient] Making DELETE request to: $cacheBustedUrl');
      if (cacheBustedUrl != url) {
        print('🌐 [AppHttpClient] ⚡ Cache-busting enabled');
      }
      print('🌐 [AppHttpClient] Headers: $masked');

      final response = await http
          .delete(
        cacheBustedUrl,
        headers: allHeaders,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      final maskedRespHeaders = _maskedHeaders(response.headers);
      print('🌐 [AppHttpClient] Response status: ${response.statusCode}');
      
      // Check for CloudFront cache headers
      if (response.headers.containsKey('x-cache')) {
        final cacheStatus = response.headers['x-cache'];
        if (cacheStatus?.contains('Hit') == true) {
          print('🌐 [AppHttpClient] ⚠️ CloudFront Cache HIT: $cacheStatus');
        } else if (cacheStatus?.contains('Miss') == true) {
          print('🌐 [AppHttpClient] ✅ CloudFront Cache MISS: $cacheStatus');
        } else {
          print('🌐 [AppHttpClient] 🔍 CloudFront Status: $cacheStatus');
        }
      }
      
      print('🌐 [AppHttpClient] Response headers: $maskedRespHeaders');
      final respBodyPreview = _truncate(response.body);
      print('🌐 [AppHttpClient] Response body: $respBodyPreview');
      return response;
    } catch (e) {
      print('🌐 [AppHttpClient] Error: $e');
      rethrow;
    }
  }
}
