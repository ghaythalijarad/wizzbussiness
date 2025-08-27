import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../services/app_auth_service.dart';
import 'session_provider.dart';

final businessProvider = FutureProvider<Business?>((ref) async {
  final session = ref.watch(sessionProvider);
  
  debugPrint('🏢 BusinessProvider: === BUSINESS FETCH STARTED ===');
  debugPrint('🏢 BusinessProvider: Session authenticated: ${session.isAuthenticated}');
  debugPrint('🏢 BusinessProvider: Business ID: ${session.businessId}');
  debugPrint('🏢 BusinessProvider: Last login time: ${session.lastLoginTime}');
  
  if (!session.isAuthenticated || session.businessId == null) {
    debugPrint('🏢 BusinessProvider: No valid session, returning null');
    return null;
  }

  try {
    debugPrint('🏢 BusinessProvider: Checking for stored business data in session...');
    
    // First check if we have business data stored in the session (from login response)
    if (session.businessData != null) {
      debugPrint('🏢 BusinessProvider: Found stored business data in session');
      debugPrint('🏢 BusinessProvider: Business data keys: ${session.businessData!.keys}');
      debugPrint(
          '🏢 BusinessProvider: RAW Business data: ${session.businessData!}');
      
      try {
        final business = Business.fromJson(session.businessData!);
        debugPrint('🏢 BusinessProvider: Created business from stored data');
        debugPrint('🏢 BusinessProvider: Business name: ${business.name}');
        debugPrint('🏢 BusinessProvider: Business status: ${business.status}');
        debugPrint('🏢 BusinessProvider: Business city: ${business.city}');
        debugPrint(
            '🏢 BusinessProvider: Business district: ${business.district}');
        debugPrint('🏢 BusinessProvider: Business street: ${business.street}');
        debugPrint(
            '🏢 BusinessProvider: Business country: ${business.country}');
        debugPrint('🏢 BusinessProvider: === BUSINESS FETCH COMPLETED (STORED DATA) ===');
        return business;
      } catch (e) {
        debugPrint('🏢 BusinessProvider: Error creating business from stored data: $e');
        // Fall through to other methods
      }
    }
    
    debugPrint('🏢 BusinessProvider: No stored business data, attempting to get current user data...');
    
    // First try to get user data from AppAuthService (which may have cached business info)
    final currentUser = await AppAuthService.getCurrentUser();
    
    if (currentUser != null) {
      debugPrint('🏢 BusinessProvider: Got current user, checking for business data...');
      
      // Try to get businesses using the more reliable method
      try {
        debugPrint('🏢 BusinessProvider: Trying to get business data from stored session...');
        
        // Create a mock business from session data for now
        // This is a temporary approach until we implement proper business data caching
        final business = Business(
          id: session.businessId!,
          name: 'Loading Business...', // Will be updated once we get real data
          email: currentUser['email'] ?? 'unknown@example.com',
          status: 'pending', // Default to pending, will be updated
          businessType: BusinessType.restaurant,
        );
        
        debugPrint('🏢 BusinessProvider: Created temporary business object');
        debugPrint('🏢 BusinessProvider: Business name: ${business.name}');
        debugPrint('🏢 BusinessProvider: Business status: ${business.status}');
        debugPrint('🏢 BusinessProvider: === BUSINESS FETCH COMPLETED (TEMPORARY) ===');
        return business;
        
      } catch (e) {
        debugPrint('🏢 BusinessProvider: Error in temporary approach: $e');
      }
    }
    
    debugPrint('🏢 BusinessProvider: Fallback to API call...');
    // Fallback to API call if needed (this might still fail but we'll handle it)
    try {
      final apiService = ApiService();
      final businesses = await apiService.getUserBusinesses();
      
      debugPrint('🏢 BusinessProvider: API call successful, got ${businesses.length} businesses');
      
      if (businesses.isNotEmpty) {
        // Find the business that matches the session business ID
        debugPrint('🏢 BusinessProvider: Looking for business with ID: ${session.businessId}');
        
        final businessData = businesses.firstWhere(
          (business) {
            final businessId = business['businessId'] ?? business['id'];
            debugPrint('🏢 BusinessProvider: Checking business: $businessId');
            return businessId == session.businessId;
          },
          orElse: () {
            debugPrint('🏢 BusinessProvider: No exact match found, using first business');
            return businesses.first;
          },
        );

        debugPrint('🏢 BusinessProvider: Selected business data: $businessData');
        final business = Business.fromJson(businessData);
        debugPrint('🏢 BusinessProvider: Business object created successfully');
        debugPrint('🏢 BusinessProvider: Business name: ${business.name}');
        debugPrint('🏢 BusinessProvider: Business status: ${business.status}');
        debugPrint('🏢 BusinessProvider: === BUSINESS FETCH COMPLETED SUCCESSFULLY ===');
        return business;
      }
    } catch (apiError) {
      debugPrint('🏢 BusinessProvider: API call failed: $apiError');
      debugPrint('🏢 BusinessProvider: This is expected if /auth/user-businesses endpoint has issues');
      
      // Return a default business object so the app doesn't crash
      final business = Business(
        id: session.businessId!,
        name: 'Your Business', 
        email: 'user@example.com',
        status: 'pending', // Safe default that will show status screen
        businessType: BusinessType.restaurant,
      );
      
      debugPrint('🏢 BusinessProvider: Created fallback business object');
      debugPrint('🏢 BusinessProvider: === BUSINESS FETCH COMPLETED (FALLBACK) ===');
      return business;
    }
    
    debugPrint('🏢 BusinessProvider: No businesses found in API response');
    return null;
  } catch (e) {
    debugPrint('🏢 BusinessProvider: Error occurred: $e');
    debugPrint('🏢 BusinessProvider: === BUSINESS FETCH FAILED ===');
    throw Exception('Failed to load business: $e');
  }
});

// Enhanced business provider with complete details from DynamoDB
final enhancedBusinessProvider = FutureProvider<Business?>((ref) async {
  final session = ref.watch(sessionProvider);

  debugPrint('🏢 EnhancedBusinessProvider: === ENHANCED BUSINESS FETCH STARTED ===');
  debugPrint('🏢 EnhancedBusinessProvider: Session authenticated: ${session.isAuthenticated}');
  debugPrint('🏢 EnhancedBusinessProvider: Business ID: ${session.businessId}');

  if (!session.isAuthenticated) {
    debugPrint('🏢 EnhancedBusinessProvider: No authenticated session, returning null');
    return null;
  }

  try {
    debugPrint('🏢 EnhancedBusinessProvider: Calling getBusinessDetails API...');
    final apiService = ApiService();
    final response = await apiService.getBusinessDetails();

    debugPrint('🏢 EnhancedBusinessProvider: API response received');
    debugPrint('🏢 EnhancedBusinessProvider: Success: ${response['success']}');

    if (response['success'] == true && response['business'] != null) {
      final businessData = response['business'];
      debugPrint('🏢 EnhancedBusinessProvider: Business data received: ${businessData.keys}');
      debugPrint('🏢 EnhancedBusinessProvider: Business status: ${businessData['status']}');
      debugPrint('🏢 EnhancedBusinessProvider: Business name: ${businessData['name'] ?? businessData['businessName']}');
      
      final business = Business.fromJson(businessData);
      debugPrint('🏢 EnhancedBusinessProvider: Business object created successfully');
      debugPrint('🏢 EnhancedBusinessProvider: Final business status: ${business.status}');
      debugPrint('🏢 EnhancedBusinessProvider: === ENHANCED BUSINESS FETCH COMPLETED ===');
      return business;
    }

    debugPrint('🏢 EnhancedBusinessProvider: API call successful but no business data returned');
    return null;
  } catch (e) {
    debugPrint('🏢 EnhancedBusinessProvider: Enhanced business fetch failed: $e');
    debugPrint('🏢 EnhancedBusinessProvider: Falling back to stored session data...');
    
    // Fallback to stored business data in session if API fails
    if (session.businessData != null) {
      debugPrint('🏢 EnhancedBusinessProvider: Found stored business data in session');
      try {
        final business = Business.fromJson(session.businessData!);
        debugPrint('🏢 EnhancedBusinessProvider: Using stored business data - Status: ${business.status}');
        return business;
      } catch (parseError) {
        debugPrint('🏢 EnhancedBusinessProvider: Error parsing stored business data: $parseError');
      }
    }
    
    debugPrint('🏢 EnhancedBusinessProvider: No fallback data available, throwing error');
    throw Exception('Failed to load business details: $e');
  }
});

// Provider for refreshing business data
final businessRefreshProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(businessProvider);
    ref.invalidate(enhancedBusinessProvider);
  };
});

// Provider for updating business profile
final businessUpdateProvider =
    StateNotifierProvider<BusinessUpdateNotifier, AsyncValue<void>>((ref) {
  return BusinessUpdateNotifier(ref);
});

class BusinessUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  BusinessUpdateNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> updateBusinessProfile(
      String businessId, Map<String, dynamic> updateData) async {
    state = const AsyncValue.loading();

    try {
      final apiService = ApiService();
      await apiService.updateBusinessProfile(businessId, updateData);

      // Refresh the business provider to get updated data
      ref.invalidate(businessProvider);
      ref.invalidate(enhancedBusinessProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateBusinessPhoto(String businessId, String photoUrl) async {
    state = const AsyncValue.loading();

    try {
      final apiService = ApiService();
      await apiService.updateBusinessPhoto(businessId, photoUrl);

      // Refresh the business provider to get updated data
      ref.invalidate(businessProvider);
      ref.invalidate(enhancedBusinessProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
