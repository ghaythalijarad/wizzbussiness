import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';

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
final productSearchProvider =
    FutureProvider.autoDispose.family<List<Product>, String>(
  (ref, query) async {
    // Get all products first
    final allProducts = await ref.watch(productsProvider.future);
    
    if (query.isEmpty) {
      // If the query is empty, return the full list of products.
      return allProducts;
    }
    
    // Filter products locally by name and description
    final lowercaseQuery = query.toLowerCase();
    return allProducts.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  },
);
