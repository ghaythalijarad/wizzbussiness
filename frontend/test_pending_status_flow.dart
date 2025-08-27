import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 TESTING PENDING STATUS FLOW');
  print('================================');

  // Test login API directly
  final loginUrl = 'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin';
  
  final loginPayload = {
    'email': 'g87_a@yahoo.com',
    'password': 'Gha@551987',
  };

  try {
    print('🔐 Testing login API directly...');
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(loginPayload),
    );

    print('📡 Response Status: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('\n✅ Login successful!');
      
      if (data['businesses'] != null && data['businesses'].isNotEmpty) {
        final business = data['businesses'][0];
        print('\n🏢 Business Data:');
        print('   ID: ${business['businessId'] ?? business['id']}');
        print('   Name: ${business['name']}');
        print('   Status: "${business['status']}"');
        print('   Status Length: ${business['status']?.length}');
        
        // Test status matching
        final status = business['status']?.toString()?.toLowerCase();
        print('\n🎯 Status Routing Test:');
        if (status == 'approved') {
          print('   ✅ Would route to BusinessDashboard');
        } else if (status == 'pending') {
          print('   ⏸️ Would route to MerchantStatusScreen (pending)');
        } else if (status == 'rejected') {
          print('   ❌ Would route to MerchantStatusScreen (rejected)');
        } else if (status == 'under_review') {
          print('   🔍 Would route to MerchantStatusScreen (under_review)');
        } else {
          print('   ❓ Would route to MerchantStatusScreen (unknown: "$status")');
        }
      } else {
        print('❌ No businesses found in response');
      }
    } else {
      print('❌ Login failed: ${response.body}');
    }
  } catch (e) {
    print('💥 Error: $e');
  }
}
