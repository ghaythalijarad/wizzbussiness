import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🧪 FLUTTER FRONTEND AUTHENTICATION TEST');
  print('======================================');

  const baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
  const testEmail = 'g87_a@yahoo.com';
  const testPassword = 'Gha@551987';

  print('Backend URL: $baseUrl');
  print('Test Email: $testEmail');
  print('');

  // Test 1: Backend Health Check
  print('1️⃣ Testing Backend Connectivity from Flutter');
  print('===========================================');

  try {
    final healthResponse = await http.get(Uri.parse('$baseUrl/auth/health'));
    print('✅ Backend health: ${healthResponse.statusCode}');
    print('   Response: ${healthResponse.body}');
  } catch (e) {
    print('❌ Backend health failed: $e');
  }

  // Test 2: Email Check
  print('\n2️⃣ Testing Email Check from Flutter');
  print('=================================');

  try {
    final emailResponse = await http.post(
      Uri.parse('$baseUrl/auth/check-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': testEmail}),
    );
    print('✅ Email check: ${emailResponse.statusCode}');
    print('   Response: ${emailResponse.body}');
  } catch (e) {
    print('❌ Email check failed: $e');
  }

  // Test 3: Login Test
  print('\n3️⃣ Testing Login from Flutter');
  print('===========================');

  try {
    final loginResponse = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': testEmail,
        'password': testPassword,
      }),
    );
    print('Status: ${loginResponse.statusCode}');
    print('Response: ${loginResponse.body}');

    if (loginResponse.statusCode == 200) {
      print('✅ Login successful from Flutter!');
    } else {
      print('❌ Login failed from Flutter');
    }
  } catch (e) {
    print('❌ Login request failed: $e');
  }

  // Test 4: Registration Test
  print('\n4️⃣ Testing Registration from Flutter');
  print('==================================');

  final testRegEmail =
      'flutter_test_${DateTime.now().millisecondsSinceEpoch}@example.com';

  try {
    final regResponse = await http.post(
      Uri.parse('$baseUrl/auth/register-with-business'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': testRegEmail,
        'password': 'TestPass123!',
        'businessName': 'Flutter Test Business',
        'businessType': 'restaurant',
        'phoneNumber': '07712345678',
        'firstName': 'Flutter',
        'lastName': 'Test',
        'address': 'Test Address',
        'city': 'Baghdad',
        'district': 'Test District',
        'country': 'Iraq',
      }),
    );
    print('Status: ${regResponse.statusCode}');
    print('Response: ${regResponse.body}');

    if (regResponse.statusCode == 200) {
      print('✅ Registration successful from Flutter!');
    } else {
      print('❌ Registration failed from Flutter');
    }
  } catch (e) {
    print('❌ Registration request failed: $e');
  }

  print('\n📊 FLUTTER FRONTEND TEST SUMMARY');
  print('===============================');
  print('This test simulates what the Flutter app would do');
  print('when communicating with the backend API.');
  print('');
  print('If all tests show ✅, the Flutter frontend should work.');
  print('If login shows ❌, the issue is with authentication.');
}
