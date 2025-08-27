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
import '../utils/responsive_helper.dart';

class DiscountManagementPage extends StatefulWidget {
  final Business business;
  final List<Order> orders;
  final VoidCallback? onNavigateToOrders;
  final Function(String, OrderStatus)? onOrderUpdated;

  const DiscountManagementPage({
    Key? key,
    required this.business,
    required this.orders,
    this.onNavigateToOrders,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  _DiscountManagementPageState createState() => _DiscountManagementPageState();
}

class _DiscountManagementPageState extends State<DiscountManagementPage> {
  // Hot reload trigger comment
  List<Discount> _discounts = [];
  String _selectedFilter = 'all';
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  bool _isInitializing = true;
  bool _isLoading = false;

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
        _isLoading = true;
      });

      final discountsData = await _apiService.getDiscounts();
      final discounts =
          discountsData.map((data) => Discount.fromJson(data)).toList();

      setState(() {
        _discounts = discounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading discounts: $e');
      setState(() {
        _isLoading = false;
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
        
        // Show a message if using fallback categories
        if (result['source'] == 'fallback' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Using default categories'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to load categories');
      }
    } catch (e) {
      print('DiscountManagementPage: Error loading categories: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
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
        return 'store'; // Fallback to store for unsupported types
      case 'cosmetics':
        return 'store'; // Fallback to store for unsupported types
      case 'betshop':
        return 'store'; // Fallback to store for unsupported types
      default:
        return 'restaurant'; // Default fallback
    }
  }

  Future<void> _createDiscount(Discount discount) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final discountData = discount.toJson();
      final createdDiscountData =
          await _apiService.createDiscount(discountData);
      final createdDiscount = Discount.fromJson(createdDiscountData);

      setState(() {
        _discounts.add(createdDiscount);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discount created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating discount: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create discount: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDiscount(Discount discount) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final discountData = discount.toJson();
      final updatedDiscountData =
          await _apiService.updateDiscount(discount.id, discountData);
      final updatedDiscount = Discount.fromJson(updatedDiscountData);

      setState(() {
        final index = _discounts.indexWhere((d) => d.id == discount.id);
        if (index != -1) {
          _discounts[index] = updatedDiscount;
        }
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discount updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating discount: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update discount: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDiscount(String discountId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _apiService.deleteDiscount(discountId);

      setState(() {
        _discounts.removeWhere((d) => d.id == discountId);
        _isLoading = false;
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
      setState(() {
        _isLoading = false;
      });

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
    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF32CD32).withOpacity(0.05), // Lime Green
                const Color(0xFFFFD300).withOpacity(0.03), // Gold
                Colors.white,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF32CD32).withOpacity(0.1),
                    const Color(0xFFFFD300).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: CircularProgressIndicator(
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF32CD32)),
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF32CD32).withOpacity(0.05), // Lime Green
              const Color(0xFFFFD300).withOpacity(0.03), // Gold
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Modern Material 3 App Bar with gradient
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF32CD32), // Lime Green
                          const Color(0xFF228B22), // Darker Lime Green
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF32CD32).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .discountManagement,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create and manage your discounts',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter chips with Material 3 design
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF32CD32).withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                              AppLocalizations.of(context)!.allDiscounts,
                              'all'),
                          const SizedBox(width: 12),
                          _buildFilterChip(
                              AppLocalizations.of(context)!.activeDiscounts,
                              'active'),
                          const SizedBox(width: 12),
                          _buildFilterChip(
                              AppLocalizations.of(context)!.scheduledDiscounts,
                              'scheduled'),
                          const SizedBox(width: 12),
                          _buildFilterChip(
                              AppLocalizations.of(context)!.expiredDiscounts,
                              'expired'),
                        ],
                      ),
                    ),
                  ),
                  
                  // Discounts list
                  Expanded(
                    child: _filteredDiscounts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredDiscounts.length,
                            itemBuilder: (context, index) {
                              final discount = _filteredDiscounts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: DiscountCard(
                                  discount: discount,
                                  onEdit: () =>
                                      _showEditDiscountDialog(discount),
                                  onDelete: () =>
                                      _showDeleteConfirmationDialog(discount),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // Loading overlay
              if (_isLoading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF32CD32).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF32CD32)),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF32CD32), // Lime Green
              const Color(0xFF228B22), // Darker Lime Green
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF32CD32).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateDiscountDialog(),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD300), // Gold accent
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.black87,
              size: 18,
            ),
          ),
          label: Text(
            AppLocalizations.of(context)!.createDiscount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isSelected ? 4 : 0,
        borderRadius: BorderRadius.circular(20),
        color: isSelected
            ? const Color(0xFF32CD32)
            : Colors.transparent,
        shadowColor: isSelected
            ? const Color(0xFF32CD32).withOpacity(0.4)
            : Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = value),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : const Color(0xFF32CD32).withOpacity(0.3),
                width: 2,
              ),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF32CD32),
                        const Color(0xFF228B22),
                      ],
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.black87,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF32CD32),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFF32CD32).withOpacity(0.02),
              const Color(0xFFFFD300).withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFF32CD32).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF32CD32).withOpacity(0.1),
                    const Color(0xFFFFD300).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 64,
                color: const Color(0xFF32CD32),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noDiscountsCreated,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.createYourFirstDiscount,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF32CD32),
                    const Color(0xFF228B22),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF32CD32).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showCreateDiscountDialog(),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.black87,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.createDiscount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDiscountDialog() {
    _showDiscountDialog();
  }

  void _showEditDiscountDialog(Discount discount) {
    _showDiscountDialog(discount: discount);
  }

  void _showDeleteConfirmationDialog(Discount discount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.red.withOpacity(0.2), width: 2),
        ),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.deleteDiscount,
                style: const TextStyle(
                  color: Color(0xFF1C1C1C),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            AppLocalizations.of(context)!.areYouSureYouWantToDeleteThisDiscount,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade400,
                  Colors.red.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
              await _deleteDiscount(discount.id);
            },
            style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.delete,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog({Discount? discount}) {
    final isEditing = discount != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: discount?.title ?? '');
    final valueController =
        TextEditingController(text: discount?.value.toString() ?? '');
    final minOrderController = TextEditingController(
        text: discount?.minimumOrderAmount.toString() ?? '');

    // If editing a free delivery discount, default the main type to percentage
    var discountType = discount?.type == DiscountType.freeDelivery
        ? DiscountType.percentage
        : (discount?.type ?? DiscountType.percentage);

    // Handle discount applicability
    var applicability =
        discount?.applicability ?? DiscountApplicability.allItems;
    var selectedItemIds = List<String>.from(discount?.applicableItemIds ?? []);
    var selectedCategoryIds =
        List<String>.from(discount?.applicableCategoryIds ?? []);

    // Buy X Get Y specific variables
    final buyXQuantityController = TextEditingController(
        text:
            discount?.conditionalParameters?['buyQuantity']?.toString() ?? '1');
    final getYQuantityController = TextEditingController(
        text:
            discount?.conditionalParameters?['getQuantity']?.toString() ?? '1');
    var selectedBuyItemId =
        discount?.conditionalParameters?['buyItemId'] as String?;
    var selectedGetItemId =
        discount?.conditionalParameters?['getItemId'] as String?;

    var startDate = discount?.validFrom ?? DateTime.now();
    var endDate =
        discount?.validTo ?? DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: const Color(0xFF32CD32).withOpacity(0.2), width: 2),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF32CD32).withOpacity(0.1),
                  const Color(0xFFFFD300).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF32CD32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing
                      ? AppLocalizations.of(context)!.editDiscount
                      : AppLocalizations.of(context)!.createDiscount,
                  style: const TextStyle(
                    color: Color(0xFF1C1C1C),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            width: ResponsiveHelper.isDesktop(context)
                ? 600
                : ResponsiveHelper.isTablet(context)
                    ? 500
                    : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.title,
                            labelStyle: TextStyle(
                              color: const Color(0xFF32CD32),
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: const Color(0xFF32CD32).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF32CD32),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: const Color(0xFF32CD32).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            filled: true,
                            fillColor:
                                const Color(0xFF32CD32).withOpacity(0.05),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .pleaseEnterTitle;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<DiscountType>(
                                value: discountType,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!
                                      .discountType,
                                  labelStyle: TextStyle(
                                    color: const Color(0xFF32CD32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF32CD32)
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF32CD32),
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF32CD32)
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  filled: true,
                                  fillColor:
                                      const Color(0xFF32CD32).withOpacity(0.05),
                                ),
                                isExpanded: true,
                                items: DiscountType.values.map((type) {
                                  String label;
                                  switch (type) {
                                    case DiscountType.percentage:
                                      label = AppLocalizations.of(context)!
                                          .percentage;
                                      break;
                                    case DiscountType.fixedAmount:
                                      label = 'Fixed Amount';
                                      break;
                                    case DiscountType.conditional:
                                      label = AppLocalizations.of(context)!
                                          .conditional;
                                      break;
                                    case DiscountType.buyXGetY:
                                      label = AppLocalizations.of(context)!
                                          .buyXGetY;
                                      break;
                                    case DiscountType.freeDelivery:
                                      label = AppLocalizations.of(context)!
                                          .freeDelivery;
                                      break;
                                  }
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      label,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      discountType = value;
                                      // Initialize value controller based on discount type
                                      if (value == DiscountType.percentage &&
                                          valueController.text.isEmpty) {
                                        valueController.text = '10.0';
                                      } else if (value !=
                                          DiscountType.percentage) {
                                        // Set to 0.0 for all non-percentage types
                                        valueController.text = '0.0';
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: discountType == DiscountType.percentage
                                  ? DropdownButtonFormField<double>(
                                      value: () {
                                        double? parsed = double.tryParse(
                                            valueController.text);
                                        List<double> validValues = [
                                          10.0,
                                          15.0,
                                          20.0,
                                          25.0,
                                          30.0,
                                          35.0,
                                          40.0,
                                          45.0,
                                          50.0
                                        ];
                                        if (parsed != null &&
                                            validValues.contains(parsed)) {
                                          return parsed;
                                        }
                                        // Default to 10% if no valid value
                                        if (valueController.text.isEmpty) {
                                          valueController.text = '10.0';
                                        }
                                        return 10.0;
                                      }(),
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(context)!.value,
                                        labelStyle: TextStyle(
                                          color: const Color(0xFF00c1e8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF00c1e8),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      items: [
                                        10,
                                        15,
                                        20,
                                        25,
                                        30,
                                        35,
                                        40,
                                        45,
                                        50
                                      ]
                                          .map((percent) =>
                                              DropdownMenuItem<double>(
                                                value: percent.toDouble(),
                                                child: Text('$percent%'),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            valueController.text =
                                                value.toString();
                                          });
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return AppLocalizations.of(context)!
                                              .pleaseEnterValue;
                                        }
                                        return null;
                                      },
                                    )
                                  : TextFormField(
                                      controller: valueController,
                                      enabled:
                                          false, // Frozen for all non-percentage types
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(context)!.value,
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        hintText: discountType ==
                                                DiscountType.freeDelivery
                                            ? 'Free Delivery (0.0)'
                                            : discountType ==
                                                    DiscountType.buyXGetY
                                                ? 'Buy X Get Y (0.0)'
                                                : 'Conditional (0.0)',
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Buy X Get Y Configuration Section
                        if (discountType == DiscountType.buyXGetY ||
                            discountType == DiscountType.conditional) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00c1e8).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      const Color(0xFF00c1e8).withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shopping_cart,
                                        color: const Color(0xFF00c1e8),
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      discountType == DiscountType.conditional
                                          ? AppLocalizations.of(context)!
                                              .conditionalDiscountConfiguration
                                          : AppLocalizations.of(context)!
                                              .buyXGetYConfiguration,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF00c1e8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Buy X Configuration
                                Text(
                                  AppLocalizations.of(context)!
                                      .buyConfiguration,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: buyXQuantityController,
                                        decoration: InputDecoration(
                                          labelText:
                                              AppLocalizations.of(context)!
                                                  .quantity,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppLocalizations.of(context)!
                                                .required;
                                          }
                                          if (int.tryParse(value) == null ||
                                              int.parse(value) <= 0) {
                                            return AppLocalizations.of(context)!
                                                .enterValidQuantity;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showBuyItemSelectionDialog(
                                                selectedBuyItemId, (itemId) {
                                          setState(() {
                                            selectedBuyItemId = itemId;
                                          });
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade400),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selectedBuyItemId == null
                                                      ? AppLocalizations.of(
                                                              context)!
                                                          .selectItem
                                                      : AppLocalizations.of(
                                                              context)!
                                                          .itemSelected,
                                                  style: TextStyle(
                                                    color: selectedBuyItemId ==
                                                            null
                                                        ? Colors.grey.shade600
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.arrow_drop_down,
                                                  color: Colors.grey.shade600),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Get Y Configuration
                                Text(
                                  AppLocalizations.of(context)!
                                      .getConfiguration,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: getYQuantityController,
                                        decoration: InputDecoration(
                                          labelText:
                                              AppLocalizations.of(context)!
                                                  .quantity,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppLocalizations.of(context)!
                                                .required;
                                          }
                                          if (int.tryParse(value) == null ||
                                              int.parse(value) <= 0) {
                                            return AppLocalizations.of(context)!
                                                .enterValidQuantity;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showGetItemSelectionDialog(
                                                selectedGetItemId, (itemId) {
                                          setState(() {
                                            selectedGetItemId = itemId;
                                          });
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade400),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selectedGetItemId == null
                                                      ? AppLocalizations.of(
                                                              context)!
                                                          .selectItem
                                                      : AppLocalizations.of(
                                                              context)!
                                                          .itemSelected,
                                                  style: TextStyle(
                                                    color: selectedGetItemId ==
                                                            null
                                                        ? Colors.grey.shade600
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.arrow_drop_down,
                                                  color: Colors.grey.shade600),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Discount Applicability Section
                        Opacity(
                          opacity: (discountType == DiscountType.conditional ||
                                  discountType == DiscountType.buyXGetY)
                              ? 0.5
                              : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (discountType ==
                                          DiscountType.conditional ||
                                      discountType == DiscountType.buyXGetY)
                                  ? const Color(0xFF00c1e8).withOpacity(0.08)
                                  : const Color(0xFF00c1e8).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: (discountType ==
                                              DiscountType.conditional ||
                                          discountType == DiscountType.buyXGetY)
                                      ? const Color(0xFF00c1e8).withOpacity(0.2)
                                      : const Color(0xFF00c1e8)
                                          .withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.category,
                                        color: const Color(0xFF00c1e8),
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .discountApplicability,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF00c1e8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<DiscountApplicability>(
                                  value: applicability,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: DiscountApplicability.values
                                      .where((type) =>
                                          type !=
                                          DiscountApplicability.minimumOrder)
                                      .map((applicabilityType) {
                                    String label;
                                    switch (applicabilityType) {
                                      case DiscountApplicability.allItems:
                                        label = AppLocalizations.of(context)!
                                            .allItems;
                                        break;
                                      case DiscountApplicability.specificItems:
                                        label = AppLocalizations.of(context)!
                                            .specificItems;
                                        break;
                                      case DiscountApplicability
                                          .specificCategories:
                                        label = AppLocalizations.of(context)!
                                            .specificCategories;
                                        break;
                                      case DiscountApplicability.minimumOrder:
                                        label = AppLocalizations.of(context)!
                                            .minimumOrder; // This won't be reached due to filter
                                        break;
                                    }
                                    return DropdownMenuItem(
                                      value: applicabilityType,
                                      child: Text(
                                        label,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList(),
                                  // Disable for conditional and buyXGetY types
                                  onChanged: (discountType ==
                                              DiscountType.conditional ||
                                          discountType == DiscountType.buyXGetY)
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              applicability = value;
                                              // Clear selections when changing applicability
                                              if (value !=
                                                  DiscountApplicability
                                                      .specificItems) {
                                                selectedItemIds.clear();
                                              }
                                              if (value !=
                                                  DiscountApplicability
                                                      .specificCategories) {
                                                selectedCategoryIds.clear();
                                              }
                                            });
                                          }
                                        },
                                ),

                                // Item Selection for Specific Items
                                if (applicability ==
                                    DiscountApplicability.specificItems) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.shopping_basket,
                                                size: 16,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .selectItems,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () => _showItemSelectionDialog(
                                              selectedItemIds, setState),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade400),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    selectedItemIds.isEmpty
                                                        ? AppLocalizations.of(
                                                                context)!
                                                            .noItemsSelected
                                                        : '${selectedItemIds.length} items selected',
                                                    style: TextStyle(
                                                      color: selectedItemIds
                                                              .isEmpty
                                                          ? Colors.grey.shade600
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                Icon(Icons.arrow_drop_down,
                                                    color:
                                                        Colors.grey.shade600),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Category Selection for Specific Categories
                                if (applicability ==
                                    DiscountApplicability
                                        .specificCategories) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.folder,
                                                size: 16,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .selectCategories,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              _showCategorySelectionDialog(
                                                  selectedCategoryIds,
                                                  setState),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade400),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    selectedCategoryIds.isEmpty
                                                        ? AppLocalizations.of(
                                                                context)!
                                                            .noCategoriesSelected
                                                        : '${selectedCategoryIds.length} categories selected',
                                                    style: TextStyle(
                                                      color: selectedCategoryIds
                                                              .isEmpty
                                                          ? Colors.grey.shade600
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                Icon(Icons.arrow_drop_down,
                                                    color:
                                                        Colors.grey.shade600),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ), // Close Opacity widget

                        // Add notice for disabled applicability
                        if (discountType == DiscountType.conditional ||
                            discountType == DiscountType.buyXGetY) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey.shade600, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .applicabilityNotConfigurable,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: minOrderController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!
                                .minimumOrderAmount(''),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null) {
                              return AppLocalizations.of(context)!
                                  .pleaseEnterValidNumber;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      startDate = pickedDate;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.startDate,
                                    border: const OutlineInputBorder(),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        '${startDate.toLocal()}'.split(' ')[0]),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: endDate,
                                    firstDate: startDate,
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      endDate = pickedDate;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.endDate,
                                    border: const OutlineInputBorder(),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        '${endDate.toLocal()}'.split(' ')[0]),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF32CD32),
                    const Color(0xFF228B22),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF32CD32).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Check for conflicting discounts
                  if ((applicability == DiscountApplicability.specificItems &&
                          selectedItemIds.isNotEmpty) ||
                      (applicability ==
                              DiscountApplicability.specificCategories &&
                          selectedCategoryIds.isNotEmpty)) {
                    if (_hasConflictingDiscounts(
                        selectedItemIds, selectedCategoryIds, discount?.id)) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!
                              .conflictingDiscountsTitle),
                          content: Text(AppLocalizations.of(context)!
                              .someSelectedItemsAlreadyHaveDiscounts),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(AppLocalizations.of(context)!.ok),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                  }

                  // Prepare conditional parameters for Buy X Get Y and Conditional discounts
                  Map<String, dynamic> conditionalParams = {};
                  ConditionalDiscountRule? conditionalRule;

                  if (discountType == DiscountType.buyXGetY ||
                      discountType == DiscountType.conditional) {
                    if (selectedBuyItemId == null ||
                        selectedGetItemId == null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title:
                              Text(AppLocalizations.of(context)!.missingItems),
                          content: Text(AppLocalizations.of(context)!
                              .missingItemsMessage(discountType ==
                                      DiscountType.conditional
                                  ? AppLocalizations.of(context)!.conditional
                                  : AppLocalizations.of(context)!.buyXGetY)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(AppLocalizations.of(context)!.ok),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    conditionalRule = ConditionalDiscountRule.buyXGetY;
                    conditionalParams = {
                      'buyItemId': selectedBuyItemId,
                      'buyQuantity': int.parse(buyXQuantityController.text),
                      'getItemId': selectedGetItemId,
                      'getQuantity': int.parse(getYQuantityController.text),
                    };
                  }

                  final newDiscount = Discount(
                    id: discount?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    name: titleController.text,
                    description: '', // Description field removed from creation
                    type: discountType,
                    value: double.parse(valueController.text),
                    applicability: applicability,
                    applicableItemIds: selectedItemIds,
                    applicableCategoryIds: selectedCategoryIds,
                    minimumOrderAmount:
                        double.tryParse(minOrderController.text) ?? 0.0,
                    startDate: startDate,
                    endDate: endDate,
                    validFrom: startDate,
                    validTo: endDate,
                    businessId: widget.business.id,
                    createdAt: discount?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                    status: DiscountStatus.active,
                    conditionalRule: conditionalRule,
                    conditionalParameters: conditionalParams,
                  );

                  Navigator.of(context).pop();

                  // Call API methods to create or update the discount
                  try {
                    if (isEditing) {
                      await _updateDiscount(newDiscount);
                    } else {
                      // Check for conflicting discounts before adding
                      if (!_hasConflictingDiscounts(
                          selectedItemIds, selectedCategoryIds, null)) {
                        await _createDiscount(newDiscount);
                      } else {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .conflictingDiscounts),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    // Error handling is already done in the individual methods
                    print('Error in discount dialog: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                  elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                  ),
              ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEditing ? Icons.save : Icons.add,
                        color: Colors.black87,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing
                          ? AppLocalizations.of(context)!.saveChanges
                          : AppLocalizations.of(context)!.create,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Add validation method to check for conflicting discounts
  bool _hasConflictingDiscounts(List<String> selectedItemIds,
      List<String> selectedCategoryIds, String? currentDiscountId) {
    final existingDiscounts = _discounts.where((d) =>
        d.id != currentDiscountId &&
        d.status == DiscountStatus.active &&
        d.type != DiscountType.freeDelivery);

    for (final discount in existingDiscounts) {
      // Check for item conflicts
      if (discount.applicability == DiscountApplicability.specificItems) {
        for (final itemId in selectedItemIds) {
          if (discount.applicableItemIds.contains(itemId)) {
            return true;
          }
        }
      }

      // Check for category conflicts
      if (discount.applicability == DiscountApplicability.specificCategories) {
        for (final categoryId in selectedCategoryIds) {
          if (discount.applicableCategoryIds.contains(categoryId)) {
            return true;
          }
        }
      }

      // Check if existing discount applies to all items
      if (discount.applicability == DiscountApplicability.allItems &&
          (selectedItemIds.isNotEmpty || selectedCategoryIds.isNotEmpty)) {
        return true;
      }
    }

    return false;
  }

  void _showItemSelectionDialog(
      List<String> selectedItemIds, StateSetter setState) async {
    // Use the already loaded products instead of API call
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noItemsFound)),
      );
      return;
    }

    // Flatten all items from all products
    List<Map<String, dynamic>> allItems = [];
    for (final product in _products) {
      // Find the category name for this product
      final category = _categories.firstWhere(
        (cat) => cat.id == product.categoryId,
        orElse: () => ProductCategory(
          id: '',
          name: 'Unknown',
          businessType: '',
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      allItems.add({
        'id': product.id,
        'name': product.name,
        'categoryName': category.name,
        'price': product.price,
      });
    }

    if (allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noItemsFound)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedItemIds);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectItems),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      '${tempSelected.length} ${AppLocalizations.of(context)!.items} selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allItems.length,
                        itemBuilder: (context, index) {
                          final item = allItems[index];
                          final isSelected = tempSelected.contains(item['id']);

                          return CheckboxListTile(
                            dense: true,
                            title: Text(item['name']),
                            subtitle: Text(AppLocalizations.of(context)!
                                .categoryAndPrice(
                                    item['categoryName'],
                                    AppLocalizations.of(context)!.kwd,
                                    item['price'].toStringAsFixed(2))),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true)
                                  tempSelected.add(item['id']);
                                else
                                  tempSelected.remove(item['id']);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedItemIds.clear();
                      selectedItemIds.addAll(tempSelected);
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00c1e8),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCategorySelectionDialog(
      List<String> selectedCategoryIds, StateSetter setState) async {
    // Use the already loaded categories instead of API call
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.noCategoriesFound)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedCategoryIds);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectCategories),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      '${tempSelected.length} ${AppLocalizations.of(context)!.categories} selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = tempSelected.contains(category.id);

                          return CheckboxListTile(
                            dense: true,
                            title: Text(category.name),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true)
                                  tempSelected.add(category.id);
                                else
                                  tempSelected.remove(category.id);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategoryIds.clear();
                      selectedCategoryIds.addAll(tempSelected);
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00c1e8),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBuyItemSelectionDialog(
      String? selectedBuyItemId, Function(String?) onItemSelected) async {
    _showSingleItemSelectionDialog(
      selectedBuyItemId,
      AppLocalizations.of(context)!.selectBuyItem,
      onItemSelected,
    );
  }

  void _showGetItemSelectionDialog(
      String? selectedGetItemId, Function(String?) onItemSelected) async {
    _showSingleItemSelectionDialog(
      selectedGetItemId,
      AppLocalizations.of(context)!.selectGetItem,
      onItemSelected,
    );
  }

  void _showSingleItemSelectionDialog(
    String? selectedItemId,
    String title,
    Function(String?) onItemSelected,
  ) async {
    // Use the already loaded products instead of API call
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noItemsFound)),
      );
      return;
    }

    // Flatten all items from all products
    List<Map<String, dynamic>> allItems = [];
    for (final product in _products) {
      // Find the category name for this product
      final category = _categories.firstWhere(
        (cat) => cat.id == product.categoryId,
        orElse: () => ProductCategory(
          id: '',
          name: 'Unknown',
          businessType: '',
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      allItems.add({
        'id': product.id,
        'name': product.name,
        'categoryName': category.name,
        'price': product.price,
      });
    }

    if (allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noItemsFound)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String? tempSelected = selectedItemId;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      tempSelected != null
                          ? AppLocalizations.of(context)!.itemSelected
                          : AppLocalizations.of(context)!.noItemSelected,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allItems.length,
                        itemBuilder: (context, index) {
                          final item = allItems[index];
                          return RadioListTile<String>(
                            dense: true,
                            title: Text(item['name']),
                            subtitle: Text(AppLocalizations.of(context)!
                                .categoryAndPrice(
                                    item['categoryName'],
                                    AppLocalizations.of(context)!.kwd,
                                    item['price'].toStringAsFixed(2))),
                            value: item['id'],
                            groupValue: tempSelected,
                            onChanged: (String? value) {
                              setDialogState(() {
                                tempSelected = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    onItemSelected(tempSelected);
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00c1e8),
                  ),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Top-level widget for individual discount cards
class DiscountCard extends StatelessWidget {
  final Discount discount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DiscountCard({
    Key? key,
    required this.discount,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(discount);
    final statusText = getStatusText(context, discount);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF32CD32).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                            discount.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF1C1C1C),
                            ),
                          ),
                          if (discount.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              discount.description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withOpacity(0.1),
                            statusColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Discount details section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF32CD32).withOpacity(0.05),
                        const Color(0xFFFFD300).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF32CD32).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF32CD32),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.local_offer,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              discount.type == DiscountType.percentage
                                  ? '${discount.value}% ${AppLocalizations.of(context)!.off}'
                                  : discount.type == DiscountType.freeDelivery
                                      ? AppLocalizations.of(context)!
                                          .freeDelivery
                                      : '${AppLocalizations.of(context)!.conditional} ${AppLocalizations.of(context)!.discount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1C1C1C),
                              ),
                            ),
                          ),
                          if ((discount.minimumOrderAmount ?? 0) > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD300).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shopping_cart,
                                      color: const Color(0xFFFFD300), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Min: \$${(discount.minimumOrderAmount ?? 0).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.category,
                              color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              getLocalizedApplicabilityText(context, discount),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.date_range,
                              color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Valid: ${discount.validFrom.day}/${discount.validFrom.month}/${discount.validFrom.year} - ${discount.validTo.day}/${discount.validTo.month}/${discount.validTo.year}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF32CD32),
                            const Color(0xFF228B22),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF32CD32).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.black87, size: 16),
                        ),
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade400,
                            Colors.red.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.white, size: 20),
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
  switch (discount.status) {
    case DiscountStatus.active:
      return const Color(0xFF32CD32); // Lime Green for active
    case DiscountStatus.scheduled:
      return const Color(0xFFFFD300); // Gold for scheduled
    case DiscountStatus.expired:
      return Colors.red.shade400; // Red for expired
    default:
      return Colors.grey.shade500; // Grey for inactive
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
