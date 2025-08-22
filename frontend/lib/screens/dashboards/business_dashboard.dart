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
import '../product_auth_test_screen.dart';
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
    _timeoutService.onOrderAutoRejected = () {
      _loadOrders();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
      _startPeriodicRefresh();
    });
  }

  void _startPeriodicRefresh() {
    _orderRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _timeoutService.stopMonitoring();
    _timeoutService.onOrderAutoRejected = null;
    _orderRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated || session.businessId == null) return;
    try {
      final orders = await _orderService.getMerchantOrders(session.businessId!);
      if (mounted) {
        setState(() {
          _orders = orders;
        });
        _timeoutService.startMonitoring(_orders);
      }
    } catch (e) {
      print('Failed to load orders: $e');
    }
  }

  Future<void> _onToggleStatus(BuildContext context, bool isOnline) async {
    final loc = AppLocalizations.of(context)!;
    final apiService = ApiService();
    try {
      final currentBusinessAsync = ref.read(businessProvider);
      final currentBusiness = currentBusinessAsync.when(
          data: (b) => b, loading: () => null, error: (_, __) => null);
      if (currentBusiness == null)
        throw Exception('Business data not available');
      final user = await apiService.getMerchantDetails();
      await apiService.updateBusinessAcceptingOrdersStatus(
          currentBusiness.id, user.id, isOnline);
      ref.read(businessOnlineStatusProvider.notifier).state = isOnline;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                isOnline ? loc.businessIsNowOnline : loc.businessIsNowOffline),
            duration: const Duration(seconds: 2)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to update status: $error'),
            backgroundColor: Colors.red));
      }
    }
  }

  void _onReturnOrder(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(loc.returnOrderFeature)));
  }

  void _onNavigate(int pageIndex) {
    ref.read(dashboardPageIndexProvider.notifier).state = pageIndex;
  }

  Widget _buildDashboardBody(Business business) {
    final pageIndex = ref.watch(dashboardPageIndexProvider);
    final session = ref.watch(sessionProvider);
    if (!session.isAuthenticated || session.businessId == null) {
      return const Center(
        child: Text('Session expired. Please log in again.'),
      );
    }
    switch (pageIndex) {
      case 0:
        return const OrdersPage(embedded: true);
      case 1:
        return ProductsManagementScreen(
            business: business); // already no AppBar
      case 2:
        return AnalyticsPage(
            business: business, orders: _orders, embedded: true);
      case 3:
        return DiscountManagementPage(
            business: business, orders: _orders, embedded: true);
      case 4:
        return ProfileSettingsPage(
            business: business, orders: _orders, embedded: true);
      default:
        return Center(child: Text(AppLocalizations.of(context)!.errorOccurred));
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessAsyncValue = widget.initialBusiness != null
        ? AsyncValue.data(widget.initialBusiness!)
        : ref.watch(businessProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(floatingOrderNotificationServiceProvider).initialize(context);
    });

    return businessAsyncValue.when(
      data: (business) {
        if (business == null) {
          return const Scaffold(
              body: Center(child: Text('No business found for this account.')));
        }
        final isDesktop = ResponsiveHelper.isDesktop(context);
        final isTablet = ResponsiveHelper.isTablet(context);
        if (isDesktop) {
          return _buildDesktopLayout(context, business);
        } else if (isTablet) {
          return _buildTabletLayout(context, business);
        } else {
          return _buildMobileLayout(context, business);
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading business: $error'))),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Business business) {
    final isOnline = ref.watch(businessOnlineStatusProvider);
    final pageIndex = ref.watch(dashboardPageIndexProvider);
    return Scaffold(
      appBar: TopAppBar(
          title: '',
          isOnline: isOnline,
          onToggleStatus: (s) => _onToggleStatus(context, s),
          onReturnOrder: () => _onReturnOrder(context),
          onNavigate: (i) => _onNavigate(i)),
      body: _buildDashboardBody(business),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIndex,
        onTap: (i) => _onNavigate(i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'Products'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer), label: 'Discounts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, Business business) {
    final isOnline = ref.watch(businessOnlineStatusProvider);
    return Scaffold(
      appBar: TopAppBar(
          title: '',
          isOnline: isOnline,
          onToggleStatus: (s) => _onToggleStatus(context, s),
          onReturnOrder: () => _onReturnOrder(context),
          onNavigate: (i) => _onNavigate(i)),
      body: Row(children: [
        Container(
            width: 280,
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                    right: BorderSide(color: Colors.grey.shade300, width: 1))),
            child: _buildSideNavigation(context, business)),
        Expanded(child: _buildDashboardBody(business)),
      ]),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Business business) {
    final isOnline = ref.watch(businessOnlineStatusProvider);
    return Scaffold(
      appBar: TopAppBar(
          title: '',
          isOnline: isOnline,
          onToggleStatus: (s) => _onToggleStatus(context, s),
          onReturnOrder: () => _onReturnOrder(context),
          onNavigate: (i) => _onNavigate(i)),
      body: Row(children: [
        Container(
            width: 320,
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                    right: BorderSide(color: Colors.grey.shade300, width: 1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(2, 0))
                ]),
            child: _buildSideNavigation(context, business)),
        Expanded(
            child: Container(
                padding: ResponsiveHelper.getResponsiveMargin(context),
                child: _buildDashboardBody(business))),
      ]),
    );
  }

  Widget _buildSideNavigation(BuildContext context, Business business) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8)
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.store,
                      color: Colors.white, size: isDesktop ? 24 : 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(business.name,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 18 : 16),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(business.address ?? 'No address provided',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isDesktop ? 14 : 12),
                        overflow: TextOverflow.ellipsis),
                  ])),
            ]),
          ]),
        ),
        _buildNavigationItem(context, loc,
            icon: Icons.list_alt, label: loc.orders, index: 0),
        _buildNavigationItem(context, loc,
            icon: Icons.shopping_bag, label: 'Products', index: 1),
        _buildNavigationItem(context, loc,
            icon: Icons.analytics, label: loc.analytics, index: 2),
        _buildNavigationItem(context, loc,
            icon: Icons.local_offer, label: loc.discounts, index: 3),
        _buildNavigationItem(context, loc,
            icon: Icons.settings, label: loc.settings, index: 4),
      ]),
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
          borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade600),
        title: Text(label,
            style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.black87)),
        onTap: () => _onNavigate(index),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
