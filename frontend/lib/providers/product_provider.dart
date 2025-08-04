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
      // If the API fails, the service provides a fallback. If that also fails, throw.
      throw Exception(result['message'] ?? 'Failed to fetch categories');
    }
  },
);

/// Provider for handling product search functionality.
/// It takes a search query as a parameter.
final productSearchProvider =
    FutureProvider.autoDispose.family<List<Product>, String>(
  (ref, query) async {
    if (query.isEmpty) {
      // If the query is empty, return the full list of products.
      return ref.watch(productsProvider.future);
    }
    // Otherwise, perform a search.
    final result = await ProductService.searchProducts(query);
    if (result['success']) {
      final productsList = result['products'] as List;
      return productsList.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception(result['message'] ?? 'Failed to search products');
    }
  },
);
