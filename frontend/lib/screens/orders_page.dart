import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/order_timer_service.dart';
import '../services/realtime_order_service.dart';
import '../screens/login_page.dart';
import '../widgets/order_card.dart';
import '../utils/responsive_helper.dart';
import '../providers/session_provider.dart';

class OrdersPage extends ConsumerStatefulWidget {
  final String? businessId;

  const OrdersPage({
    Key? key,
    this.businessId,
  }) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  final OrderService _orderService = OrderService();
  final RealtimeOrderService _realtimeService = RealtimeOrderService();
  List<Order> _orders = [];
  String _selectedFilter = 'pending';
  bool _isInitializing = true;
  bool _isLoading = true;
  StreamSubscription? _newOrderSubscription;
  StreamSubscription? _orderUpdateSubscription;
  Timer? _expiredOrdersTimer; // Add timer for checking expired orders

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
        // FIRST: Add the order to local list for IMMEDIATE UI update
        setState(() {
          // Check if order already exists to avoid duplicates
          final existingIndex = _orders.indexWhere((order) => order.id == newOrder.id);
          if (existingIndex == -1) {
            // Insert at the beginning so it appears at the top
            _orders.insert(0, newOrder);
            debugPrint('✅ Added new order to local list: ${newOrder.id}');
          } else {
            debugPrint('⚠️ Order ${newOrder.id} already exists in local list');
          }
          
          // Ensure we're showing pending orders to see the new order
          if (_selectedFilter != 'pending') {
            _selectedFilter = 'pending';
            debugPrint('🔄 Switched filter to pending to show new order');
          }
        });
        
        // SECOND: Show prominent notification for new order
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.new_releases, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🆕 New order from ${newOrder.customerName}\nTotal: ${newOrder.totalAmount.toStringAsFixed(2)} IQD',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _selectedFilter = 'pending';
                });
              },
            ),
          ),
        );
        
        // THIRD: Refresh from server to sync with backend (delayed to not interfere with immediate UI)
        Future.delayed(const Duration(milliseconds: 500), () async {
          final session = ref.read(sessionProvider);
          if (mounted && session.isAuthenticated && session.businessId != null) {
            debugPrint('🔄 Refreshing orders from server after new order notification');
            await _loadOrders(session.businessId!, preserveNewOrders: true);
          }
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
  }

  @override
  void dispose() {
    _expiredOrdersTimer?.cancel();
    _cleanupRealtimeService();
    super.dispose();
  }

  void _cleanupRealtimeService() {
    // Cancel subscriptions safely
    _newOrderSubscription?.cancel();
    _orderUpdateSubscription?.cancel();
    
    // Reset subscription references
    _newOrderSubscription = null;
    _orderUpdateSubscription = null;
    
    // Disconnect but don't dispose the singleton service
    // The service handles its own lifecycle as a singleton
    if (!_isInitializing && _realtimeService.isConnected) {
      _realtimeService.disconnect();
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
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated || session.businessId == null) {
      _showAuthenticationRequiredDialog();
      return;
    }

    final businessId = session.businessId!;

    try {
      print('🔍 OrdersPage: businessId = "$businessId"');

      setState(() {
        _isInitializing = true;
      });

      await _loadOrders(businessId, preserveNewOrders: false);

      print('🔍 OrdersPage: Initializing real-time service...');
      await _realtimeService.initialize(businessId);
      
      _initializeRealtimeService();

      // Sync connection state and finish initialization
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        
        // Start the expired orders timer after successful initialization
        _startExpiredOrdersTimer();
      }
      
      print('✅ OrdersPage: Initialization completed successfully');
    } catch (e) {
      print('❌ OrdersPage: Initialization failed: $e');
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      
      _showAuthenticationRequiredDialog();
    }
  }

  Future<void> _loadOrders(String businessId, {bool preserveNewOrders = false}) async {
    try {
      final orders = await _orderService.getMerchantOrders(businessId);
      if (mounted) {
        setState(() {
          List<Order> processedOrders = orders;
          
          // Check for orders that should be expired and update them automatically
          final ordersToExpire = processedOrders
              .where((order) => order.status == OrderStatus.pending && order.shouldAutoReject())
              .toList();
          
          // Process expired orders
          for (final order in ordersToExpire) {
            debugPrint('⏰ Auto-expiring order ${order.id} due to timeout');
            // Update order status to expired locally immediately
            order.status = OrderStatus.expired;
            
            // Update on backend asynchronously (don't await to avoid blocking UI)
            _handleOrderUpdate(order.id, OrderStatus.expired).catchError((error) {
              debugPrint('❌ Failed to update expired order ${order.id} on backend: $error');
              // Revert status if backend update fails
              if (mounted) {
                setState(() {
                  order.status = OrderStatus.pending;
                });
              }
            });
          }
          
          if (preserveNewOrders) {
            // Merge server orders with any locally added new orders
            final serverOrderIds = processedOrders.map((o) => o.id).toSet();
            final localNewOrders = _orders.where((order) => 
              !serverOrderIds.contains(order.id) && 
              order.status == OrderStatus.pending
            ).toList();
            
            // Combine local new orders (at top) with server orders
            _orders = [...localNewOrders, ...processedOrders];
            debugPrint('📋 Merged ${localNewOrders.length} local new orders with ${processedOrders.length} server orders');
          } else {
            _orders = processedOrders;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
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
      final session = ref.read(sessionProvider);
      if (session.isAuthenticated && session.businessId != null) {
        await _loadOrders(session.businessId!, preserveNewOrders: false);
      }
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
      case OrderStatus.completed:
        return 'completed';
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
        builder: (context) => const LoginPage(),
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
      case 'expired':
        return OrderStatus.expired;
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
      final session = ref.read(sessionProvider);
      if (session.isAuthenticated && session.businessId != null) {
        await _loadOrders(session.businessId!, preserveNewOrders: false);
      }

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

  void _startExpiredOrdersTimer() {
    // Check for expired orders every 10 seconds
    _expiredOrdersTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _checkAndExpireOrders();
      }
    });
  }

  void _checkAndExpireOrders() {
    if (_orders.isEmpty) return;

    bool hasExpiredOrders = false;
    
    // Find orders that should be expired
    for (final order in _orders) {
      if (order.status == OrderStatus.pending && order.shouldAutoReject()) {
        debugPrint('⏰ Auto-expiring order ${order.id} due to timeout');
        
        // Update order status to expired locally immediately
        setState(() {
          order.status = OrderStatus.expired;
        });
        
        hasExpiredOrders = true;
        
        // Update on backend asynchronously
        _handleOrderUpdate(order.id, OrderStatus.expired).catchError((error) {
          debugPrint('❌ Failed to update expired order ${order.id} on backend: $error');
          // Revert status if backend update fails
          if (mounted) {
            setState(() {
              order.status = OrderStatus.pending;
            });
          }
        });
      }
    }
    
    // If we expired orders and user is viewing pending, show notification
    if (hasExpiredOrders && _selectedFilter == 'pending' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.timer_off, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⏰ Some orders have expired and moved to Expired tab',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VIEW EXPIRED',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _selectedFilter = 'expired';
              });
            },
          ),
        ),
      );
    }
  }

  void _showArchiveStatusMenu(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.archive_outlined,
                  color: Color(0xFF00C1E8),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Archive & History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF001133),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF001133)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Archive status options
            _buildArchiveMenuItem(
              context,
              icon: Icons.cancel_outlined,
              label: loc.cancelled,
              subtitle: 'View cancelled orders',
              value: 'cancelled',
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildArchiveMenuItem(
              context,
              icon: Icons.keyboard_return,
              label: loc.orderReturned,
              subtitle: 'View returned orders',
              value: 'returned',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildArchiveMenuItem(
              context,
              icon: Icons.timer_off_outlined,
              label: 'Expired',
              subtitle: 'View expired/timed out orders',
              value: 'expired',
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedFilter == value;
    
    return Material(
      color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : const Color(0xFF001133),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF001133).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveMenuButton() {
    final isArchiveSelected = ['cancelled', 'returned', 'expired'].contains(_selectedFilter);
    const customBlueColor = Color(0xFF00C1E8);
    const customPinkColor = Color(0xFFC6007E);
    
    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(context);
    
    double horizontalPadding;
    double verticalPadding;
    double fontSize;
    
    if (screenWidth < 400) {
      horizontalPadding = 12;
      verticalPadding = 8;
      fontSize = 13;
    } else if (isMobile) {
      horizontalPadding = 16;
      verticalPadding = 8;
      fontSize = 14;
    } else {
      horizontalPadding = 20;
      verticalPadding = 10;
      fontSize = 15;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isArchiveSelected ? 2 : 0.5,
        borderRadius: BorderRadius.circular(8),
        color: isArchiveSelected
            ? customBlueColor
            : const Color(0xFF001133).withOpacity(0.05),
        shadowColor: isArchiveSelected
            ? customBlueColor.withOpacity(0.3)
            : const Color(0xFF001133).withOpacity(0.1),
        child: InkWell(
          onTap: () => _showArchiveStatusMenu(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isArchiveSelected
                    ? customPinkColor
                    : customPinkColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.archive_outlined,
                  color: isArchiveSelected ? Colors.white : customBlueColor,
                  size: fontSize + 2,
                ),
                const SizedBox(width: 6),
                Text(
                  'Archive',
                  style: TextStyle(
                    color: isArchiveSelected ? Colors.white : customBlueColor,
                    fontWeight: isArchiveSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: fontSize,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isArchiveSelected ? Colors.white : customBlueColor,
                  size: fontSize + 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(loc.pending, 'pending'),
                      const SizedBox(width: 6),
                      _buildFilterChip(loc.confirmed, 'confirmed'),
                      const SizedBox(width: 6),
                      _buildFilterChip(loc.orderReady, 'ready'),
                      const SizedBox(width: 12),
                      // Archive menu button
                      _buildArchiveMenuButton(),
                    ],
                  ),
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
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    // Define the custom blue color #00C1E8 for fill and the pink color #C6007E for borders
    const customBlueColor = Color(0xFF00C1E8);
    const customPinkColor = Color(0xFFC6007E);

    // Responsive sizing for chips - longer and little higher
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(context);

    // Increased horizontal padding for longer chips
    double horizontalPadding;
    double verticalPadding; // Increased vertical padding for higher chips
    double fontSize;

    if (screenWidth < 400) {
      // Very small mobile screens
      horizontalPadding = 12; // Increased from 8 for longer chips
      verticalPadding = 8; // Increased from 4 for higher chips
      fontSize = 13; // Increased from 11 for better visibility
    } else if (isMobile) {
      // Regular mobile screens
      horizontalPadding = 16; // Increased from 10 for longer chips
      verticalPadding = 8; // Increased from 4 for higher chips
      fontSize = 14; // Increased from 12 for better visibility
    } else {
      // Desktop/tablet
      horizontalPadding = 20; // Increased from 12 for longer chips
      verticalPadding = 10; // Increased from 6 for higher chips
      fontSize = 15; // Increased from 13 for better visibility
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isSelected ? 2 : 0.5,
        borderRadius: BorderRadius.circular(
          8,
        ), // Reduced from 16 to 8 for less round corners
        color: isSelected
            ? customBlueColor
            : const Color(0xFF001133).withOpacity(0.05),
        shadowColor: isSelected
            ? customBlueColor.withOpacity(0.3)
            : const Color(0xFF001133).withOpacity(0.1),
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = value),
          borderRadius: BorderRadius.circular(
            8,
          ), // Match the container border radius
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                8,
              ), // Reduced corners here too
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
                fontSize: fontSize,
                letterSpacing: 0.1, // Slightly reduced letter spacing
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Handle text overflow
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
        );
      },
    );
  }
}
