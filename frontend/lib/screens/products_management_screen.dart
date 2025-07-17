import 'package:flutter/material.dart';
import 'dart:async';
import '../models/product.dart';
import '../models/business.dart';
import '../services/product_service.dart';
import '../widgets/wizz_business_button.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductsManagementScreen extends StatefulWidget {
  final Business business;

  const ProductsManagementScreen({
    super.key,
    required this.business,
  });

  @override
  State<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<ProductCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _debounceTimer;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load products and categories in parallel
      final results = await Future.wait([
        ProductService.getProducts(),
        _loadCategories(),
      ]);

      final productsResult = results[0] as Map<String, dynamic>;

      if (productsResult['success']) {
        final productsList = productsResult['products'] as List;
        _products = productsList.map((json) => Product.fromJson(json)).toList();
        _updateFilteredProducts();
      } else {
        _error = productsResult['message'];
      }
    } catch (e) {
      _error = 'Failed to load data: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    // Get business type from the business object
    final businessTypeString =
        _getBusinessTypeString(widget.business.businessType);

    print('🏪 ProductsManagementScreen: Loading categories...');
    print('   Business ID: ${widget.business.id}');
    print('   Business Name: ${widget.business.name}');
    print('   Business Type Enum: ${widget.business.businessType}');
    print('   Business Type String: $businessTypeString');

    try {
      final result = await ProductService.getCategoriesForBusinessType(
        businessTypeString,
      );

      print('📋 Categories API Result: $result');

      // The updated ProductService now always returns success=true with categories
      // (either from API or predetermined fallback)
      if (result['success'] && result['categories'] != null) {
        final categoriesList = result['categories'] as List;
        print('📦 Raw categories list length: ${categoriesList.length}');
        print('📦 Raw categories data: $categoriesList');
        
        _categories = categoriesList
            .map((json) => ProductCategory.fromJson(json))
            .toList();
        print('✅ Successfully loaded ${_categories.length} categories:');
        for (var category in _categories) {
          print('   - ${category.name} (ID: ${category.id})');
        }
      } else {
        print('❌ No categories available, this should not happen with the updated service');
        print('   Result success: ${result['success']}');
        print('   Result categories: ${result['categories']}');
        _categories = [];
      }
    } catch (e) {
      print('💥 Error loading categories: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      _categories = [];
    }
  }

  String _getBusinessTypeString(dynamic businessType) {
    // Convert BusinessType enum to the correct API string
    final typeStr = businessType.toString().split('.').last.toLowerCase();

    switch (typeStr) {
      case 'kitchen':
        return 'restaurant'; // API expects 'restaurant' for kitchen businesses
      case 'cloudkitchen':
        return 'cloudkitchen';
      case 'store':
        return 'store';
      case 'pharmacy':
        return 'pharmacy';
      case 'caffe':
        return 'caffe';
      default:
        return 'restaurant'; // Default fallback
    }
  }

  List<Product> get _displayedProducts {
    return _filteredProducts;
  }

  void _updateFilteredProducts() {
    List<Product> filtered = _products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        final nameMatch = product.name.toLowerCase().contains(query);
        final descriptionMatch = product.description.toLowerCase().contains(query);
        
        // Check for ingredients match if product has additionalData
        bool ingredientsMatch = false;
        if (product.additionalData != null && 
            product.additionalData!['ingredients'] != null) {
          final ingredients = product.additionalData!['ingredients'];
          if (ingredients is List) {
            ingredientsMatch = ingredients.any((ingredient) => 
              ingredient.toString().toLowerCase().contains(query));
          } else if (ingredients is String) {
            ingredientsMatch = ingredients.toLowerCase().contains(query);
          }
        }
        
        return nameMatch || descriptionMatch || ingredientsMatch;
      }).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _onSearchChanged() {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Set a new timer for debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    
    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      if (query.isEmpty) {
        // If no search query, use local filtering
        _updateFilteredProducts();
      } else {
        // Perform backend search for more comprehensive results
        final searchResult = await ProductService.searchProducts(query);
        
        if (searchResult['success']) {
          final searchProducts = searchResult['products'] as List;
          final products = searchProducts.map((json) => Product.fromJson(json)).toList();
          
          setState(() {
            _filteredProducts = products;
          });
        } else {
          // Fallback to local search if backend search fails
          _updateFilteredProducts();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Search unavailable, showing local results'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Fallback to local search on error
      _updateFilteredProducts();
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  String _getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => ProductCategory(
        id: categoryId,
        name: 'Unknown Category',
        businessType: '',
        sortOrder: 0,
      ),
    );
    return category.name;
  }

  Future<void> _deleteProduct(String productId) async {
    final result = await ProductService.deleteProduct(productId);

    if (result['success']) {
      setState(() {
        _products.removeWhere((product) => product.id == productId);
      });
      _updateFilteredProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleProductAvailability(Product product) async {
    final result = await ProductService.updateProduct(
      productId: product.id,
      isAvailable: !product.isAvailable,
    );

    if (result['success']) {
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product.copyWith(
            isAvailable: !product.isAvailable,
            updatedAt: DateTime.now(),
          );
        }
      });
      _updateFilteredProducts();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(product.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      WizzBusinessButton(
                        onPressed: _loadData,
                        text: 'Retry',
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Field
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF3399FF).withOpacity(0.08),
                            const Color(0xFF00C1E8).withOpacity(0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF3399FF).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3399FF).withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                          prefixIcon: _isSearching
                              ? Container(
                                  width: 16,
                                  height: 16,
                                  padding: const EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFF3399FF),
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.search_rounded,
                                  color: const Color(0xFF3399FF),
                                  size: 20,
                                ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: Colors.grey[500],
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                    _updateFilteredProducts();
                                  },
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),

                    // Search Results Summary
                    if (_searchQuery.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.grey[600],
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_filteredProducts.length} results for "${_searchQuery}"',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Products List
                    Expanded(
                      child: _filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty
                                        ? Icons.search_off
                                        : Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No products found for "${_searchQuery}"'
                                        : 'No products found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Try adjusting your search terms'
                                        : 'Add your first product to get started',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Only allow adding products if we have categories
          if (_categories.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Cannot add products: No categories available. Please check your business type configuration.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddProductScreen(categories: _categories),
            ),
          );

          if (result == true) {
            _loadData(); // Refresh the list
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryName(product.categoryId),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Availability Toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isAvailable
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: product.isAvailable
                          ? Colors.green[800]
                          : Colors.red[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                // Action Buttons
                IconButton(
                  icon: Icon(
                    product.isAvailable
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.blue,
                  ),
                  onPressed: () => _toggleProductAvailability(product),
                  tooltip: product.isAvailable
                      ? 'Make Unavailable'
                      : 'Make Available',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditProductScreen(
                          product: product,
                          categories: _categories,
                        ),
                      ),
                    );

                    if (result == true) {
                      _loadData(); // Refresh the list
                    }
                  },
                  tooltip: 'Edit Product',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(product),
                  tooltip: 'Delete Product',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
