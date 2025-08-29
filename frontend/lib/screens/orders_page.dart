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
import '../core/theme/app_colors.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';

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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.new_releases_rounded,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🆕 New order from ${newOrder.customerName}\nTotal: ${newOrder.totalAmount.toStringAsFixed(2)} IQD',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              backgroundColor: AppColors.successContainer,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppColors.surface,
        elevation: 6,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.security_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        title: Text(
          loc.userNotLoggedIn,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Please sign in to view orders',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => _navigateToLogin(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.login_rounded),
            label: Text(loc.signIn),
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
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Orders refreshed successfully',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to refresh orders: $e',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer_off_rounded,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '⏰ Some orders have expired and moved to Expired tab',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VIEW EXPIRED',
            textColor: Colors.white,
            backgroundColor: AppColors.warningContainer,
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
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.archive_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Archive & History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.onSurfaceVariant,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Archive status options
            _buildArchiveMenuItem(
              context,
              icon: Icons.cancel_rounded,
              label: loc.cancelled,
              subtitle: 'View cancelled orders',
              value: 'cancelled',
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            _buildArchiveMenuItem(
              context,
              icon: Icons.keyboard_return_rounded,
              label: loc.orderReturned,
              subtitle: 'View returned orders',
              value: 'returned',
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            _buildArchiveMenuItem(
              context,
              icon: Icons.timer_off_rounded,
              label: 'Expired',
              subtitle: 'View expired/timed out orders',
              value: 'expired',
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
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
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shadowColor: isSelected
          ? color.withOpacity(0.2)
          : AppColors.onSurface.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : color.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                            color: isSelected ? color : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveMenuButton() {
    final isArchiveSelected =
        ['cancelled', 'returned', 'expired'].contains(_selectedFilter);
    
    // Use design system spacing
    final isMobile = ResponsiveHelper.isMobile(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: FilterChip(
        selected: isArchiveSelected,
        onSelected: (_) => _showArchiveStatusMenu(context),
        avatar: Icon(
          Icons.archive_rounded,
          color: isArchiveSelected ? AppColors.onPrimary : AppColors.primary,
          size: GoldenRatio.lg,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Archive',
              style: TypographySystem.labelLarge.copyWith(
                fontWeight:
                    isArchiveSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isArchiveSelected ? AppColors.onPrimary : AppColors.primary,
              ),
            ),
            SizedBox(width: GoldenRatio.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color:
                  isArchiveSelected ? AppColors.onPrimary : AppColors.primary,
              size: GoldenRatio.lg,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? GoldenRatio.lg : GoldenRatio.xl,
          vertical: GoldenRatio.md,
        ),
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: isArchiveSelected
              ? AppColors.secondary
              : AppColors.secondary.withOpacity(0.4),
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
        ),
        labelStyle: TypographySystem.labelLarge.copyWith(
          color: isArchiveSelected ? AppColors.onPrimary : AppColors.primary,
        ),
        elevation: isArchiveSelected ? GoldenRatio.xs : 0,
        shadowColor:
            isArchiveSelected ? AppColors.primary.withOpacity(0.3) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.backgroundVariant,
        body: Container(
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
          child: Center(
            child: Container(
              padding:
                  EdgeInsets.all(GoldenRatio.spacing24 + GoldenRatio.spacing8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
            ),
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
      backgroundColor: AppColors.backgroundVariant,
      body: Container(
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
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Filter chips with Material 3 design
                  Container(
                    margin: EdgeInsets.all(GoldenRatio.spacing16),
                    padding: EdgeInsets.all(GoldenRatio.spacing20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.04),
                          blurRadius: GoldenRatio.spacing20,
                          offset: Offset(0, GoldenRatio.spacing8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(loc.pending, 'pending'),
                          const SizedBox(width: 12),
                          _buildFilterChip(loc.confirmed, 'confirmed'),
                          const SizedBox(width: 12),
                          _buildFilterChip(loc.orderReady, 'ready'),
                          const SizedBox(width: 20),
                          _buildArchiveMenuButton(),
                        ],
                      ),
                    ),
                  ),

                  // Orders list
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: Container(
                              padding: EdgeInsets.all(GoldenRatio.spacing24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(GoldenRatio.radiusXl),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow.withOpacity(0.04),
                                    blurRadius: GoldenRatio.spacing20,
                                    offset: Offset(0, GoldenRatio.spacing8),
                                  ),
                                ],
                              ),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : filteredOrders.isEmpty
                            ? Center(
                                child: Container(
                                  margin: EdgeInsets.all(GoldenRatio.spacing24),
                                  padding: EdgeInsets.all(
                                      GoldenRatio.spacing24 +
                                          GoldenRatio.spacing8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                        GoldenRatio.radiusXl),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppColors.shadow.withOpacity(0.04),
                                        blurRadius: GoldenRatio.spacing20,
                                        offset: Offset(0, GoldenRatio.spacing8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                            GoldenRatio.spacing16),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                              GoldenRatio.radiusXl),
                                        ),
                                        child: Icon(
                                          Icons.inbox_outlined,
                                          size: GoldenRatio.spacing24 * 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      SizedBox(height: GoldenRatio.spacing20),
                                      Text(
                                        loc.noOrdersFoundFor(_selectedFilter),
                                        style: TypographySystem.titleLarge
                                            .copyWith(
                                          color: AppColors.onSurface,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: GoldenRatio.spacing12),
                                      Text(
                                        'When orders come in, they\'ll appear here',
                                        style: TypographySystem.bodyMedium
                                            .copyWith(
                                          color: AppColors.onSurface
                                              .withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _refreshOrders,
                                color: AppColors.primary,
                                backgroundColor: AppColors.surface,
                                child: ResponsiveHelper.isTablet(context) ||
                                        ResponsiveHelper.isDesktop(context)
                                    ? _buildGridLayout(filteredOrders)
                                    : _buildListLayout(filteredOrders),
                              ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isSelected ? 4 : 1,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        color: isSelected ? AppColors.primary : AppColors.surface,
        shadowColor: isSelected
            ? AppColors.primary.withOpacity(0.3)
            : AppColors.shadow.withOpacity(0.1),
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = value),
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: GoldenRatio.spacing20,
              vertical: GoldenRatio.spacing12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
              border: Border.all(
                color: isSelected 
                    ? AppColors.secondary.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Container(
                    padding: EdgeInsets.all(GoldenRatio.spacing4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(GoldenRatio.radiusSm),
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.onSecondary,
                      size: GoldenRatio.spacing16,
                    ),
                  ),
                  SizedBox(width: GoldenRatio.spacing8),
                ],
                Text(
                  label,
                  style: TypographySystem.labelLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.onPrimary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListLayout(List<Order> orders) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(GoldenRatio.lg),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Padding(
          padding: EdgeInsets.only(bottom: GoldenRatio.md),
          child: OrderCard(
            order: order,
            onOrderUpdated: _handleOrderUpdate,
          ),
        );
      },
    );
  }

  Widget _buildGridLayout(List<Order> orders) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(GoldenRatio.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: GoldenRatio.lg,
        mainAxisSpacing: GoldenRatio.lg,
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
