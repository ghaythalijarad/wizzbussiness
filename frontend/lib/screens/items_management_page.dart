import 'package:flutter/material.dart';
import 'dart:async';
import '../models/business.dart';
import '../models/order.dart';
import '../models/item_category.dart';
import '../models/dish.dart';
import '../services/api_service.dart';
import '../services/app_auth_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';
import 'login_page.dart';

class ItemsManagementPage extends StatefulWidget {
  final Business business;
  final List<Order> orders;
  final VoidCallback? onNavigateToOrders;
  final Function(String, OrderStatus)? onOrderUpdated;

  const ItemsManagementPage({
    Key? key,
    required this.business,
    required this.orders,
    this.onNavigateToOrders,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  _ItemsManagementPageState createState() => _ItemsManagementPageState();
}

class _ItemsManagementPageState extends State<ItemsManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ItemCategory> _categories = [];
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    print(
        'ItemsManagementPage: Initializing with business: ID=${widget.business.id}, Name=${widget.business.name}');

    // The validation logic is now handled within the data loading methods
    _loadCategories();
    _loadUserData();

    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadCategories() async {
    try {
      // Check if we have a valid business ID first
      if (widget.business.id == 'unknown-id' || widget.business.id.isEmpty) {
        print(
            'ItemsManagementPage: Invalid business ID: ${widget.business.id}');
        print(
            'ItemsManagementPage: Business object: ${widget.business.name} - ${widget.business.email}');

        // Show error dialog and redirect to login
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          _showAuthenticationRequiredDialog(loc.authenticationFailedTitle,
              'Invalid business configuration. Please sign in again.');
        }
        return;
      }

      // Verify authentication before making API calls
      final isSignedIn = await AppAuthService.isSignedIn();
      if (!isSignedIn) {
        print(
            'ItemsManagementPage: User not authenticated, cannot load categories');

        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          _showAuthenticationRequiredDialog(loc.authenticationFailedTitle,
              'Please sign in to access your items.');
        }
        return;
      }

      print(
          'ItemsManagementPage: Loading categories for business: ${widget.business.id}');
      final categories = await _apiService.getCategories(widget.business.id);

      if (mounted) {
        setState(() {
          _categories = categories;
        });
        print(
            'ItemsManagementPage: Loaded ${categories.length} categories successfully');
      }
    } catch (e) {
      // Handle error
      print('ItemsManagementPage: Error loading categories: $e');

      // Check if it's an authentication error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('401') ||
          errorString.contains('unauthorized') ||
          errorString.contains('authentication') ||
          errorString.contains('token') ||
          errorString.contains('signedout') ||
          errorString.contains('signed out')) {
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          _showAuthenticationRequiredDialog(
              loc.sessionExpiredTitle, loc.sessionExpiredPleaseLoginAgain);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.failedToLoadCategories}: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              onPressed: _loadCategories,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Verify authentication status first
      final isSignedIn = await AppAuthService.isSignedIn();
      if (!isSignedIn) {
        print(
            'ItemsManagementPage: User not authenticated, cannot load user data');

        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          _showAuthenticationRequiredDialog(loc.authenticationFailedTitle,
              'Please sign in to access your account.');
        }
        return;
      }

      // Get current authenticated user data
      final userResponse = await AppAuthService.getCurrentUser();
      if (userResponse != null && mounted) {
        setState(() {
          _userData = userResponse;
        });
        print(
            'ItemsManagementPage: User data loaded for ${userResponse['email'] ?? 'Unknown user'}');
      } else {
        print('ItemsManagementPage: Failed to load user data');
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          _showAuthenticationRequiredDialog(
            loc.sessionExpiredTitle,
            'Unable to load user information. Please sign in again.',
          );
        }
      }
    } catch (e) {
      // Handle error with more detailed logging
      print('ItemsManagementPage: Error loading user data: $e');

      // Check if it's an authentication error
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized') ||
          e.toString().contains('authentication') ||
          e.toString().contains('token')) {
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          _showAuthenticationRequiredDialog(
              loc.sessionExpiredTitle, loc.sessionExpiredPleaseLoginAgain);
        }
      }
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Set a new timer for debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      // Verify authentication before performing search
      final isSignedIn = await AppAuthService.isSignedIn();
      if (!isSignedIn) {
        throw Exception('Authentication required. Please sign in again.');
      }

      if (query.isEmpty) {
        // If no search query, load all categories normally
        await _loadCategories();
      } else {
        // Perform backend search
        final searchResult = await _apiService.searchItems(
          widget.business.id,
          query,
        );

        // Process search results and group by categories
        final items = searchResult;
        final categoryMap = <String, ItemCategory>{};

        for (var item in items) {
          final categoryId = item.categoryId;
          // Find the category name from existing categories
          String categoryName = AppLocalizations.of(context)!.uncategorized;
          if (categoryId.isNotEmpty) {
            final category = _categories.firstWhere(
              (cat) => cat.id == categoryId,
              orElse: () => ItemCategory(
                id: categoryId,
                name: 'Category $categoryId',
                businessId: widget.business.id,
                items: [],
              ),
            );
            categoryName = category.name;
          }
          final finalCategoryId =
              categoryId.isNotEmpty ? categoryId : 'uncategorized';

          if (!categoryMap.containsKey(finalCategoryId)) {
            categoryMap[finalCategoryId] = ItemCategory(
              id: finalCategoryId,
              name: categoryName,
              businessId: widget.business.id,
              items: [],
            );
          }

          categoryMap[finalCategoryId]!.items.add(item);
        }

        if (mounted) {
          setState(() {
            _categories = categoryMap.values.toList();
          });
        }
      }
    } catch (e) {
      print('ItemsManagementPage: Error performing search: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.searchFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showAddItemDialogWithAuth() async {
    final loc = AppLocalizations.of(context)!;

    try {
      print(
          'ItemsManagementPage: Starting authentication check for add item...');

      // Check if we have a valid business ID first
      if (widget.business.id == 'unknown-id' || widget.business.id.isEmpty) {
        print(
            'ItemsManagementPage: Invalid business ID: ${widget.business.id}');
        _showAuthenticationRequiredDialog('Invalid Business Configuration',
            'Business setup is incomplete. Please sign in again to reload your business information.');
        return;
      }

      // Try a simple authentication check first
      bool isSignedIn = false;
      try {
        isSignedIn = await AppAuthService.isSignedIn();
        print('ItemsManagementPage: isSignedIn = $isSignedIn');
      } catch (signInError) {
        print(
            'ItemsManagementPage: Error checking sign-in status: $signInError');
        // If we can't even check sign-in status, there's an Amplify configuration issue
        _showAuthenticationRequiredDialog('Authentication System Error',
            'There is an issue with the authentication system. Please restart the app and try signing in again.');
        return;
      }

      if (!isSignedIn) {
        print('ItemsManagementPage: User is not signed in');
        _showAuthenticationRequiredDialog(loc.authenticationFailedTitle,
            "Please sign in to add items to your business.");
        return;
      }

      // Try to get access token - this is the most reliable check
      String? accessToken;
      try {
        accessToken = await AppAuthService.getAccessToken();
        print(
            'ItemsManagementPage: accessToken = ${accessToken != null ? "Present" : "NULL"}');
      } catch (tokenError) {
        print('ItemsManagementPage: Error getting access token: $tokenError');

        // Check if it's an Amplify configuration error
        if (tokenError.toString().contains('Auth plugin has not been added') ||
            tokenError.toString().contains('Amplify')) {
          _showAuthenticationRequiredDialog('Authentication Setup Issue',
              'There is an issue with the authentication system. Please restart the app and try signing in again.');
          return;
        }
      }

      if (accessToken == null) {
        print('ItemsManagementPage: No access token available');
        _showAuthenticationRequiredDialog(loc.sessionExpiredTitle,
            'Your session has expired. Please sign in again.');
        return;
      }

      // Try to get user info (but don't fail if this doesn't work)
      try {
        final currentUser = await AppAuthService.getCurrentUser();
        print('ItemsManagementPage: currentUser = $currentUser');

        // Only check success if we get a response back
        if (currentUser != null && currentUser['success'] == false) {
          print(
              'ItemsManagementPage: currentUser success is false: ${currentUser['message']}');
          _showAuthenticationRequiredDialog(
              loc.sessionExpiredTitle,
              currentUser['message'] ??
                  'Authentication failed. Please sign in again.');
          return;
        }
      } catch (userError) {
        print(
            'ItemsManagementPage: Warning - could not get current user: $userError');
        // Continue anyway if we have a token
      }

      // If we reach here, we have basic authentication, proceed with add item
      print(
          'ItemsManagementPage: Authentication checks passed, showing add item dialog');
      _showAddItemDialog();
    } catch (e) {
      print('ItemsManagementPage: Authentication verification failed: $e');

      // Check if it's an Amplify configuration error
      if (e.toString().contains('Auth plugin has not been added') ||
          e.toString().contains('Amplify') ||
          e.toString().contains('Future already completed')) {
        _showAuthenticationRequiredDialog('Authentication Setup Issue',
            'There is an issue with the authentication system. Please restart the app and try signing in again.');
      } else {
        _showAuthenticationRequiredDialog(loc.authenticationFailedTitle,
            "Authentication check failed. Please try signing in again.");
      }
    }
  }

  void _showAuthenticationRequiredDialog(String title, String message) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.orange.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login or trigger re-authentication
              _navigateToLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.signIn),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    // Navigate to the login page to re-authenticate
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          onLanguageChanged: (Locale locale) {
            // Handle language change if needed - this would typically
            // be passed down from a parent widget
          },
        ),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        business: widget.business,
        apiService: _apiService,
        onItemAdded: (category, item) {
          _loadCategories();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.itemAddedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showEditItemDialog(Dish item) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(
        dish: item,
        business: widget.business,
        apiService: _apiService,
        onItemUpdated: (dish) {
          _loadCategories();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.itemUpdatedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(loc.items),
            if (_userData != null && _userData!['business_name'] != null)
              Text(
                _userData!['business_name'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: loc.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: loc.search,
                prefixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch(); // Reload all categories
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _categories.isEmpty
                ? Center(child: Text(loc.noItemsFound))
                : ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategorySection(category);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialogWithAuth,
        backgroundColor: const Color(0xFF00c1e8),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategorySection(ItemCategory category) {
    // Items are already filtered by the backend search
    final items = category.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(category.name,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ...items.map((item) {
          return ListTile(
            title: Text(item.name),
            subtitle: Text('${loc.currency} ${item.price.toStringAsFixed(2)}'),
            onTap: () => _showEditItemDialog(item),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == loc.edit.toLowerCase()) {
                  _showEditItemDialog(item);
                } else if (value == loc.delete.toLowerCase()) {
                  _showDeleteConfirmation(item);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: loc.edit.toLowerCase(), child: Text(loc.edit)),
                PopupMenuItem(
                    value: loc.delete.toLowerCase(), child: Text(loc.delete)),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showDeleteConfirmation(Dish item) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteItem),
        content: Text(loc.deleteItemConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItem(item);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  void _deleteItem(Dish item) async {
    try {
      // Verify authentication before performing delete operation
      final isSignedIn = await AppAuthService.isSignedIn();
      if (!isSignedIn) {
        throw Exception('Authentication required. Please sign in again.');
      }

      await _apiService.deleteItem(widget.business.id, item.id);
      _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.itemDeletedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Handle error
      print('ItemsManagementPage: Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${AppLocalizations.of(context)!.failedToDeleteItem}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AddItemDialog extends StatefulWidget {
  final Business business;
  final ApiService apiService;
  final Function(ItemCategory category, Dish item) onItemAdded;

  const AddItemDialog({
    Key? key,
    required this.business,
    required this.apiService,
    required this.onItemAdded,
  }) : super(key: key);

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _newCategoryController = TextEditingController();

  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _showNewCategoryField = false;
  List<ItemCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      print(
          'AddItemDialog: Loading categories for business: ${widget.business.id}');

      // Validate business ID first
      if (widget.business.id == 'unknown-id' || widget.business.id.isEmpty) {
        throw Exception(
            'Invalid business ID: ${widget.business.id}. Cannot load categories.');
      }

      // Check authentication using real Cognito service
      final isSignedIn = await AppAuthService.isSignedIn();
      if (!isSignedIn) {
        throw Exception(AppLocalizations.of(context)!.userNotLoggedIn);
      }

      // Verify we can get current user and access token
      final currentUser = await AppAuthService.getCurrentUser();
      final accessToken = await AppAuthService.getAccessToken();

      if (currentUser == null || accessToken == null) {
        throw Exception(
            'Authentication verification failed. Please sign in again.');
      }

      print(
          'AddItemDialog: User authenticated - ${currentUser['user']?['email'] ?? 'Unknown email'}');

      final categories =
          await widget.apiService.getCategories(widget.business.id);
      print('AddItemDialog: Loaded ${categories.length} categories');
      for (var category in categories) {
        print('Category: ${category.id} - ${category.name}');
      }
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('AddItemDialog: Error loading categories: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.failedToLoadCategories}: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              onPressed: _loadCategories,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isDesktop ? 600 : (isTablet ? 500 : double.infinity),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: isDesktop
              ? 600
              : (isTablet ? 500 : MediaQuery.of(context).size.width * 0.9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(
                  ResponsiveHelper.getResponsivePadding(context) *
                      0.8), // Reduced padding
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.addNewItem,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ),
                  if (!isMobile)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.getResponsivePadding(context) *
                          0.8), // Reduced padding
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image upload section - temporarily disabled
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.info, color: Colors.orange),
                            const SizedBox(height: 6),
                            Text(
                              'Image upload feature is temporarily disabled during cleanup.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      ),

                      // Category selection section
                      if (!_showNewCategoryField) ...[
                        if (_categories.isEmpty && !_showNewCategoryField)
                          Container(
                            margin: const EdgeInsets.only(
                                bottom: 12), // Reduced from 16 to 12
                            padding: const EdgeInsets.all(
                                12), // Reduced from 16 to 12
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.info, color: Colors.orange),
                                const SizedBox(
                                    height: 6), // Reduced from 8 to 6
                                Text(
                                  AppLocalizations.of(context)!
                                      .noCategoriesFoundMessage,
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(color: Colors.orange.shade700),
                                ),
                              ],
                            ),
                          ),
                        if (_categories.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: loc.selectCategory,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12, // Reduced from 16 to 12
                              ),
                            ),
                            isExpanded: true,
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category.id,
                                child: Text(
                                  category.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              print('Category selected: $value');
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                            validator: (value) => value == null &&
                                    !_showNewCategoryField &&
                                    _categories.isNotEmpty
                                ? loc.pleaseSelectCategory
                                : null,
                          ),
                      ],

                      // New category field
                      if (_showNewCategoryField) ...[
                        TextFormField(
                          controller: _newCategoryController,
                          decoration: InputDecoration(
                            labelText: loc.newCategoryName,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) =>
                              value?.isEmpty == true && _showNewCategoryField
                                  ? loc.pleaseEnterCategoryName
                                  : null,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Category toggle button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showNewCategoryField = !_showNewCategoryField;
                            });
                          },
                          icon: Icon(
                              _showNewCategoryField ? Icons.list : Icons.add),
                          label: Text(_showNewCategoryField
                              ? loc.selectExistingCategory
                              : loc.addNewCategory),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Form fields in responsive layout
                      if (isDesktop || isTablet) ...[
                        // Two-column layout for larger screens
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: loc.itemName,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12, // Reduced from 16 to 12
                                  ),
                                ),
                                validator: (value) => value?.isEmpty == true
                                    ? loc.pleaseEnterItemName
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: loc.price,
                                  border: const OutlineInputBorder(),
                                  prefixText: loc.currencyPrefix,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12, // Reduced from 16 to 12
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty == true)
                                    return loc.pleaseEnterPrice;
                                  if (double.tryParse(value!) == null) {
                                    return loc.pleaseEnterValidPrice;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: loc.description,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _imageUrlController,
                                decoration: InputDecoration(
                                  labelText:
                                      '${loc.imageUrl} (${loc.optional})',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12, // Reduced from 16 to 12
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 120,
                              child: SwitchListTile(
                                title: Text(
                                  loc.available,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: _isAvailable,
                                onChanged: (value) {
                                  setState(() {
                                    _isAvailable = value;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Single-column layout for mobile
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: loc.itemName,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                          validator: (value) => value?.isEmpty == true
                              ? loc.pleaseEnterItemName
                              : null,
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: loc.description,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: loc.price,
                            border: const OutlineInputBorder(),
                            prefixText: loc.currencyPrefix,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true)
                              return loc.pleaseEnterPrice;
                            if (double.tryParse(value!) == null) {
                              return loc.pleaseEnterValidPrice;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: InputDecoration(
                            labelText: '${loc.imageUrl} (${loc.optional})',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        SwitchListTile(
                          title: Text(loc.available),
                          value: _isAvailable,
                          onChanged: (value) {
                            setState(() {
                              _isAvailable = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: EdgeInsets.all(
                  ResponsiveHelper.getResponsivePadding(context) *
                      0.8), // Reduced padding
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  if (isMobile) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12), // Reduced from 14 to 12
                        ),
                        child: Text(loc.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12), // Reduced from 14 to 12
                          backgroundColor: const Color(0xff00c1e8),
                        ),
                        child: Text(loc.add),
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(loc.add),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Verify authentication before performing create operations
        final isSignedIn = await AppAuthService.isSignedIn();
        if (!isSignedIn) {
          throw Exception('Authentication required. Please sign in again.');
        }

        ItemCategory? category;
        if (_showNewCategoryField && _newCategoryController.text.isNotEmpty) {
          // Create new category
          category = await widget.apiService
              .createCategory(widget.business.id, _newCategoryController.text);
        } else if (_selectedCategoryId != null) {
          // Use existing category
          category = _categories.firstWhere((c) => c.id == _selectedCategoryId);
        } else {
          // This shouldn't happen due to validation, but handle gracefully
          throw Exception(
              AppLocalizations.of(context)!.pleaseSelectCategoryOrCreate);
        }

        final newItem = Dish(
          id: 'dish-${DateTime.now().millisecondsSinceEpoch}', // The backend will generate the ID
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          categoryId: category.id,
          isAvailable: _isAvailable,
          imageUrl: _imageUrlController.text.isEmpty
              ? null
              : _imageUrlController.text,
          businessId: widget.business.id,
        );

        final createdItem =
            await widget.apiService.createItem(widget.business.id, newItem);

        // Image upload functionality is temporarily disabled
        // if (_imageFile != null) {
        //   try {
        //     final imageUrl = await widget.apiService
        //         .uploadItemImage(createdItem.id, _imageFile!);
        //     createdItem.imageUrl = imageUrl;
        //     await widget.apiService.updateItem(widget.business.id, createdItem);
        //   } catch (imageError) {
        //     print('Error uploading image: $imageError');
        //     // Continue anyway, item was created successfully
        //   }
        // }

        widget.onItemAdded(category, createdItem);
        Navigator.of(context).pop();
      } catch (e) {
        print('Error adding item: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${AppLocalizations.of(context)!.failedToAddItem}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class EditItemDialog extends StatefulWidget {
  final Dish dish;
  final Business business;
  final ApiService apiService;
  final Function(Dish item) onItemUpdated;

  const EditItemDialog({
    Key? key,
    required this.dish,
    required this.business,
    required this.apiService,
    required this.onItemUpdated,
  }) : super(key: key);

  @override
  _EditItemDialogState createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  late bool _isAvailable;
  List<ItemCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dish.name);
    _descriptionController =
        TextEditingController(text: widget.dish.description);
    _priceController =
        TextEditingController(text: widget.dish.price.toString());
    _imageUrlController =
        TextEditingController(text: widget.dish.imageUrl ?? '');
    _isAvailable = widget.dish.isAvailable;
    _selectedCategoryId = widget.dish.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await widget.apiService.getCategories(widget.business.id);
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isDesktop ? 600 : (isTablet ? 500 : double.infinity),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: isDesktop
              ? 600
              : (isTablet ? 500 : MediaQuery.of(context).size.width * 0.9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(
                  ResponsiveHelper.getResponsivePadding(context) * 0.8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.editItem,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ),
                  if (!isMobile)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.getResponsivePadding(context) * 0.8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category selection
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: loc.selectCategory,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        isExpanded: true,
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(
                              category.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? loc.pleaseSelectCategory : null,
                      ),
                      const SizedBox(height: 16),

                      // Form fields in responsive layout
                      if (isDesktop || isTablet) ...[
                        // Two-column layout for larger screens
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: loc.itemName,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12, // Reduced from 16 to 12
                                  ),
                                ),
                                validator: (value) => value?.isEmpty == true
                                    ? loc.pleaseEnterItemName
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: loc.price,
                                  border: const OutlineInputBorder(),
                                  prefixText: loc.currencyPrefix,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12, // Reduced from 16 to 12
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty == true)
                                    return loc.pleaseEnterPrice;
                                  if (double.tryParse(value!) == null) {
                                    return loc.pleaseEnterValidPrice;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: loc.description,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _imageUrlController,
                                decoration: InputDecoration(
                                  labelText:
                                      '${loc.imageUrl} (${loc.optional})',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12, // Reduced from 16 to 12
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 120,
                              child: SwitchListTile(
                                title: Text(
                                  loc.available,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: _isAvailable,
                                onChanged: (value) {
                                  setState(() {
                                    _isAvailable = value;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Single-column layout for mobile
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: loc.itemName,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                          validator: (value) => value?.isEmpty == true
                              ? loc.pleaseEnterItemName
                              : null,
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: loc.description,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: loc.price,
                            border: const OutlineInputBorder(),
                            prefixText: loc.currencyPrefix,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true)
                              return loc.pleaseEnterPrice;
                            if (double.tryParse(value!) == null) {
                              return loc.pleaseEnterValidPrice;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: InputDecoration(
                            labelText: '${loc.imageUrl} (${loc.optional})',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12, // Reduced from 16 to 12
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        SwitchListTile(
                          title: Text(loc.available),
                          value: _isAvailable,
                          onChanged: (value) {
                            setState(() {
                              _isAvailable = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: EdgeInsets.all(
                  ResponsiveHelper.getResponsivePadding(context) *
                      0.8), // Reduced padding
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  if (isMobile) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12), // Reduced from 14 to 12
                        ),
                        child: Text(loc.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _updateItem,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12), // Reduced from 14 to 12
                          backgroundColor: const Color(0xff00c1e8),
                        ),
                        child: Text(loc.update),
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _updateItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(loc.update),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateItem() async {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final updatedDish = Dish(
        id: widget.dish.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        isAvailable: _isAvailable,
        categoryId: _selectedCategoryId!,
        businessId: widget.business.id,
      );

      try {
        // Verify authentication before performing update operation
        final isSignedIn = await AppAuthService.isSignedIn();
        if (!isSignedIn) {
          throw Exception('Authentication required. Please sign in again.');
        }

        final item =
            await widget.apiService.updateItem(widget.business.id, updatedDish);
        widget.onItemUpdated(item);
        Navigator.of(context).pop();
      } catch (e) {
        print('EditItemDialog: Error updating item: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${AppLocalizations.of(context)!.failedToUpdateItem}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
