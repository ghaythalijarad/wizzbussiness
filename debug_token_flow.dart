#!/usr/bin/env dart

// Debug script to test the complete token flow with the fixed login logic
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('🔍 DEBUGGING COMPLETE TOKEN FLOW');
  print('================================\n');

  print('📋 Testing complete login flow:');
  print('1. Backend API call for authentication');
  print('2. Token storage in SharedPreferences');
  print('3. Token retrieval for business data fetch');
  print('4. Session establishment\n');

  // Test 1: Backend Login API
  print('🌐 Step 1: Testing backend login API...');
  
  final loginUrl = 'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin';
  final client = HttpClient();
  
  try {
    final uri = Uri.parse(loginUrl);
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType('application', 'json');
    
    final loginData = {
      'email': 'g87_a@yahoo.com',
      'password': 'Gha@551987',
    };
    
    request.write(jsonEncode(loginData));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📡 Login API Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      print('✅ Login successful');
      print('📄 Response structure:');
      print('   - success: ${data['success']}');
      print('   - user: ${data['user'] != null ? "Present" : "Missing"}');
      print('   - businesses: ${data['businesses']?.length ?? 0} found');
      print('   - data: ${data['data'] != null ? "Present" : "Missing"}');
      
      if (data['data'] != null) {
        final authData = data['data'];
        print('🔑 Authentication tokens:');
        print('   - AccessToken: ${authData['AccessToken'] != null ? "${authData['AccessToken'].toString().length} chars" : "Missing"}');
        print('   - IdToken: ${authData['IdToken'] != null ? "${authData['IdToken'].toString().length} chars" : "Missing"}');
        print('   - RefreshToken: ${authData['RefreshToken'] != null ? "${authData['RefreshToken'].toString().length} chars" : "Missing"}');
        
        // Test token storage simulation
        print('\n💾 Step 2: Testing token storage...');
        final accessToken = authData['AccessToken'];
        if (accessToken != null && accessToken.isNotEmpty) {
          print('✅ Access token ready for storage');
          print('📏 Token length: ${accessToken.length}');
          print('📝 Token format valid: ${_isValidJWT(accessToken)}');
          
          // Test business API with token
          print('\n🏢 Step 3: Testing business data fetch with token...');
          await _testBusinessDataFetch(accessToken);
        } else {
          print('❌ No access token in response');
        }
      } else {
        print('❌ No authentication data in response');
      }
    } else {
      print('❌ Login failed: ${response.statusCode}');
      print('📄 Error response: $responseBody');
    }
  } catch (e) {
    print('💥 Login API error: $e');
  } finally {
    client.close();
  }
  
  print('\n🎯 ANALYSIS:');
  print('The token storage issue occurs because:');
  print('1. AppAuthService.signIn() gets tokens from backend ✅');
  print('2. _storeAuthTokens() should store them in SharedPreferences ❓');
  print('3. When AuthWrapper tries to get business data, it calls AppAuthService.getAccessToken() ❓');
  print('4. If storage failed, getAccessToken() returns null ❌');
  print('\n🔧 Next step: Fix the _storeAuthTokens() method in AppAuthService');
}

bool _isValidJWT(String token) {
  if (token.isEmpty) return false;
  final parts = token.split('.');
  return parts.length == 3;
}

Future<void> _testBusinessDataFetch(String accessToken) async {
  final businessUrl = 'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/user-businesses';
  final client = HttpClient();
  
  try {
    final uri = Uri.parse(businessUrl);
    final request = await client.getUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $accessToken');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📡 Business API Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      print('✅ Business data fetch successful');
      print('🏢 Businesses found: ${(data as List).length}');
      
      if ((data as List).isNotEmpty) {
        final business = data.first;
        print('📋 First business:');
        print('   - businessId: ${business['businessId']}');
        print('   - email: ${business['email']}');
        print('   - status: ${business['status']}');
      }
    } else {
      print('❌ Business data fetch failed: ${response.statusCode}');
      print('📄 Error response: $responseBody');
    }
  } catch (e) {
    print('💥 Business API error: $e');
  } finally {
    client.close();
  }
}
