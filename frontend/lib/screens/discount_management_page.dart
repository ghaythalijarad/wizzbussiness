import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/discount.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../services/app_auth_service.dart';
import '../services/product_service.dart';
import '../screens/login_page.dart';

class DiscountManagementPage extends StatefulWidget {
  final Business business;
  final List<Order> orders;
  final VoidCallback? onNavigateToOrders;
  final Function(String, OrderStatus)? onOrderUpdated;
  final bool embedded;

  const DiscountManagementPage({
    Key? key,
    required this.business,
    required this.orders,
    this.onNavigateToOrders,
    this.onOrderUpdated,
    this.embedded = false,
  }) : super(key: key);

  @override
  _DiscountManagementPageState createState() => _DiscountManagementPageState();
}

class _DiscountManagementPageState extends State<DiscountManagementPage> {
  // Hot reload trigger comment
  List<Discount> _discounts = [];
  // ignore: unused_field
  List<Product> _products = [];
  // ignore: unused_field
  List<ProductCategory> _categories = [];
  String _selectedFilter = 'all';
  final ApiService _apiService = ApiService();
  bool _isInitializing = true;

  List<Discount> get _filteredDiscounts {
    final allDiscounts = _discounts;

    switch (_selectedFilter) {
      case 'active':
        return allDiscounts
            .where((d) => d.status == DiscountStatus.active)
            .toList();
      case 'scheduled':
        return allDiscounts
            .where((d) => d.status == DiscountStatus.scheduled)
            .toList();
      case 'expired':
        return allDiscounts
            .where((d) => d.status == DiscountStatus.expired)
            .toList();
      default:
        return allDiscounts;
    }
  }

  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
    _validateAuthenticationAndInitialize();
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  Future<void> _validateAuthenticationAndInitialize() async {
    try {
      // Check if we have a valid business ID first
      if (widget.business.id == 'unknown-id' || widget.business.id.isEmpty) {
        print(
            'DiscountManagementPage: Invalid business ID: ${widget.business.id}');

        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          _showAuthenticationRequiredDialog(loc.authenticationFailedTitle,
              'Invalid business configuration. Please sign in again.');
        }
        return;
      }

      // Verify authentication before proceeding
      final isSignedIn = await AppAuthService.isSignedIn();
      if (!isSignedIn) {
        print('DiscountManagementPage: User not authenticated');

        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          _showAuthenticationRequiredDialog(loc.authenticationFailedTitle,
              'Please sign in to access discount management.');
        }
        return;
      }

      // Verify we can get current user and access token
      final currentUser = await AppAuthService.getCurrentUser();
      final accessToken = await AppAuthService.getAccessToken();

      if (currentUser == null || accessToken == null) {
        print('DiscountManagementPage: Authentication verification failed');

        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          _showAuthenticationRequiredDialog(loc.sessionExpiredTitle,
              'Your session has expired. Please sign in again.');
        }
        return;
      }

      print(
          'DiscountManagementPage: Authentication verified - ${currentUser['email'] ?? 'Unknown email'}');

      // Load all data in parallel
      await Future.wait([
        _loadDiscounts(),
        _loadProducts(),
        _loadCategories(),
      ]);

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('DiscountManagementPage: Error during initialization: $e');

      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        _showAuthenticationRequiredDialog(
            loc.authenticationFailedTitle, 'Failed to initialize: $e');
      }
    }
  }

  Future<void> _loadDiscounts() async {
    try {
      setState(() {
        _isInitializing = true;
      });

      final discountsData = await _apiService.getDiscounts();
      final discounts =
          discountsData.map((data) => Discount.fromJson(data)).toList();

      setState(() {
        _discounts = discounts;
        _isInitializing = false;
      });
    } catch (e) {
      print('Error loading discounts: $e');
      setState(() {
        _isInitializing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load discounts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      print(
          'DiscountManagementPage: Loading products for business ${widget.business.id}');
      final result = await ProductService.getProducts();

      if (result['success'] && result['products'] != null) {
        final productsList = result['products'] as List;
        final products =
            productsList.map((json) => Product.fromJson(json)).toList();

        setState(() {
          _products = products;
        });

        print('DiscountManagementPage: Loaded ${products.length} products');
      } else {
        throw Exception(result['message'] ?? 'Failed to load products');
      }
    } catch (e) {
      print('DiscountManagementPage: Error loading products: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final businessTypeString =
          _getBusinessTypeString(widget.business.businessType);
      print(
          'DiscountManagementPage: Loading categories for business type $businessTypeString');
      final result =
          await ProductService.getCategoriesForBusinessType(businessTypeString);

      if (result['success'] && result['categories'] != null) {
        final categoriesList = result['categories'] as List;
        final categories = categoriesList
            .map((json) => ProductCategory.fromJson(json))
            .toList();

        setState(() {
          _categories = categories;
        });

        print('DiscountManagementPage: Loaded ${categories.length} categories');
      } else {
        print(
            'DiscountManagementPage: Categories API failed: ${result['message']}');
        
        // Handle different error types
        final error = result['error'] ?? 'unknown_error';
        String userMessage = result['message'] ?? 'Failed to load categories';
        
        if (error == 'authorization_required' ||
            error == 'authentication_required') {
          userMessage =
              'Please sign in again to access categories for discounts.';
        } else if (error == 'authorization_failed' ||
            error == 'backend_misconfigured') {
          userMessage =
              'Categories service temporarily unavailable. Cannot create discounts without categories.';
        } else if (error == 'categories_not_found') {
          userMessage =
              'No categories found. Please add categories before creating discounts.';
        }
        
        throw Exception(userMessage);
      }
    } catch (e) {
      print('DiscountManagementPage: Error loading categories: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _loadCategories(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteDiscount(String discountId) async {
    print('Attempting to delete discount: $discountId');
    try {
      await _apiService.deleteDiscount(discountId);
      setState(() {
        _discounts.removeWhere((d) => d.id == discountId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discount deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting discount: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete discount: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        return 'cafe'; // ✅ FIXED: API expects 'cafe' not 'caffe'
      case 'bakery':
        return 'bakery';
      case 'herbalspices':
        return 'herbalspices'; // Use actual business type instead of fallback
      case 'cosmetics':
        return 'cosmetics'; // Use actual business type instead of fallback
      case 'betshop':
        return 'betshop'; // Use actual business type instead of fallback
      default:
        return 'restaurant'; // Default fallback
    }
  }

  void _showAuthenticationRequiredDialog(String title, String message) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red[700]),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: _navigateToLogin,
            child: Text(loc.signIn),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final body = _isInitializing
        ? const Center(child: CircularProgressIndicator())
        : _buildDiscountDashboard(loc, theme);

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Discount Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDiscounts,
            tooltip: 'Refresh Discounts',
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDiscountDialog(loc),
        label: Text(loc.createDiscount),
        icon: const Icon(Icons.add),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildDiscountDashboard(AppLocalizations loc, ThemeData theme) {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                    AppLocalizations.of(context)!.allDiscounts, 'all'),
                const SizedBox(width: 8),
                _buildFilterChip(
                    AppLocalizations.of(context)!.activeDiscounts, 'active'),
                const SizedBox(width: 8),
                _buildFilterChip(
                    AppLocalizations.of(context)!.scheduledDiscounts,
                    'scheduled'),
                const SizedBox(width: 8),
                _buildFilterChip(
                    AppLocalizations.of(context)!.expiredDiscounts, 'expired'),
              ],
            ),
          ),
        ),
        // Discounts list
        Expanded(
          child: _filteredDiscounts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredDiscounts.length,
                  itemBuilder: (context, index) {
                    final discount = _filteredDiscounts[index];
                    return _buildDiscountCard(discount);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isSelected ? 2 : 0.5,
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? const Color(0xFF00C1E8)
            : const Color(0xFF001133).withOpacity(0.05),
        shadowColor: isSelected
            ? const Color(0xFF00C1E8).withOpacity(0.3)
            : const Color(0xFF001133).withOpacity(0.1),
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = value),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00C1E8)
                    : const Color(0xFF001133).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF001133),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: const Color(0xFF001133).withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noDiscountsCreated,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF001133).withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createYourFirstDiscount,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF001133).withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  void _showCreateDiscountDialog(AppLocalizations loc) {
    _showDiscountForm();
  }

  void _showEditDiscountDialog(Discount discount) {
    _showDiscountForm(discount: discount);
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _refreshDiscounts() {
    _loadDiscounts();
  }

  Widget _buildDiscountCard(Discount discount) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(discount.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(discount.description),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _showEditDiscountDialog(discount),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[700]),
              onPressed: () async {
                final loc = AppLocalizations.of(context)!;
                final confirmed = await _showConfirmationDialog(
                  loc.deleteDiscount,
                  loc.areYouSureYouWantToDeleteThisDiscount,
                );
                if (confirmed) {
                  await _deleteDiscount(discount.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscountForm({Discount? discount}) {
    // Implement the discount form dialog here
  }
}

String getLocalizedApplicabilityText(BuildContext context, Discount discount) {
  final loc = AppLocalizations.of(context)!;
  switch (discount.applicability) {
    case DiscountApplicability.allItems:
      return loc.appliesToAllItems;
    case DiscountApplicability.specificItems:
      return loc.appliesToSpecificItems(discount.applicableItemIds.length);
    case DiscountApplicability.specificCategories:
      return loc.appliesToCategories(discount.applicableCategoryIds.length);
    case DiscountApplicability.minimumOrder:
      return loc.appliesToMinimumOrder;
  }
}

String getApplicabilityText(Discount discount) {
  // This function needs context for localization, so it should be moved or refactored
  switch (discount.applicability) {
    case DiscountApplicability.allItems:
      return 'Applies to all items'; // Will be replaced with localized version
    case DiscountApplicability.specificItems:
      return 'Applies to ${discount.applicableItemIds.length} specific items'; // Will be replaced
    case DiscountApplicability.specificCategories:
      return 'Applies to ${discount.applicableCategoryIds.length} categories'; // Will be replaced
    case DiscountApplicability.minimumOrder:
      return 'Applies to orders above minimum amount'; // Will be replaced
  }
}

Color getStatusColor(Discount discount) {
  // Legacy function retained for compatibility; delegate to new extension (no context available here)
  switch (discount.status) {
    case DiscountStatus.active:
      return Colors.green;
    case DiscountStatus.scheduled:
      return Colors.blue;
    case DiscountStatus.expired:
      return Colors.red;
    case DiscountStatus.paused:
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

String getStatusText(BuildContext context, Discount discount) {
  switch (discount.status) {
    case DiscountStatus.active:
      return AppLocalizations.of(context)!.active;
    case DiscountStatus.scheduled:
      return AppLocalizations.of(context)!.scheduled;
    case DiscountStatus.expired:
      return AppLocalizations.of(context)!.expired;
    default:
      return '';
  }
}
