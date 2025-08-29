import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/design_system.dart';
import '../core/theme/app_colors.dart';

/// Products Management Screen - Design System Implementation
///
/// This screen demonstrates the comprehensive use of the Material Design 3 +
/// Golden Ratio design system for managing products in the order receiver app.

class ProductsManagementScreenDS extends ConsumerStatefulWidget {
  const ProductsManagementScreenDS({super.key});

  @override
  ConsumerState<ProductsManagementScreenDS> createState() =>
      _ProductsManagementScreenDSState();
}

class _ProductsManagementScreenDSState
    extends ConsumerState<ProductsManagementScreenDS> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Food',
    'Beverages',
    'Desserts',
    'Specials'
  ];

  // Mock products data for demonstration
  final List<Map<String, dynamic>> _mockProducts = [
    {
      'id': '1',
      'name': 'Margherita Pizza',
      'description':
          'Classic pizza with tomato sauce, mozzarella, and fresh basil',
      'price': 18.99,
      'category': 'Food',
      'inStock': true,
      'image': 'https://example.com/pizza.jpg',
      'rating': 4.8,
      'reviews': 124,
    },
    {
      'id': '2',
      'name': 'Craft Beer Selection',
      'description': 'Local craft beer with hoppy flavor and citrus notes',
      'price': 6.50,
      'category': 'Beverages',
      'inStock': true,
      'image': 'https://example.com/beer.jpg',
      'rating': 4.5,
      'reviews': 89,
    },
    {
      'id': '3',
      'name': 'Chocolate Lava Cake',
      'description':
          'Rich chocolate cake with molten center and vanilla ice cream',
      'price': 9.99,
      'category': 'Desserts',
      'inStock': false,
      'image': 'https://example.com/cake.jpg',
      'rating': 4.9,
      'reviews': 203,
    },
    // Add more mock products...
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _mockProducts.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product['description']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          product['category'] == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Products Management',
        style: TypographySystem.headlineSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: GoldenRatio.xs,
      actions: [
        IconButton(
          icon: Icon(Icons.analytics_outlined, size: GoldenRatio.lg),
          onPressed: () => _showAnalytics(),
          tooltip: 'View Analytics',
        ),
        IconButton(
          icon: Icon(Icons.more_vert, size: GoldenRatio.lg),
          onPressed: () => _showMoreOptions(),
          tooltip: 'More Options',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        _buildCategoryFilter(),
        _buildProductsHeader(),
        Expanded(child: _buildProductsList()),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: EdgeInsets.all(GoldenRatio.lg),
      padding: EdgeInsets.symmetric(
        horizontal: GoldenRatio.lg,
        vertical: GoldenRatio.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: GoldenRatio.sm,
            offset: Offset(0, GoldenRatio.xs / 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant,
            size: GoldenRatio.lg,
          ),
          SizedBox(width: GoldenRatio.md),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TypographySystem.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TypographySystem.bodyLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: AppColors.onSurfaceVariant,
                size: GoldenRatio.lg,
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: GoldenRatio.xxxl,
      margin: EdgeInsets.symmetric(horizontal: GoldenRatio.lg),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Container(
            margin: EdgeInsets.only(right: GoldenRatio.sm),
            child: FilterChip(
              label: Text(
                category,
                style: TypographySystem.labelLarge.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GoldenRatio.lg),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: GoldenRatio.md,
                vertical: GoldenRatio.xs,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsHeader() {
    final filteredCount = _filteredProducts.length;

    return Container(
      padding: EdgeInsets.all(GoldenRatio.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$filteredCount Products',
            style: TypographySystem.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.view_list, size: GoldenRatio.lg),
                onPressed: () => _switchToListView(),
                tooltip: 'List View',
              ),
              IconButton(
                icon: Icon(Icons.grid_view, size: GoldenRatio.lg),
                onPressed: () => _switchToGridView(),
                tooltip: 'Grid View',
              ),
              IconButton(
                icon: Icon(Icons.sort, size: GoldenRatio.lg),
                onPressed: () => _showSortOptions(),
                tooltip: 'Sort Options',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: GoldenRatio.lg),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: EdgeInsets.only(bottom: GoldenRatio.lg),
      elevation: GoldenRatio.xs,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoldenRatio.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(GoldenRatio.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductHeader(product),
            SizedBox(height: GoldenRatio.md),
            _buildProductContent(product),
            SizedBox(height: GoldenRatio.md),
            _buildProductFooter(product),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader(Map<String, dynamic> product) {
    return Row(
      children: [
        Container(
          width: GoldenRatio.xxl,
          height: GoldenRatio.xxl,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(GoldenRatio.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            _getCategoryIcon(product['category']),
            color: AppColors.primary,
            size: GoldenRatio.lg,
          ),
        ),
        SizedBox(width: GoldenRatio.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product['name'],
                style: TypographySystem.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                product['category'],
                style: TypographySystem.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.sm,
            vertical: GoldenRatio.xs,
          ),
          decoration: BoxDecoration(
            color: product['inStock']
                ? AppColors.successContainer
                : AppColors.errorContainer,
            borderRadius: BorderRadius.circular(GoldenRatio.sm),
          ),
          child: Text(
            product['inStock'] ? 'In Stock' : 'Out of Stock',
            style: TypographySystem.labelSmall.copyWith(
              color: product['inStock'] ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductContent(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product['description'],
          style: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: GoldenRatio.sm),
        Row(
          children: [
            Icon(
              Icons.star,
              color: AppColors.warning,
              size: GoldenRatio.md,
            ),
            SizedBox(width: GoldenRatio.xs),
            Text(
              '${product['rating']}',
              style: TypographySystem.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: GoldenRatio.xs),
            Text(
              '(${product['reviews']} reviews)',
              style: TypographySystem.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductFooter(Map<String, dynamic> product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '\$${product['price'].toStringAsFixed(2)}',
          style: TypographySystem.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, size: GoldenRatio.lg),
              onPressed: () => _editProduct(product),
              tooltip: 'Edit Product',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: GoldenRatio.lg),
              onPressed: () => _deleteProduct(product),
              tooltip: 'Delete Product',
            ),
            ElevatedButton(
              style: ButtonThemes.primaryElevatedButton,
              onPressed: product['inStock']
                  ? () => _viewProductDetails(product)
                  : null,
              child: Text('View Details'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(GoldenRatio.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: GoldenRatio.xxxl,
              color: AppColors.onSurfaceVariant,
            ),
            SizedBox(height: GoldenRatio.lg),
            Text(
              'No Products Found',
              style: TypographySystem.headlineMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: GoldenRatio.sm),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Get started by adding your first product',
              style: TypographySystem.bodyLarge.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: GoldenRatio.xl),
            ElevatedButton.icon(
              style: ButtonThemes.primaryElevatedButton,
              icon: Icon(Icons.add),
              label: Text('Add Product'),
              onPressed: () => _addProduct(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _addProduct(),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: GoldenRatio.sm,
      icon: Icon(Icons.add),
      label: Text(
        'Add Product',
        style: TypographySystem.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Beverages':
        return Icons.local_drink;
      case 'Desserts':
        return Icons.cake;
      case 'Specials':
        return Icons.star;
      default:
        return Icons.inventory;
    }
  }

  // Action methods
  void _showAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analytics feature coming soon'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GoldenRatio.lg),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(GoldenRatio.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.upload),
              title: Text('Import Products'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Export Products'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _switchToListView() {
    // Implementation for list view
  }

  void _switchToGridView() {
    // Implementation for grid view
  }

  void _showSortOptions() {
    // Implementation for sort options
  }

  void _editProduct(Map<String, dynamic> product) {
    // Navigate to edit product screen
  }

  void _deleteProduct(Map<String, dynamic> product) {
    // Show delete confirmation dialog
  }

  void _viewProductDetails(Map<String, dynamic> product) {
    // Navigate to product details screen
  }

  void _addProduct() {
    // Navigate to add product screen
  }
}
