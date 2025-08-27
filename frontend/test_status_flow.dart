import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/models/business.dart';
import 'lib/services/app_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 TESTING STATUS FLOW FOR g87_a@yahoo.com');
  print('=============================================');

  try {
    // Initialize AppAuthService
    await AppAuthService.initialize();

    // Test login with the known pending account
    final email = 'g87_a@yahoo.com';
    final password = 'Gha@551987';

    print('🔐 Attempting login with $email...');
    final result =
        await AppAuthService.signIn(email: email, password: password);

    print('📡 Login result:');
    print('   Success: ${result.success}');
    print('   Message: ${result.message}');
    print('   User: ${result.user != null ? "Present" : "Null"}');
    print('   Businesses count: ${result.businesses.length}');

    if (result.success && result.businesses.isNotEmpty) {
      print('\n🏢 BUSINESS DATA ANALYSIS:');

      final businessData = result.businesses.first;
      print('   Raw business data: $businessData');

      // Test Business.fromJson parsing
      try {
        final business = Business.fromJson(businessData);
        print('\n✅ Business object created successfully:');
        print('   Business ID: ${business.id}');
        print('   Business Name: ${business.name}');
        print('   Business Email: ${business.email}');
        print('   Business Status: "${business.status}"');
        print('   Business Type: ${business.businessType}');

        // Test status logic
        print('\n🎯 STATUS ROUTING TEST:');
        if (business.status == 'approved') {
          print('   ✅ STATUS: approved → Should route to BusinessDashboard');
        } else if (business.status == 'pending') {
          print(
              '   ⚠️  STATUS: pending → Should route to MerchantStatusScreen');
        } else if (business.status == 'rejected') {
          print('   ❌ STATUS: rejected → Should route to MerchantStatusScreen');
        } else if (business.status == 'under_review') {
          print(
              '   🔍 STATUS: under_review → Should route to MerchantStatusScreen');
        } else {
          print(
              '   ❓ STATUS: "${business.status}" → Should route to MerchantStatusScreen (unknown status)');
        }

        // Test specific value comparison
        print('\n🔍 DETAILED STATUS ANALYSIS:');
        print('   Status string: "${business.status}"');
        print('   Status length: ${business.status.length}');
        print('   Status bytes: ${business.status.codeUnits}');
        print('   Is exactly "pending": ${business.status == "pending"}');
        print('   Contains "pending": ${business.status.contains("pending")}');
        print('   Trimmed status: "${business.status.trim()}"');
        print(
            '   Is trimmed "pending": ${business.status.trim() == "pending"}');
      } catch (businessError) {
        print('❌ Error creating Business object: $businessError');
      }
    } else {
      print('❌ Login failed or no businesses found');
    }
  } catch (e) {
    print('❌ Test failed with error: $e');
  }

  print('\n✅ Status flow test completed');
}
