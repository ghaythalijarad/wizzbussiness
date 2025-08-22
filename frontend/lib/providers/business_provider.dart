import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import 'session_provider.dart';

final businessProvider = FutureProvider<Business?>((ref) async {
  final session = ref.watch(sessionProvider);
  final apiService = ApiService();

  print('🏢 BusinessProvider: session.isAuthenticated = ${session.isAuthenticated}');
  print('🏢 BusinessProvider: session.businessId = ${session.businessId}');

  if (session.isAuthenticated) {
    try {
      print('🏢 BusinessProvider: Fetching user businesses...');
      final businesses = await apiService.getUserBusinesses();
      print('🏢 BusinessProvider: Got ${businesses.length} businesses');
      
      // Debug: Print the structure of the first business
      if (businesses.isNotEmpty) {
        print('🏢 BusinessProvider: First business keys: ${businesses.first.keys.toList()}');
        print('🏢 BusinessProvider: First business data: ${businesses.first}');
      }
      
      if (businesses.isNotEmpty) {
        // If we have a specific businessId in session, try to find that business
        if (session.businessId != null) {
          print('🏢 BusinessProvider: Looking for businessId ${session.businessId}');
          
          // Find the matching business
          Map<String, dynamic>? businessData;
          try {
            businessData = businesses.firstWhere(
              (b) => b['businessId'] == session.businessId,
            );
            print('🏢 BusinessProvider: Found matching business ${businessData['businessName']}');
          } catch (e) {
            print('🏢 BusinessProvider: No matching business found, using first business');
            businessData = businesses.first;
          }
          
          final business = Business.fromJson(businessData);
          print('🏢 BusinessProvider: Created business object - ID: ${business.id}, Name: ${business.name}');
          
          // Update session with the actual business ID if it was different
          if (business.id != session.businessId) {
            print('🔄 BusinessProvider: Updating session with correct businessId: ${business.id}');
            ref.read(sessionProvider.notifier).setSession(business.id);
          }
          
          return business;
        } else {
          print('🏢 BusinessProvider: No specific businessId, using first business and updating session');
          // No specific businessId, use the first business and update session
          final businessData = businesses.first;
          final business = Business.fromJson(businessData);
          print('🏢 BusinessProvider: Created business object - ID: ${business.id}, Name: ${business.name}');
          
          // Update session with the business ID
          ref.read(sessionProvider.notifier).setSession(business.id);
          
          return business;
        }
      } else {
        print('🏢 BusinessProvider: No businesses found for user');
      }
    } catch (e) {
      print('❌ BusinessProvider: Error fetching business details: $e');
      
      // Only rethrow authentication errors - for other errors, try to maintain session
      if (e.toString().contains('401') ||
          e.toString().contains('Invalid or expired access token') ||
          e.toString().contains('Missing or invalid authorization header')) {
        print('🧹 BusinessProvider: Authentication error detected, propagating error');
        rethrow;
      } else {
        print('ℹ️ BusinessProvider: Non-auth error, returning null but maintaining session');
        // For temporary API issues, don't break the entire flow
        return null;
      }
    }
  } else {
    print('🏢 BusinessProvider: User not authenticated');
  }
  return null;
});
