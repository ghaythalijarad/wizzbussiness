import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/order_timer_service.dart';
import '../services/realtime_order_service.dart'; // Import real-time service
import '../services/app_auth_service.dart';
import '../screens/login_page.dart';
import '../widgets/order_card.dart';
import '../utils/responsive_helper.dart';

class OrdersPage extends StatefulWidget {
  final String? businessId;

  const OrdersPage({
    Key? key,
    this.businessId,
  }) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderService _orderService = OrderService();
  final RealtimeOrderService _realtimeService = RealtimeOrderService();
  List<Order> _orders = [];
  String _selectedFilter = 'pending';
  bool _isInitializing = true;
  bool _isLoading = true;
  StreamSubscription? _newOrderSubscription;
  StreamSubscription? _orderUpdateSubscription;
  StreamSubscription? _connectionSubscription;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _validateAuthenticationAndInitialize();
  }

  void _initializeRealtimeService() {
    // Subscribe to new orders
    _newOrderSubscription = _realtimeService.newOrderStream.listen((newOrder) {
      debugPrint('🔔 New order received via real-time service: ${newOrder.id}');
      if (mounted) {
        setState(() {
          _orders.insert(0, newOrder);
        });
      }
    });

    // Subscribe to order updates
    _orderUpdateSubscription =
        _realtimeService.orderUpdateStream.listen((update) {
      debugPrint('📝 Order update received: ${update['orderId']}');
      if (mounted) {
        _handleRealtimeOrderUpdate(update);
      }
    });

    // Subscribe to connection status
    _connectionSubscription =
        _realtimeService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });
  }

  @override
  void dispose() {
    _cleanupRealtimeService();
    super.dispose();
  }

  void _cleanupRealtimeService() {
    // Cancel subscriptions safely
    _newOrderSubscription?.cancel();
    _orderUpdateSubscription?.cancel();
    _connectionSubscription?.cancel();
    
    // Reset subscription references
    _newOrderSubscription = null;
    _orderUpdateSubscription = null;
    _connectionSubscription = null;
    
    // Only dispose the service if it was actually initialized
    if (!_isInitializing) {
      _realtimeService.dispose();
    }
  }

  void _handleRealtimeOrderUpdate(Map<String, dynamic> update) {
    final orderId = update['orderId'] as String?;
    final status = update['status'] as String?;

    if (orderId != null && status != null) {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        final orderStatus = _getStatusFromString(status);
        if (orderStatus != null) {
          setState(() {
            _orders[orderIndex].status = orderStatus;
          });
        }
      }
    }
  }

  Future<void> _validateAuthenticationAndInitialize() async {
    try {
      print('🔍 OrdersPage: businessId = "${widget.businessId}"');
      print('🔍 OrdersPage: businessId is null = ${widget.businessId == null}');
      print('🔍 OrdersPage: businessId is empty = ${widget.businessId?.isEmpty}');

      if (widget.businessId == null || widget.businessId!.isEmpty) {
        print('❌ OrdersPage: businessId is null or empty, showing auth dialog');
        _showAuthenticationRequiredDialog();
        return;
      }

      print('🔍 OrdersPage: Checking authentication status...');
      final isSignedIn = await AppAuthService.isSignedIn();
      print('🔍 OrdersPage: isSignedIn = $isSignedIn');
      
      if (!isSignedIn) {
        print('❌ OrdersPage: User not signed in, showing auth dialog');
        _showAuthenticationRequiredDialog();
        return;
      }

      print('🔍 OrdersPage: Getting current user and access token...');
      final currentUser = await AppAuthService.getCurrentUser();
      final accessToken = await AppAuthService.getAccessToken();

      print('🔍 OrdersPage: currentUser = $currentUser');
      print('🔍 OrdersPage: accessToken exists = ${accessToken != null && accessToken.isNotEmpty}');

      if (currentUser == null || accessToken == null) {
        print('❌ OrdersPage: No current user or access token, showing auth dialog');
        _showAuthenticationRequiredDialog();
        return;
      }

      print('✅ OrdersPage: Authentication validated, loading orders...');
      await _loadOrders();

      print('🔍 OrdersPage: Initializing real-time service...');
      // Initialize real-time service with business credentials
      await _realtimeService.initialize(widget.businessId!);
      
      // Now that authentication is validated and service is initialized, set up listeners
      _initializeRealtimeService();

      setState(() {
        _isInitializing = false;
      });
      
      print('✅ OrdersPage: Initialization completed successfully');
    } catch (e) {
      print('❌ OrdersPage: Authentication validation failed: $e');
      
      // Ensure we don't leave the app in a loading state
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      
      _showAuthenticationRequiredDialog();
    }
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _orderService.getMerchantOrders(widget.businessId);
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleOrderUpdate(String orderId, OrderStatus newStatus) async {
    try {
      if (newStatus == OrderStatus.confirmed) {
        await _orderService.acceptMerchantOrder(orderId);
      } else {
        // Convert OrderStatus enum to string for backend
        String statusString = _convertOrderStatusToString(newStatus);
        await _orderService.updateMerchantOrderStatus(orderId, statusString);
      }
      await _loadOrders();
    } catch (e) {
      print('Failed to update order: $e');
      // Optionally, show an error message to the user
    }
  }

  String _convertOrderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.onTheWay:
        return 'ontheway';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.returned:
        return 'returned';
      case OrderStatus.expired:
        return 'expired';
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
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'returned':
        return OrderStatus.returned;
      default:
        return null;
    }
  }

  /// Manual refresh of orders and real-time connection
  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh orders from API
      await _loadOrders();

      // Try to refresh real-time connection
      await _realtimeService.refreshConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orders refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh orders: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    List<Order> filteredOrders = _orders;
    final filterStatus = _getStatusFromString(_selectedFilter);
    if (filterStatus != null) {
      filteredOrders = _orders.where((o) => o.status == filterStatus).toList();
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
          // Connection status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green.shade600 : Colors.orange,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected
                      ? 'Real-time sync active'
                      : 'Using backup sync - WebSocket disconnected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
                    _buildFilterChip(loc.preparing, 'preparing'),
                    const SizedBox(width: 6),
                    _buildFilterChip(loc.orderReady, 'ready'),
                    const SizedBox(width: 6),
                    _buildFilterChip(loc.onTheWay, 'on_the_way'),
                    const SizedBox(width: 6),
                    _buildFilterChip(loc.delivered, 'delivered'),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                    ? Center(
                        child: Text(
                          loc.noOrdersFoundFor(_selectedFilter),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshOrders,
                        child: ResponsiveHelper.isTablet(context) ||
                                ResponsiveHelper.isDesktop(context)
                            ? _buildGridLayout(filteredOrders)
                            : _buildListLayout(filteredOrders),
                      ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    // Define the custom blue color #00C1E8 for fill and the pink color #C6007E for borders
    const customBlueColor = Color(0xFF00C1E8);
    const customPinkColor = Color(0xFFC6007E);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isSelected ? 2 : 0.5,
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? customBlueColor
            : const Color(0xFF001133).withOpacity(0.05),
        shadowColor: isSelected
            ? customBlueColor.withOpacity(0.3)
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
                    ? customPinkColor
                    : customPinkColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : customBlueColor,
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
          onOrderUpdated: _handleOrderUpdate,
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
          onOrderUpdated: _handleOrderUpdate,
        );
      },
    );
  }
}
