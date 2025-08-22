import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/realtime_order_service.dart';
import '../services/timer_service.dart';
import '../widgets/order_card.dart';
import '../providers/session_provider.dart';
import 'signin_screen.dart';
import '../utils/responsive_helper.dart';

class OrdersPage extends ConsumerStatefulWidget {
  final bool embedded;

  const OrdersPage({Key? key, this.embedded = false}) : super(key: key);

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  final OrderService _orderService = OrderService();
  final RealtimeOrderService _realtimeService = RealtimeOrderService();
  List<Order> _orders = [];
  String _selectedFilter = 'pending';
  bool _isInitializing = true;
  StreamSubscription? _newOrderSubscription;
  StreamSubscription? _orderUpdateSubscription;
  Timer? _expiredOrdersTimer;
  bool _showDiagnostics = false;
  final Map<String, DateTime> _lastStatusSnackShown = {};
  static const Duration _statusSnackDebounce = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _validateAuthenticationAndInitialize();
  }

  @override
  void dispose() {
    _expiredOrdersTimer?.cancel();
    _cleanupRealtimeService();
    super.dispose();
  }

  void _initializeRealtimeService() {
    _newOrderSubscription = _realtimeService.newOrderStream.listen((newOrder) {
      debugPrint('🔔 New order received via real-time service: ${newOrder.id}');
      if (mounted) {
        setState(() {
          final existingIndex = _orders.indexWhere((o) => o.id == newOrder.id);
          if (existingIndex == -1) {
            _orders.insert(0, newOrder);
          }
          if (_selectedFilter != 'pending') {
            _selectedFilter = 'pending';
          }
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🆕 New order from ${newOrder.customerName} for ${newOrder.totalAmount.toStringAsFixed(2)} IQD'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => setState(() => _selectedFilter = 'pending'),
            ),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () async {
          final session = ref.read(sessionProvider);
          if (mounted &&
              session.isAuthenticated &&
              session.businessId != null) {
            await _loadOrders(session.businessId!, preserveNewOrders: true);
          }
        });
      }
    });

    _orderUpdateSubscription =
        _realtimeService.orderUpdateStream.listen((update) {
      if (mounted) {
        _handleRealtimeOrderUpdate(update);
      }
    });
  }

  void _cleanupRealtimeService() {
    _newOrderSubscription?.cancel();
    _orderUpdateSubscription?.cancel();
    _newOrderSubscription = null;
    _orderUpdateSubscription = null;
    if (!_isInitializing && _realtimeService.isConnected) {
      _realtimeService.disconnect();
    }
  }

  void _handleRealtimeOrderUpdate(Map<String, dynamic> update) {
    final orderId = update['orderId'] as String?;
    final status = update['status'] as String?;

    if (orderId == null || status == null) return;

    var orderIndex = _orders.indexWhere((order) => order.id == orderId);
    final orderStatus = _getStatusFromString(status);

    if (orderIndex == -1) {
      final session = ref.read(sessionProvider);
      if (session.isAuthenticated && session.businessId != null) {
        _orderService.getMerchantOrders(session.businessId!).then((remote) {
          if (!mounted) return;
          final maybe = remote.where((o) => o.id == orderId);
          if (maybe.isNotEmpty) {
            setState(() => _orders.insert(0, maybe.first));
            orderIndex = 0;
          }
        }).catchError((e) {
          debugPrint('⚠️ Reconcile fetch failed: $e');
        });
      }
    }

    if (orderIndex != -1 && orderStatus != null) {
      final current = _orders[orderIndex].status;
      if (current != orderStatus) {
        setState(() => _orders[orderIndex].status = orderStatus);
        _maybeShowStatusUpdateSnack(orderId, orderStatus);
      }
    }
  }

  void _maybeShowStatusUpdateSnack(String orderId, OrderStatus status) {
    if (!mounted) return;
    final now = DateTime.now();
    final last = _lastStatusSnackShown[orderId];
    if (last != null && now.difference(last) < _statusSnackDebounce) return;
    _lastStatusSnackShown[orderId] = now;

    final label = _statusLabel(status);
    final color = _statusColor(status);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #$orderId $label'),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'is pending';
      case OrderStatus.confirmed:
        return 'was confirmed';
      case OrderStatus.preparing:
        return 'is preparing';
      case OrderStatus.ready:
        return 'is ready';
      case OrderStatus.onTheWay:
        return 'is on the way';
      case OrderStatus.delivered:
        return 'was delivered';
      case OrderStatus.cancelled:
        return 'was cancelled';
      case OrderStatus.returned:
        return 'was returned';
      case OrderStatus.expired:
        return 'expired';
    }
  }

  Color _statusColor(OrderStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case OrderStatus.confirmed:
      case OrderStatus.ready:
      case OrderStatus.onTheWay:
      case OrderStatus.delivered:
        return scheme.primary;
      case OrderStatus.preparing:
        return scheme.secondary;
      case OrderStatus.cancelled:
      case OrderStatus.returned:
      case OrderStatus.expired:
        return Colors.redAccent;
      case OrderStatus.pending:
        return scheme.tertiaryContainer;
    }
  }

  Future<void> _validateAuthenticationAndInitialize() async {
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated || session.businessId == null) {
      _showAuthenticationRequiredDialog();
      return;
    }

    final businessId = session.businessId!;
    setState(() => _isInitializing = true);

    await _loadOrders(businessId);
    await _realtimeService.initialize(businessId);
    _initializeRealtimeService();

    if (mounted) {
      setState(() => _isInitializing = false);
      _startExpiredOrdersTimer();
    }
  }

  Future<void> _loadOrders(String businessId,
      {bool preserveNewOrders = false}) async {
    try {
      final orders = await _orderService.getMerchantOrders(businessId);
      if (mounted) {
        setState(() {
          List<Order> processedOrders = orders;
          final ordersToExpire = processedOrders
              .where((order) =>
                  order.status == OrderStatus.pending &&
                  order.timeoutStatus == OrderTimeoutStatus.autoReject)
              .toList();

          for (final order in ordersToExpire) {
            order.status = OrderStatus.expired;
            _handleOrderUpdate(order.id, OrderStatus.expired).catchError((e) {
              debugPrint('❌ Failed backend expire for ${order.id}: $e');
              if (mounted) setState(() => order.status = OrderStatus.pending);
            });
          }

          if (preserveNewOrders) {
            final serverOrderIds = processedOrders.map((o) => o.id).toSet();
            final localNewOrders =
                _orders.where((o) => !serverOrderIds.contains(o.id)).toList();
            _orders = [...localNewOrders, ...processedOrders];
          } else {
            _orders = processedOrders;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleOrderUpdate(String orderId, OrderStatus newStatus) async {
    try {
      if (newStatus == OrderStatus.confirmed) {
        await _orderService.acceptMerchantOrder(orderId);
      } else {
        String statusString = _convertOrderStatusToString(newStatus);
        await _orderService.updateMerchantOrderStatus(orderId, statusString);
      }
      final session = ref.read(sessionProvider);
      if (session.isAuthenticated && session.businessId != null) {
        await _loadOrders(session.businessId!);
      }
    } catch (e) {
      debugPrint('Failed to update order: $e');
    }
  }

  String _convertOrderStatusToString(OrderStatus status) {
    return status.toString().split('.').last.toLowerCase();
  }

  void _showAuthenticationRequiredDialog() {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc.userNotLoggedIn),
        content: const Text('Please sign in to view orders'),
        actions: [
          TextButton(
            onPressed: () => _navigateToLogin(),
            child: Text(loc.signIn),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) =>
            const SignInScreen(noticeMessage: 'Please sign in to view orders'),
      ),
      (route) => false,
    );
  }

  OrderStatus? _getStatusFromString(String value) {
    for (var status in OrderStatus.values) {
      if (status.toString().split('.').last.toLowerCase() ==
          value.toLowerCase()) {
        return status;
      }
    }
    return null;
  }

  Future<void> _refreshOrders() async {
    try {
      final session = ref.read(sessionProvider);
      if (session.isAuthenticated && session.businessId != null) {
        await _loadOrders(session.businessId!);
      }
      await _realtimeService.refreshConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Orders refreshed successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _startExpiredOrdersTimer() {
    _expiredOrdersTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _checkAndExpireOrders();
    });
  }

  void _checkAndExpireOrders() {
    if (_orders.isEmpty) return;
    bool changed = false;
    for (final order in _orders) {
      if (order.status == OrderStatus.pending &&
          order.timeoutStatus == OrderTimeoutStatus.autoReject) {
        setState(() => order.status = OrderStatus.expired);
        changed = true;
        _handleOrderUpdate(order.id, OrderStatus.expired);
      }
    }
    if (changed && _selectedFilter == 'pending' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⏰ Some orders have expired.'),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () => setState(() => _selectedFilter = 'expired'),
          ),
        ),
      );
    }
  }

  void _showArchiveStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildArchiveMenuItem(context, 'cancelled', 'Cancelled'),
          _buildArchiveMenuItem(context, 'returned', 'Returned'),
          _buildArchiveMenuItem(context, 'expired', 'Expired'),
        ],
      ),
    );
  }

  Widget _buildArchiveMenuItem(
      BuildContext context, String value, String label) {
    return ListTile(
      title: Text(label),
      onTap: () {
        setState(() => _selectedFilter = value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Order> filteredOrders = _orders;
    final filterStatus = _getStatusFromString(_selectedFilter);
    if (filterStatus != null) {
      filteredOrders = _orders.where((o) => o.status == filterStatus).toList();
    }

    final timerService = ref.watch(orderTimerServiceProvider);

    if (_selectedFilter == 'pending') {
      filteredOrders.sort((a, b) {
        final urgencyA = timerService.getUrgency(a);
        final urgencyB = timerService.getUrgency(b);
        int comparison = urgencyB.index.compareTo(urgencyA.index);
        if (comparison == 0) {
          return a.createdAt.compareTo(b.createdAt);
        }
        return comparison;
      });
    } else {
      filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final body = RefreshIndicator(
      onRefresh: _refreshOrders,
      child: Column(
        children: [
          _buildDiagnosticsBanner(),
          _buildFilterBar(),
          Expanded(
            child: ResponsiveHelper.isMobile(context)
                ? _buildListLayout(filteredOrders)
                : _buildGridLayout(filteredOrders),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _showArchiveStatusMenu(context),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          _buildFilterChip('pending', 'Pending'),
          _buildFilterChip('confirmed', 'Confirmed'),
          _buildFilterChip('preparing', 'Preparing'),
          _buildFilterChip('ready', 'Ready'),
          _buildFilterChip('ontheway', 'On The Way'),
          _buildFilterChip('delivered', 'Delivered'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedFilter = value);
          }
        },
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildListLayout(List<Order> orders) {
    if (orders.isEmpty) return const Center(child: Text('No orders found.'));
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onOrderUpdated: (id, status) => _handleOrderUpdate(id, status),
        );
      },
    );
  }

  Widget _buildGridLayout(List<Order> orders) {
    if (orders.isEmpty) return const Center(child: Text('No orders found.'));
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onOrderUpdated: (id, status) => _handleOrderUpdate(id, status),
        );
      },
    );
  }

  Widget _buildDiagnosticsBanner() {
    return StreamBuilder<bool>(
      stream: _realtimeService.connectionStream,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? _realtimeService.isConnected;
        if (!connected || _showDiagnostics) {
          return Container(
            color: connected
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(connected ? Icons.check_circle : Icons.error,
                    color: connected ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(connected ? 'Connected' : 'Disconnected'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () =>
                      setState(() => _showDiagnostics = !_showDiagnostics),
                )
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
