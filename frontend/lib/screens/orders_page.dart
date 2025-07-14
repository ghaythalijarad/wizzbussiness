import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../services/order_timer_service.dart';
import '../services/app_auth_service.dart';
import '../screens/login_page.dart';
import '../widgets/order_card.dart';
import '../utils/responsive_helper.dart';

class OrdersPage extends StatefulWidget {
  final List<Order> orders;
  final Function(String, OrderStatus) onOrderUpdated;
  final String? businessId;
  final Function()? onOrdersRefresh;

  const OrdersPage({
    Key? key,
    required this.orders,
    required this.onOrderUpdated,
    this.businessId,
    this.onOrdersRefresh,
  }) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _selectedFilter = 'pending';
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _validateAuthenticationAndInitialize();
  }

  Future<void> _validateAuthenticationAndInitialize() async {
    try {
      // Check if business ID is provided
      if (widget.businessId == null || widget.businessId!.isEmpty) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // Check if user is signed in
      final isSignedIn = await AppAuthService.isSignedIn();
      if (!isSignedIn) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // Verify current user and access token
      final currentUser = await AppAuthService.getCurrentUser();
      final accessToken = await AppAuthService.getAccessToken();

      if (currentUser == null || accessToken == null) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // If all checks pass, proceed with initialization
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('Authentication validation failed: $e');
      _showAuthenticationRequiredDialog();
    }
  }

  void _showAuthenticationRequiredDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(
          Icons.security,
          color: Color(0xFF00C1E8),
          size: 48,
        ),
        title: Text(
          loc.userNotLoggedIn,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF001133),
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Please sign in to view orders',
          style: TextStyle(
            color: const Color(0xFF001133).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => _navigateToLogin(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF00C1E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(loc.signIn),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          onLanguageChanged: (locale) {
            // Handle language change if needed
          },
        ),
      ),
      (route) => false,
    );
  }

  OrderStatus? _getStatusFromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'ready':
        return OrderStatus.ready;
      case 'pickedUp':
        return OrderStatus.pickedUp;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'returned':
        return OrderStatus.returned;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00C1E8),
          ),
        ),
      );
    }

    final loc = AppLocalizations.of(context)!;
    List<Order> filteredOrders = widget.orders;
    final filterStatus = _getStatusFromString(_selectedFilter);
    if (filterStatus != null) {
      filteredOrders =
          widget.orders.where((o) => o.status == filterStatus).toList();
    }
    if (_selectedFilter == 'pending') {
      filteredOrders.sort((a, b) {
        final ra = OrderTimerService.getRemainingSeconds(a.id);
        final rb = OrderTimerService.getRemainingSeconds(b.id);
        return ra.compareTo(rb);
      });
    } else {
      filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      body: Column(
        children: [
          // Filter bar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Directionality(
              textDirection:
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip(loc.pending, 'pending'),
                    const SizedBox(width: 6),
                    _buildFilterChip(loc.confirmed, 'confirmed'),
                    const SizedBox(width: 6),
                    _buildFilterChip(loc.orderReady, 'ready'),
                    const SizedBox(width: 6),
                    _buildFilterChip(loc.pickedUp, 'pickedUp'),
                    const SizedBox(width: 6),
                    _buildFilterChip(loc.cancelled, 'cancelled'),
                    const SizedBox(width: 6),
                    _buildFilterChip(loc.orderReturned, 'returned'),
                  ],
                ),
              ),
            ),
          ),
          // Orders list
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Text(
                      loc.noOrdersFoundFor(_selectedFilter),
                    ),
                  )
                : ResponsiveHelper.isTablet(context) ||
                        ResponsiveHelper.isDesktop(context)
                    ? _buildGridLayout(filteredOrders)
                    : _buildListLayout(filteredOrders),
          ),
        ],
      ),
      floatingActionButton: null,
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

  Widget _buildListLayout(List<Order> orders) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onOrderUpdated: widget.onOrderUpdated,
        );
      },
    );
  }

  Widget _buildGridLayout(List<Order> orders) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: ResponsiveHelper.isDesktop(context) ? 1.2 : 0.85,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onOrderUpdated: widget.onOrderUpdated,
        );
      },
    );
  }
}
