import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/business.dart';
import '../services/product_service.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../providers/product_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class ProductsManagementScreen extends ConsumerStatefulWidget {
  final Business business;

  const ProductsManagementScreen({
    super.key,
    required this.business,
  });

  @override
  ConsumerState<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState
    extends ConsumerState<ProductsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state =
            _searchController.text.trim();
      }
    });
  }

  String _getBusinessTypeString(dynamic businessType) {
    final typeStr = businessType.toString().split('.').last.toLowerCase();
    switch (typeStr) {
      case 'kitchen':
        return 'restaurant';
      case 'cloudkitchen':
        return 'cloudkitchen';
      case 'store':
        return 'store';
      case 'pharmacy':
        return 'pharmacy';
      case 'caffe':
        return 'cafe';
      case 'bakery':
        return 'bakery';
      default:
        return 'restaurant';
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final result = await ProductService.deleteProduct(productId);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(productsProvider);
      } else {
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
      // Pass other fields to avoid nulling them
      name: product.name,
      description: product.description,
      price: product.price,
      categoryId: product.categoryId,
      imageUrl: product.imageUrl,
    );

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Product availability updated to ${!product.isAvailable}'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(productsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to update availability: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAddProductScreen() async {
    final businessType = _getBusinessTypeString(widget.business.businessType);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddProductScreen(businessType: businessType),
      ),
    );

    if (result == true) {
      ref.invalidate(productsProvider);
    }
  }

  void _navigateToEditProductScreen(Product product) async {
    final businessType = _getBusinessTypeString(widget.business.businessType);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          product: product,
          businessType: businessType,
        ),
      ),
    );

    if (result == true) {
      ref.invalidate(productsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final productsAsyncValue = ref.watch(productSearchProvider(searchQuery));
    final businessType = _getBusinessTypeString(widget.business.businessType);
    final categoriesAsyncValue = ref.watch(categoriesProvider(businessType));

    return Scaffold(
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: productsAsyncValue.when(
              data: (products) => categoriesAsyncValue.when(
                data: (categories) => _buildProductList(products, categories),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    _buildErrorWidget('Failed to load categories: $err'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  _buildErrorWidget('Failed to load products: $err'),
            ),
          ),
        ],
      ),
      floatingActionButton: categoriesAsyncValue.when(
        data: (categories) => FloatingActionButton(
          onPressed: () async {
            if (categories.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Cannot add products: No categories available.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            final businessType =
                _getBusinessTypeString(widget.business.businessType);
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    AddProductScreen(businessType: businessType),
              ),
            );
            if (result == true) {
              ref.invalidate(productsProvider);
            }
          },
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        loading: () => const FloatingActionButton(
          onPressed: null,
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(productsProvider);
                final businessType =
                    _getBusinessTypeString(widget.business.businessType);
                ref.invalidate(categoriesProvider(businessType));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final searchQuery = ref.watch(searchQueryProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      height: 40,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildProductList(
      List<Product> products, List<ProductCategory> categories) {
    final searchQuery = ref.watch(searchQueryProvider);

    if (products.isEmpty) {
      return Center(
        child: Text(searchQuery.isNotEmpty
            ? 'No products found for "$searchQuery"'
            : 'No products found. Add one to get started!'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, categories);
      },
    );
  }

  String _getCategoryName(
      String categoryId, List<ProductCategory> categories) {
    try {
      return categories.firstWhere((cat) => cat.id == categoryId).name;
    } catch (e) {
      return 'Unknown Category';
    }
  }

  Widget _buildProductCard(Product product, List<ProductCategory> categories) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultProductIcon(),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          )
                        : _buildDefaultProductIcon(),
                  ),
                ),
                const SizedBox(width: 16),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryName(product.categoryId, categories),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                Switch(
                  value: product.isAvailable,
                  onChanged: (_) => _toggleProductAvailability(product),
                  activeColor: Colors.green,
                ),
                Text(
                  product.isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    color: product.isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Action Buttons
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () async {
                    final businessType =
                        _getBusinessTypeString(widget.business.businessType);
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditProductScreen(
                          product: product,
                          businessType: businessType,
                        ),
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(productsProvider);
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

  Widget _buildDefaultProductIcon() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.restaurant_menu,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

}
