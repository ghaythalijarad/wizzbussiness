import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../config/app_config.dart';

/// Feature flags provider for environment-based feature management
final featureFlagsProvider = Provider<Map<String, bool>>((ref) {
  return {
    'floating_notifications': AppConfig.enableFloatingNotifications,
    'centralized_platform': AppConfig.enableCentralizedPlatform,
    'firebase_push': AppConfig.enableFirebasePush,
    'debug_logging': AppConfig.enableLogging,
    'ai_recommendations': AppConfig.enableAIFeatures,
    'search_functionality': AppConfig.enableSearchFunctionality,
    'real_time_updates': AppConfig.enableRealTimeNotifications,
    'merchant_approval': AppConfig.enableMerchantApproval,
    'online_offline_toggle': AppConfig.enableOnlineOfflineToggle,
  };
});

/// Environment info provider for debugging and monitoring
final environmentInfoProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'environment': AppConfig.environment,
    'feature_set': AppConfig.featureSet,
    'api_url': AppConfig.baseUrl,
    'cognito_pool': AppConfig.cognitoUserPoolId,
    'cognito_client': AppConfig.appClientId,
    'websocket_url': AppConfig.webSocketUrl,
    'is_production': AppConfig.isProduction,
    'is_staging': AppConfig.isStaging,
    'is_development': AppConfig.isDevelopment,
  };
});

/// Provider to fetch the list of all products for the business.
/// This provider will cache the result and only refetch when invalidated.
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ProductService.getProducts();
  if (result['success']) {
    final productsList = result['products'] as List;
    return productsList.map((json) => Product.fromJson(json)).toList();
  } else {
    throw Exception(result['message'] ?? 'Failed to fetch products');
  }
});

/// Provider to fetch the list of categories for a given business type.
/// It is an auto-disposing provider that takes a business type string as a parameter.
final categoriesProvider =
    FutureProvider.autoDispose.family<List<ProductCategory>, String>(
  (ref, businessType) async {
    final result =
        await ProductService.getCategoriesForBusinessType(businessType);
    if (result['success'] && result['categories'] != null) {
      final categoriesList = result['categories'] as List;
      return categoriesList
          .map((json) => ProductCategory.fromJson(json))
          .toList();
    } else {
      // Handle different error types with appropriate user messages
      final error = result['error'] ?? 'unknown_error';
      final message = result['message'] ?? 'Failed to fetch categories';

      // Create a user-friendly error message based on error type
      String errorMessage = message;

      if (error == 'authorization_required' ||
          error == 'authentication_required') {
        errorMessage =
            'Authentication required. Please sign in again to access categories.';
      } else if (error == 'authorization_failed' ||
          error == 'backend_misconfigured') {
        errorMessage =
            'Categories service temporarily unavailable. Backend deployment may be required.';
      } else if (error == 'categories_not_found') {
        errorMessage =
            'No categories found for business type "$businessType". You can create custom categories in settings.';
      } else if (error == 'server_error') {
        errorMessage =
            'Server temporarily unavailable. Please try again in a few minutes.';
      } else if (error == 'network_error') {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      }

      throw Exception(errorMessage);
    }
  },
);

/// Provider for handling product search functionality.
/// It takes a search query as a parameter.
/// This is the FIXED version that works reliably with client-side filtering!
final productSearchProvider =
    FutureProvider.autoDispose.family<List<Product>, String>(
  (ref, query) async {
    // Check if search functionality is enabled
    final featureFlags = ref.watch(featureFlagsProvider);
    if (!featureFlags['search_functionality']!) {
      return [];
    }
    
    // Get all products first (uses the same reliable endpoint)
    final allProducts = await ref.watch(productsProvider.future);
    
    if (query.isEmpty) {
      // If the query is empty, return the full list of products.
      return allProducts;
    }
    
    // Filter products locally by name and description (CLIENT-SIDE FILTERING)
    // This eliminates the API authentication issues we had before
    final lowercaseQuery = query.toLowerCase();
    return allProducts.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  },
);
