import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../orders_page.dart';
import '../products_management_screen.dart';
import '../analytics_page.dart';
import '../discount_management_page.dart';
import '../profile_settings_page.dart';
import '../../models/business.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/app_state.dart';
import '../../services/app_auth_service.dart';
import '../../providers/session_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/modern_navigation_rail.dart';
import '../../widgets/modern_sidebar.dart';
import '../../utils/responsive_helper.dart';
import '../../l10n/app_localizations.dart';

class BusinessDashboard extends ConsumerStatefulWidget {
  final Business? initialBusiness;

  const BusinessDashboard({
    Key? key,
    this.initialBusiness,
  }) : super(key: key);

  @override
  ConsumerState<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends ConsumerState<BusinessDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isOnline = true;
  List<Order> _orders = [];
  bool _loadingOrders = false;
  bool _isToggling = false;

  final OrderService _orderService = OrderService();
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeData() async {
    final session = ref.read(sessionProvider);
    if (session.isAuthenticated && session.businessId != null) {
      await _loadOrders();
      await _loadOnlineStatus(session.businessId!);
    }
  }

  /// Load online status from API and sync with local state
  Future<void> _loadOnlineStatus(String businessId) async {
    try {
      await _appState.loadOnlineStatusFromAPI(businessId);
      if (mounted) {
        setState(() {
          _isOnline = _appState.isOnline;
        });
      }
    } catch (e) {
      debugPrint('Error loading online status: $e');
      // Keep the current persisted status if API fails
      if (mounted) {
        setState(() {
          _isOnline = _appState.isOnline;
        });
      }
    }
  }

  Future<void> _loadOrders() async {
    if (_loadingOrders) return;

    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated || session.businessId == null) return;

    setState(() {
      _loadingOrders = true;
    });

    try {
      final orders = await _orderService.getMerchantOrders(session.businessId!);
      if (mounted) {
        setState(() {
          _orders = orders;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingOrders = false;
        });
      }
    }
  }

  Future<void> _toggleOnlineStatus(bool isOnline) async {
    if (_isToggling) return;

    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated || session.businessId == null) {
      debugPrint('Cannot toggle status: missing authentication data');
      return;
    }

    setState(() {
      _isToggling = true;
    });

    try {
      // Get current user information to obtain userId
      final currentUser = await AppAuthService.getCurrentUser();
      if (currentUser == null || currentUser['userId'] == null) {
        throw Exception('Cannot get current user information');
      }

      // Use AppState to handle the toggle with real API call
      await _appState.setOnline(isOnline, (status) async {
        await _appState.updateBusinessOnlineStatus(
          session.businessId!,
          currentUser['userId']!,
          status,
        );
      });

      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });

        HapticFeedback.lightImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnline 
                ? AppLocalizations.of(context)!.businessNowOnline 
                : AppLocalizations.of(context)!.businessNowOffline,
            ),
            backgroundColor: isOnline ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling online status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorUpdatingStatus,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onOrderUpdated(String orderId, OrderStatus newStatus) {
    setState(() {
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(status: newStatus);
      }
    });
  }

  Widget _buildDashboardBody(Business business) {
    switch (_selectedIndex) {
      case 0:
        return OrdersPage(businessId: business.id);
      case 1:
        return const ProductsManagementScreen();
      case 2:
        return AnalyticsPage(
          business: business,
          orders: _orders,
          onNavigateToOrders: () => _onNavigate(0),
          onOrderUpdated: _onOrderUpdated,
        );
      case 3:
        return DiscountManagementPage(
          business: business,
          orders: _orders,
          onNavigateToOrders: () => _onNavigate(0),
          onOrderUpdated: _onOrderUpdated,
        );
      case 4:
        return ProfileSettingsPage(
          business: business,
          orders: _orders,
        );
      default:
        return OrdersPage(businessId: business.id);
    }
  }

  Widget _buildMobileLayout(Business business) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.business,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                business.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          // Status Indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isOnline ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline
                      ? AppLocalizations.of(context)!.online
                      : AppLocalizations.of(context)!.offline,
                  style: TextStyle(
                    color:
                        _isOnline ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Hamburger Menu Button
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(
                Icons.menu,
                color: Color(0xFF00C1E8),
                size: 24,
              ),
              tooltip: AppLocalizations.of(context)!.menu,
            ),
          ),
        ],
      ),
      body: _buildDashboardBody(business),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavigate,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag),
            label: AppLocalizations.of(context)!.orders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2),
            label: AppLocalizations.of(context)!.items,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: AppLocalizations.of(context)!.analytics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_offer),
            label: AppLocalizations.of(context)!.discounts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
      endDrawer: ModernSidebar(
        isOnline: _isOnline,
        onToggleStatus: _toggleOnlineStatus,
        onNavigate: _onNavigate,
        onClose: () => Navigator.of(context).pop(),
        onReturnOrder: () {},
      ),
    );
  }

  Widget _buildTabletLayout(Business business) {
    return Scaffold(
      body: Row(
        children: [
          ModernNavigationRail(
            selectedIndex: _selectedIndex,
            onNavigate: _onNavigate,
            isOnline: _isOnline,
            onToggleStatus: _toggleOnlineStatus,
          ),
          Expanded(
            child: _buildDashboardBody(business),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Business business) {
    return Scaffold(
      body: Row(
        children: [
          ModernSidebar(
            isOnline: _isOnline,
            onToggleStatus: _toggleOnlineStatus,
            onReturnOrder: () {},
            onNavigate: _onNavigate,
            onClose: () {},
          ),
          Expanded(
            child: _buildDashboardBody(business),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessProvider);

    return businessAsync.when(
      data: (business) {
        if (business == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.business,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No business found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please contact support',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ResponsiveHelper.isMobile(context)
            ? _buildMobileLayout(business)
            : ResponsiveHelper.isTablet(context)
                ? _buildTabletLayout(business)
                : _buildDesktopLayout(business);
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading business',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(businessProvider),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
