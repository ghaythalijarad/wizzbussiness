import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import 'session_provider.dart';

final businessProvider = FutureProvider<Business?>((ref) async {
  final session = ref.watch(sessionProvider);
  
  if (!session.isAuthenticated || session.businessId == null) {
    return null;
  }

  try {
    final apiService = ApiService();
    final businesses = await apiService.getUserBusinesses();
    
    if (businesses.isNotEmpty) {
      // Find the business that matches the session business ID
      final businessData = businesses.firstWhere(
        (business) =>
            business['businessId'] == session.businessId ||
            business['id'] == session.businessId,
        orElse: () => businesses.first,
      );

      return Business.fromJson(businessData);
    }
    
    return null;
  } catch (e) {
    throw Exception('Failed to load business: $e');
  }
});

// Enhanced business provider with complete details from DynamoDB
final enhancedBusinessProvider = FutureProvider<Business?>((ref) async {
  final session = ref.watch(sessionProvider);

  if (!session.isAuthenticated) {
    return null;
  }

  try {
    final apiService = ApiService();
    final response = await apiService.getBusinessDetails();

    if (response['success'] == true && response['business'] != null) {
      return Business.fromJson(response['business']);
    }

    return null;
  } catch (e) {
    // Fallback to the original business provider if enhanced fails
    print('Enhanced business fetch failed, falling back to original: $e');
    return ref.watch(businessProvider).when(
          data: (business) => business,
          loading: () => null,
          error: (error, stack) => null,
        );
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
