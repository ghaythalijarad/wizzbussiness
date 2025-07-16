import 'package:flutter/material.dart';
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
  List<ProductCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
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

    print('Loading categories for business type: $businessTypeString');

    try {
      final result = await ProductService.getCategoriesForBusinessType(
        businessTypeString,
      );

      print('Categories result: $result');

      if (result['success']) {
        final categoriesList = result['categories'] as List;
        _categories = categoriesList
            .map((json) => ProductCategory.fromJson(json))
            .toList();
        print(
            'Loaded ${_categories.length} categories: ${_categories.map((c) => c.name).toList()}');
      } else {
        print('Failed to load categories: ${result['message']}');
        _categories = [];
      }
    } catch (e) {
      print('Error loading categories: $e');
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

  List<Product> get _filteredProducts {
    if (_selectedCategoryFilter == 'all') {
      return _products;
    }
    return _products
        .where((product) => product.categoryId == _selectedCategoryFilter)
        .toList();
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
      appBar: AppBar(
        title: const Text('Products Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
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
                    // Category Filter
                    if (_categories.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Text(
                              'Filter by category: ',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _selectedCategoryFilter,
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCategoryFilter = newValue ?? 'all';
                                  });
                                },
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: 'all',
                                    child: Text('All Categories'),
                                  ),
                                  ..._categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category.id,
                                      child: Text(category.name),
                                    );
                                  }).toList(),
                                ],
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
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedCategoryFilter == 'all'
                                        ? 'No products found'
                                        : 'No products in this category',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Add your first product to get started',
                                    style: TextStyle(color: Colors.grey),
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
