import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/business.dart';
import '../providers/product_provider_riverpod.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../core/theme/app_colors.dart';

class ProductsManagementScreen extends ConsumerStatefulWidget {
  final Business business;

  const ProductsManagementScreen({Key? key, required this.business})
      : super(key: key);

  @override
  ConsumerState<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState
    extends ConsumerState<ProductsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProviderRiverpod.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.secondary.withOpacity(0.03),
                AppColors.background,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: Column(
            children: [
              _buildModernAppBar(),
              _buildHeaderSection(),
              _buildSearchSection(),
              Expanded(
                child: _buildProductContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.lg),
      margin: EdgeInsets.fromLTRB(
        GoldenRatio.lg,
        GoldenRatio.sm,
        GoldenRatio.lg,
        0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.lg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: GoldenRatio.lg,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(GoldenRatio.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(GoldenRatio.sm),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
                          Icons.inventory_2_rounded,
              color: AppColors.primary,
              size: GoldenRatio.xl,
            ),
          ),
          SizedBox(width: GoldenRatio.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Management',
                  style: TypographySystem.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: GoldenRatio.xs),
                Text(
                  'Manage your menu items and inventory',
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final productState = ref.watch(productProviderRiverpod);
              final isLoading = productState.isLoading;
              
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(GoldenRatio.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: GoldenRatio.sm,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(GoldenRatio.sm),
                    onTap: isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AddProductScreen(),
                              ),
                            );
                          },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: GoldenRatio.md,
                        vertical: GoldenRatio.sm,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: GoldenRatio.xs),
                                Text(
                                  'Add Product',
                                  style: TypographySystem.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Consumer(
      builder: (context, ref, child) {
        final productState = ref.watch(productProviderRiverpod);
        final products = productState.products;
        final categories = productState.categories;
        
        final availableCount = products.where((p) => p.isAvailable).length;
        final unavailableCount = products.where((p) => !p.isAvailable).length;
        final categoryCount = categories.length;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: GoldenRatio.lg),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Available Products',
                  availableCount.toString(),
                  Icons.check_circle_rounded,
                  AppColors.success,
                ),
              ),
              SizedBox(width: GoldenRatio.sm),
              Expanded(
                child: _buildStatCard(
                  'Unavailable',
                  unavailableCount.toString(),
                  Icons.remove_circle_rounded,
                  AppColors.warning,
                ),
              ),
              SizedBox(width: GoldenRatio.sm),
              Expanded(
                child: _buildStatCard(
                  'Categories',
                  categoryCount.toString(),
                  Icons.category_rounded,
                  AppColors.info,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.md),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: GoldenRatio.sm,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(GoldenRatio.xs),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.xs),
            ),
            child: Icon(
              icon,
              color: color,
              size: GoldenRatio.lg,
            ),
          ),
          SizedBox(height: GoldenRatio.xs),
          Text(
            count,
            style: TypographySystem.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TypographySystem.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: EdgeInsets.all(GoldenRatio.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.lg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: GoldenRatio.sm,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: GoldenRatio.lg,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(GoldenRatio.md),
        ),
        style: TypographySystem.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildProductContent() {
    return Consumer(
      builder: (context, ref, child) {
        final productState = ref.watch(productProviderRiverpod);

        if (productState.isLoading) {
          return _buildLoadingState();
        }

        if (productState.errorMessage != null) {
          return _buildErrorState(productState.errorMessage!);
        }

        final filteredProducts = productState.products.where((product) {
          return product.name.toLowerCase().contains(_searchQuery) ||
              product.description.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredProducts.isEmpty) {
          return _buildEmptyState();
        }

        return _buildProductList(filteredProducts);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(GoldenRatio.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(GoldenRatio.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(GoldenRatio.xl),
              ),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: GoldenRatio.lg),
            Text(
              'Loading products...',
              style: TypographySystem.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(GoldenRatio.lg),
        padding: EdgeInsets.all(GoldenRatio.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(GoldenRatio.lg),
          border: Border.all(
            color: AppColors.error.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.05),
              blurRadius: GoldenRatio.lg,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(GoldenRatio.md),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(GoldenRatio.md),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: GoldenRatio.xxl,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: GoldenRatio.lg),
            Text(
              'Oops! Something went wrong',
              style: TypographySystem.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: GoldenRatio.sm),
            Text(
              error,
              style: TypographySystem.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: GoldenRatio.lg),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(GoldenRatio.sm),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(productProviderRiverpod.notifier).loadProducts();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    horizontal: GoldenRatio.lg,
                    vertical: GoldenRatio.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GoldenRatio.sm),
                  ),
                ),
                icon: Icon(Icons.refresh_rounded),
                label: Text(
                  'Try Again',
                  style: TypographySystem.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(GoldenRatio.lg),
        padding: EdgeInsets.all(GoldenRatio.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.primary.withOpacity(0.02),
              AppColors.secondary.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(GoldenRatio.xl),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: GoldenRatio.lg,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(GoldenRatio.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(GoldenRatio.lg),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: GoldenRatio.xxxl,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: GoldenRatio.lg),
            Text(
              _searchQuery.isEmpty
                  ? 'Your Product Catalog Awaits!'
                  : 'No Products Found',
              style: TypographySystem.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: GoldenRatio.sm),
            Text(
              _searchQuery.isEmpty
                  ? 'Start building your menu by adding your first product. Showcase what makes your ${widget.business.businessType.name} special!'
                  : 'Try adjusting your search terms or check the spelling.',
              style: TypographySystem.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              SizedBox(height: GoldenRatio.lg),
              // Benefits section
              _buildBenefitCards(),
              SizedBox(height: GoldenRatio.xl),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(GoldenRatio.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: GoldenRatio.md,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: GoldenRatio.xl,
                      vertical: GoldenRatio.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GoldenRatio.md),
                    ),
                  ),
                  icon: Container(
                    padding: EdgeInsets.all(GoldenRatio.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(GoldenRatio.xs),
                    ),
                    child: Icon(Icons.add_rounded, size: 18),
                  ),
                  label: Text(
                    'Add Your First Product',
                    style: TypographySystem.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCards() {
    final benefits = [
      {
        'icon': Icons.visibility_rounded,
        'title': 'Showcase Menu',
        'description': 'Display your offerings beautifully',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.inventory_2_rounded,
        'title': 'Manage Inventory',
        'description': 'Control availability in real-time',
        'color': AppColors.warning,
      },
      {
        'icon': Icons.trending_up_rounded,
        'title': 'Track Performance',
        'description': 'Monitor sales and popularity',
        'color': AppColors.success,
      },
    ];

    return Row(
      children: benefits.map((benefit) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: GoldenRatio.xs),
            padding: EdgeInsets.all(GoldenRatio.md),
            decoration: BoxDecoration(
              color: (benefit['color'] as Color).withOpacity(0.05),
              borderRadius: BorderRadius.circular(GoldenRatio.md),
              border: Border.all(
                color: (benefit['color'] as Color).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(GoldenRatio.sm),
                  decoration: BoxDecoration(
                    color: (benefit['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(GoldenRatio.sm),
                  ),
                  child: Icon(
                    benefit['icon'] as IconData,
                    color: benefit['color'] as Color,
                    size: GoldenRatio.lg,
                  ),
                ),
                SizedBox(height: GoldenRatio.sm),
                Text(
                  benefit['title'] as String,
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: GoldenRatio.xs),
                Text(
                  benefit['description'] as String,
                  style: TypographySystem.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: GoldenRatio.lg),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildModernProductCard(product);
      },
    );
  }

  Widget _buildModernProductCard(Product product) {
    return Container(
      margin: EdgeInsets.only(bottom: GoldenRatio.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.lg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: GoldenRatio.md,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(GoldenRatio.lg),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditProductScreen(product: product),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(GoldenRatio.lg),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GoldenRatio.md),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.secondary.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: (product.images.isNotEmpty || product.imageUrl != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(GoldenRatio.md - 1),
                          child: Image.network(
                            product.images.isNotEmpty 
                                ? product.images.first 
                                : product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported_rounded,
                                color: AppColors.primary,
                                size: GoldenRatio.xl,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.restaurant_menu_rounded,
                          color: AppColors.primary,
                          size: GoldenRatio.xl,
                        ),
                ),
                SizedBox(width: GoldenRatio.md),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TypographySystem.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: GoldenRatio.xs),
                      Text(
                        product.description,
                        style: TypographySystem.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: GoldenRatio.sm),
                      Row(
                        children: [
                          // Price Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: GoldenRatio.sm,
                              vertical: GoldenRatio.xs,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(GoldenRatio.sm),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: GoldenRatio.xs,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              'IQD ${product.price.toStringAsFixed(0)}',
                              style: TypographySystem.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: GoldenRatio.sm),
                          // Availability Status
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: GoldenRatio.sm,
                              vertical: GoldenRatio.xs,
                            ),
                            decoration: BoxDecoration(
                              color: product.isAvailable
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(GoldenRatio.sm),
                              border: Border.all(
                                color: product.isAvailable
                                    ? AppColors.success.withOpacity(0.3)
                                    : AppColors.error.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  product.isAvailable
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: product.isAvailable
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: 14,
                                ),
                                SizedBox(width: GoldenRatio.xs),
                                Text(
                                  product.isAvailable
                                      ? 'Available'
                                      : 'Unavailable',
                                  style: TypographySystem.bodySmall.copyWith(
                                    color: product.isAvailable
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Menu
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(GoldenRatio.sm),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.primary,
                      size: GoldenRatio.lg,
                    ),
                    surfaceTintColor: AppColors.surface,
                    color: AppColors.surface,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GoldenRatio.md),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProductScreen(product: product),
                            ),
                          );
                          break;
                        case 'delete':
                          _showDeleteConfirmation(product, ref);
                          break;
                        case 'toggle_availability':
                          await ref
                              .read(productProviderRiverpod.notifier)
                              .updateProduct(
                                product.copyWith(
                                  isAvailable: !product.isAvailable,
                                ),
                              );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(
                            Icons.edit_rounded,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'Edit',
                            style: TypographySystem.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_availability',
                        child: ListTile(
                          leading: Icon(
                            product.isAvailable
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.warning,
                          ),
                          title: Text(
                            product.isAvailable
                                ? 'Make Unavailable'
                                : 'Make Available',
                            style: TypographySystem.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_rounded,
                            color: AppColors.error,
                          ),
                          title: Text(
                            'Delete',
                            style: TypographySystem.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(GoldenRatio.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: GoldenRatio.lg,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(GoldenRatio.xs),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(GoldenRatio.sm),
          ),
          child: Icon(
            Icons.add_rounded,
            size: GoldenRatio.lg,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Product product, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color(0xFF00C1E8).withOpacity(0.1),
            width: 1,
          ),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.delete_rounded,
            color: Colors.red,
            size: 32,
          ),
        ),
        title: Text(
          'Delete Product',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await ref
                    .read(productProviderRiverpod.notifier)
                    .deleteProduct(product.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Product deleted successfully',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else if (mounted) {
                  final error =
                      ref.read(productProviderRiverpod).errorMessage ??
                          'Unknown error';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.error_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Failed to delete product: $error',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }
}
