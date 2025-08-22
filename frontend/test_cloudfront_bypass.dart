#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:math';

/// Test CloudFront cache bypass strategies
/// This script tests various approaches to bypass CloudFront caching

const String baseUrl = 'https://tcpt1l16q6.execute-api.us-east-1.amazonaws.com/dev';

void main() async {
  print('🧪 CloudFront Cache Bypass Test');
  print('=================================\n');
  
  final client = HttpClient();
  
  // Test 1: Basic request (likely cached)
  print('Test 1: Basic request (baseline)');
  await testRequest(client, '/categories', {});
  
  // Test 2: Query parameter cache busting
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final random = Random().nextInt(99999).toString();
  print('\nTest 2: Query parameter cache busting');
  await testRequest(client, '/categories', {
    '_cb': timestamp,
    '_v': '2.0.2',
    '_t': timestamp,
    '_r': random,
    'nocache': 'true',
    'bypass': 'cf',
  });
  
  // Test 3: Different endpoint path
  print('\nTest 3: Different endpoint path');
  await testRequest(client, '/auth/health', {});
  
  // Test 4: HTTP/1.1 with aggressive headers
  print('\nTest 4: HTTP/1.1 with aggressive cache-busting headers');
  await testRequestWithHeaders(client, '/categories', {
    '_force': timestamp,
  }, {
    'Cache-Control': 'no-cache, no-store, must-revalidate, max-age=0',
    'Pragma': 'no-cache',
    'Expires': '0',
    'X-Requested-With': 'XMLHttpRequest',
    'X-Cache-Buster': timestamp,
    'X-Request-ID': 'flutter-$timestamp-$random',
    'X-CloudFront-Bypass': 'true',
    'X-Forwarded-For': '127.0.0.1',
    'If-None-Match': '*',
    'X-Custom-Header': random,
  });
  
  client.close();
}

Future<void> testRequest(HttpClient client, String path, Map<String, String> queryParams) async {
  try {
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: queryParams);
    final request = await client.getUrl(uri);
    final response = await request.close();
    
    print('  URL: $uri');
    print('  Status: ${response.statusCode}');
    print('  Headers:');
    
    final importantHeaders = ['x-cache', 'via', 'x-amz-cf-pop', 'x-amzn-errortype'];
    for (final header in importantHeaders) {
      if (response.headers[header] != null) {
        print('    $header: ${response.headers[header]}');
      }
    }
    
    final isCloudFront = response.headers['via']?.any((v) => v.contains('cloudfront')) ?? false;
    final isCached = response.headers['x-cache']?.any((v) => v.contains('cloudfront')) ?? false;
    
    print('  CloudFront: $isCloudFront');
    print('  Cached: $isCached');
    
    if (isCloudFront && isCached) {
      print('  ❌ Request is being served by CloudFront cache');
    } else if (response.statusCode == 200) {
      print('  ✅ Request succeeded (not cached)');
    } else {
      print('  ⚠️ Request failed but may not be cached');
    }
    
  } catch (e) {
    print('  ❌ Error: $e');
  }
}

Future<void> testRequestWithHeaders(HttpClient client, String path, Map<String, String> queryParams, Map<String, String> headers) async {
  try {
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: queryParams);
    final request = await client.getUrl(uri);
    
    // Add custom headers
    headers.forEach((key, value) {
      request.headers.add(key, value);
    });
    
    final response = await request.close();
    
    print('  URL: $uri');
    print('  Status: ${response.statusCode}');
    print('  Custom headers count: ${headers.length}');
    
    final importantHeaders = ['x-cache', 'via', 'x-amz-cf-pop', 'x-amzn-errortype'];
    for (final header in importantHeaders) {
      if (response.headers[header] != null) {
        print('    $header: ${response.headers[header]}');
      }
    }
    
    final isCloudFront = response.headers['via']?.any((v) => v.contains('cloudfront')) ?? false;
    final isCached = response.headers['x-cache']?.any((v) => v.contains('cloudfront')) ?? false;
    
    print('  CloudFront: $isCloudFront');
    print('  Cached: $isCached');
    
    if (isCloudFront && isCached) {
      print('  ❌ Request is still being served by CloudFront cache');
    } else if (response.statusCode == 200) {
      print('  ✅ Request succeeded (bypassed cache)');
    } else {
      print('  ⚠️ Request failed but may have bypassed cache');
    }
    
  } catch (e) {
    print('  ❌ Error: $e');
  }
}
