// Test script to verify business photo upload functionality
// Run this test to ensure the business photo upload works during registration

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl =
    'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

void main() async {
  print('🧪 Testing Business Photo Upload Endpoint...\n');

  await testBusinessPhotoUpload();
}

Future<void> testBusinessPhotoUpload() async {
  try {
    print('📤 Testing business photo upload to public endpoint...');

    // Create a test multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/business-photo'),
    );

    // Add a mock file (we'll just send some test data)
    request.files.add(
      http.MultipartFile.fromString(
        'image',
        'mock-image-data',
        filename: 'test-business-photo.jpg',
      ),
    );

    print('🔗 Endpoint: $baseUrl/upload/business-photo');
    print('🚀 Sending request...');

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📊 Response Status: ${response.statusCode}');
    print('📋 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        print('✅ SUCCESS: Business photo upload endpoint is working!');
        print('🖼️  Mock Image URL: ${responseData['imageUrl']}');
        print('💬 Message: ${responseData['message']}');
      } else {
        print(
            '❌ FAILED: Upload request was processed but returned success: false');
        print('💬 Message: ${responseData['message']}');
      }
    } else {
      print('❌ FAILED: HTTP ${response.statusCode}');
      print('💬 Response: ${response.body}');
    }
  } catch (e) {
    print('❌ ERROR: Exception occurred during test');
    print('💬 Error: $e');
  }

  print('\n' + '=' * 60);
  print('📝 TEST SUMMARY:');
  print('This test verifies that the business photo upload endpoint');
  print('works without requiring authentication tokens.');
  print(
      '✅ If successful, users can now upload business photos during registration!');
  print('=' * 60);
}
