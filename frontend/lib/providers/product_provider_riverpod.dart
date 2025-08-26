import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';

// State class for product management
class ProductState {
  final List<Product> products;
  final List<ProductCategory> categories;
  final bool isLoading;
  final String? errorMessage;
  final Product? selectedProduct;

  const ProductState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedProduct,
  });

  ProductState copyWith({
    List<Product>? products,
    List<ProductCategory>? categories,
    bool? isLoading,
    String? errorMessage,
    Product? selectedProduct,
  }) {
    return ProductState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedProduct: selectedProduct ?? this.selectedProduct,
    );
  }
}

// Product StateNotifier
class ProductNotifier extends StateNotifier<ProductState> {
  ProductNotifier() : super(const ProductState());

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await ProductService.getProducts();
      if (result['success'] == true && result['products'] != null) {
        final productsList = result['products'] as List;
        final products = productsList.map((json) => Product.fromJson(json)).toList();
        
        state = state.copyWith(
          products: products,
          isLoading: false,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to load products',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadCategories(String businessType) async {
    // Don't reload if categories are already loaded for this business type
    if (state.categories.isNotEmpty) {
      return;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await ProductService.getCategoriesForBusinessType(businessType);
      if (result['success'] == true && result['categories'] != null) {
        final categoriesList = result['categories'] as List;
        List<ProductCategory> categories = categoriesList.map((json) => ProductCategory.fromJson(json)).toList();
        
        // Remove duplicates based on category ID
        final Map<String, ProductCategory> uniqueCategories = {};
        for (final category in categories) {
          uniqueCategories[category.id] = category;
        }
        categories = uniqueCategories.values.toList();
        
        print('🏷️ ProductProvider: Loaded ${categories.length} unique categories');
        
        state = state.copyWith(
          categories: categories,
          isLoading: false,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to load categories',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> forceLoadCategories(String businessType) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await ProductService.getCategoriesForBusinessType(businessType);
      if (result['success'] == true && result['categories'] != null) {
        final categoriesList = result['categories'] as List;
        List<ProductCategory> categories = categoriesList.map((json) => ProductCategory.fromJson(json)).toList();
        
        // Remove duplicates based on category ID
        final Map<String, ProductCategory> uniqueCategories = {};
        for (final category in categories) {
          uniqueCategories[category.id] = category;
        }
        categories = uniqueCategories.values.toList();
        
        print('🏷️ ProductProvider: Force loaded ${categories.length} unique categories');
        
        state = state.copyWith(
          categories: categories,
          isLoading: false,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to load categories',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> addProduct(Product product) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await ProductService.createProduct(
        name: product.name,
        description: product.description,
        price: product.price,
        categoryId: product.categoryId,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
        isAvailable: product.isAvailable,
      );

      if (result['success'] == true && result['product'] != null) {
        final newProduct = Product.fromJson(result['product']);
        final updatedProducts = [...state.products, newProduct];
        
        state = state.copyWith(
          products: updatedProducts,
          isLoading: false,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to create product',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await ProductService.updateProduct(
        productId: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        categoryId: product.categoryId,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
        isAvailable: product.isAvailable,
      );

      if (result['success'] == true && result['product'] != null) {
        final updatedProduct = Product.fromJson(result['product']);
        final updatedProducts = state.products.map((p) {
          return p.id == product.id ? updatedProduct : p;
        }).toList();
        
        state = state.copyWith(
          products: updatedProducts,
          isLoading: false,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to update product',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await ProductService.deleteProduct(productId);
      
      if (result['success'] == true) {
        final updatedProducts = state.products.where((p) => p.id != productId).toList();
        
        state = state.copyWith(
          products: updatedProducts,
          isLoading: false,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to delete product',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void selectProduct(Product? product) {
    state = state.copyWith(selectedProduct: product);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  List<Product> getProductsByCategory(String categoryId) {
    return state.products.where((product) => product.categoryId == categoryId).toList();
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return state.products;
    
    return state.products.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
             product.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}

// Provider for product management
final productProviderRiverpod = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier();
});

// Convenience providers for specific data
final productsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productProviderRiverpod).products;
});

final productCategoriesProvider = Provider<List<ProductCategory>>((ref) {
  return ref.watch(productProviderRiverpod).categories;
});

final productLoadingProvider = Provider<bool>((ref) {
  return ref.watch(productProviderRiverpod).isLoading;
});

final productErrorProvider = Provider<String?>((ref) {
  return ref.watch(productProviderRiverpod).errorMessage;
});

final selectedProductProvider = Provider<Product?>((ref) {
  return ref.watch(productProviderRiverpod).selectedProduct;
});
