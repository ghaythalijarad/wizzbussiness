import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/business.dart';
import '../../models/order.dart';
import '../../l10n/app_localizations.dart';
import '../orders_page.dart';
import '../profile_settings_page.dart';
import '../discount_management_page.dart';
import '../products_management_screen.dart';
import '../analytics_page.dart';
import '../../widgets/top_app_bar.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/session_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/floating_order_notification_service.dart';
import '../../services/api_service.dart';
import '../../services/order_service.dart';
import '../../services/order_timeout_service.dart';

class BusinessDashboard extends ConsumerStatefulWidget {
  final Business? initialBusiness;
  const BusinessDashboard({
    Key? key,
    this.initialBusiness,
  }) : super(key: key);

  @override
  _BusinessDashboardState createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends ConsumerState<BusinessDashboard> {
  final OrderService _orderService = OrderService();
  final OrderTimeoutService _timeoutService = OrderTimeoutService();
  List<Order> _orders = [];
  Timer? _orderRefreshTimer;

  @override
  void initState() {
    super.initState();

    // Set up callback for auto-rejection events
    _timeoutService.onOrderAutoRejected = () {
      // Refresh orders when an order is auto-rejected
      _loadOrders();
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
      _startPeriodicRefresh();
    });
  }

  /// Start periodic order refresh to update timeout monitoring
  void _startPeriodicRefresh() {
    _orderRefreshTimer = Timer.periodic(
      const Duration(seconds: 30), // Refresh every 30 seconds
      (_) => _loadOrders(),
    );
  }

  @override
  void dispose() {
    // Stop timeout monitoring and periodic refresh when dashboard is disposed
    _timeoutService.stopMonitoring();
    // Clear the callback to prevent memory leaks
    _timeoutService.onOrderAutoRejected = null;
    _orderRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated || session.businessId == null) {
      return;
    }

    try {
      final orders = await _orderService.getMerchantOrders(session.businessId!);
      if (mounted) {
        setState(() {
          _orders = orders;
        });

        // Start timeout monitoring for pending orders
        _timeoutService.startMonitoring(_orders);
      }
    } catch (e) {
      print('❌ Failed to load orders for analytics: $e');
    }
  }

  Future<void> _onToggleStatus(BuildContext context, bool isOnline) async {
    final loc = AppLocalizations.of(context)!;
    final apiService = ApiService();

    print('🔄 AppState: Starting toggle online status to: $isOnline');

    try {
      // Get current business and user data
      print('🔄 AppState: Getting current business...');
      final currentBusinessAsync = ref.read(businessProvider);
      final currentBusiness = currentBusinessAsync.when(
        data: (business) => business,
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      if (currentBusiness == null) {
        print('❌ AppState: Business data not available');
        throw Exception('Business data not available');
      }

      print('✅ AppState: Got current business: ${currentBusiness.id}');

      // Get user details
      print('🔄 AppState: Getting user details...');
      final user = await apiService.getMerchantDetails();
      print('✅ AppState: Got user details: ${user.id}');

      // Make API call to update business online status on backend
      print('🔄 AppState: Making API call to update status...');
      await apiService.updateBusinessOnlineStatus(
          currentBusiness.id, user.id, isOnline);

      print('✅ AppState: API call successful, updating provider state');
      // Update provider state only if backend call succeeds
      ref.read(businessOnlineStatusProvider.notifier).state = isOnline;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isOnline ? loc.businessIsNowOnline : loc.businessIsNowOffline),
            backgroundColor: isOnline ? Colors.green : Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('✅ AppState: Toggle online status completed successfully');
    } catch (error) {
      print('❌ AppState: Failed to toggle online status: $error');

      // Handle error and show user feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      // Don't rethrow here to prevent breaking the UI
    }
  }

  void _onReturnOrder(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.returnOrderFeature),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _onNavigate(int pageIndex) {
    ref.read(dashboardPageIndexProvider.notifier).state = pageIndex;
  }

  Widget _buildDashboardBody(Business business) {
    final pageIndex = ref.watch(dashboardPageIndexProvider);
    final session = ref.watch(sessionProvider);

    if (!session.isAuthenticated || session.businessId == null) {
      return const Center(child: Text('Session expired. Please log in again.'));
    }

    switch (pageIndex) {
      case 0:
        return OrdersPage(
          businessId: session.businessId!,
        );
      case 1:
        return ProductsManagementScreen(business: business);
      case 2:
        return AnalyticsPage(
          business: business,
          orders: _orders, // Pass real orders data
        );
      case 3:
        return DiscountManagementPage(
          business: business,
          orders: _orders, // Pass real orders data
        );
      case 4:
        return ProfileSettingsPage(
          business: business,
          orders: _orders, // Pass real orders data
        );
      default:
        return Center(child: Text(AppLocalizations.of(context)!.errorOccurred));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final businessAsyncValue = widget.initialBusiness != null
        ? AsyncValue.data(widget.initialBusiness!)
        : ref.watch(businessProvider);

    // Initialize floating notification service with root context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(floatingOrderNotificationServiceProvider).initialize(context);
    });

    return businessAsyncValue.when(
      data: (business) {
        if (business == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('No business found for this account.'),
                  SizedBox(height: 16),
                  // TODO: Add a sign out button here
                ],
              ),
            ),
          );
        }

        final isDesktop = ResponsiveHelper.isDesktop(context);
        final isTablet = ResponsiveHelper.isTablet(context);

        if (isDesktop) {
          return _buildDesktopLayout(context, loc, business);
        } else if (isTablet) {
          return _buildTabletLayout(context, loc, business);
        } else {
          return _buildMobileLayout(context, loc, business);
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error loading business: $error'),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, AppLocalizations loc, Business business) {
    final isOnline = ref.watch(businessOnlineStatusProvider);
    final pageIndex = ref.watch(dashboardPageIndexProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: isOnline,
        onToggleStatus: (status) async =>
            await _onToggleStatus(context, status),
        onReturnOrder: () => _onReturnOrder(context),
        onNavigate: (index) => _onNavigate(index),
      ),
      body: _buildDashboardBody(business),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIndex,
        onTap: (index) => _onNavigate(index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: loc.orders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: loc.analytics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_offer),
            label: loc.discounts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: loc.settings,
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildTabletLayout(
      BuildContext context, AppLocalizations loc, Business business) {
    final isOnline = ref.watch(businessOnlineStatusProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: isOnline,
        onToggleStatus: (status) async =>
            await _onToggleStatus(context, status),
        onReturnOrder: () => _onReturnOrder(context),
        onNavigate: (index) => _onNavigate(index),
      ),
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: _buildSideNavigation(context, loc, business),
          ),
          Expanded(
            child: _buildDashboardBody(business),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, AppLocalizations loc, Business business) {
    final isOnline = ref.watch(businessOnlineStatusProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: isOnline,
        onToggleStatus: (status) async =>
            await _onToggleStatus(context, status),
        onReturnOrder: () => _onReturnOrder(context),
        onNavigate: (index) => _onNavigate(index),
      ),
      body: Row(
        children: [
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: _buildSideNavigation(context, loc, business),
          ),
          Expanded(
            child: Container(
              padding: ResponsiveHelper.getResponsiveMargin(context),
              child: _buildDashboardBody(business),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigation(
      BuildContext context, AppLocalizations loc, Business business) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.store,
                        color: Colors.white,
                        size: isDesktop ? 24 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 18 : 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            business.address ?? 'No address provided',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isDesktop ? 14 : 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildNavigationItem(
            context,
            loc,
            icon: Icons.list_alt,
            label: loc.orders,
            index: 0,
          ),
          _buildNavigationItem(
            context,
            loc,
            icon: Icons.shopping_bag,
            label: 'Products',
            index: 1,
          ),
          _buildNavigationItem(
            context,
            loc,
            icon: Icons.analytics,
            label: loc.analytics,
            index: 2,
          ),
          _buildNavigationItem(
            context,
            loc,
            icon: Icons.local_offer,
            label: loc.discounts,
            index: 3,
          ),
          _buildNavigationItem(
            context,
            loc,
            icon: Icons.settings,
            label: loc.settings,
            index: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(BuildContext context, AppLocalizations loc,
      {required IconData icon, required String label, required int index}) {
    final pageIndex = ref.watch(dashboardPageIndexProvider);
    final isSelected = pageIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade600,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          ),
        ),
        onTap: () => _onNavigate(index),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
