import 'package:flutter/material.dart';
import '../models/order.dart';
import '../widgets/floating_order_card.dart';
import 'realtime_order_service.dart';
import 'order_service.dart';
import 'dart:async';

class FloatingOrderNotificationService {
  static final FloatingOrderNotificationService _instance =
      FloatingOrderNotificationService._internal();
  factory FloatingOrderNotificationService() => _instance;
  FloatingOrderNotificationService._internal();

  OverlayEntry? _currentOverlay;
  BuildContext? _context;
  StreamSubscription? _newOrderSubscription;
  final RealtimeOrderService _realtimeService = RealtimeOrderService();
  final OrderService _orderService = OrderService();

  /// Initialize the service with the root context
  void initialize(BuildContext context) {
    _context = context;
    _setupRealtimeOrderListener();
  }

  /// Setup listener for new orders from real-time service
  void _setupRealtimeOrderListener() {
    _newOrderSubscription?.cancel();
    _newOrderSubscription = _realtimeService.newOrderStream.listen((newOrder) {
      debugPrint('🔔 FloatingOrderNotificationService: New order received ${newOrder.id}');
      _showNewOrderNotification(newOrder);
    });
  }

  /// Show notification for a new order with integrated actions
  void _showNewOrderNotification(Order order) {
    showOrderNotification(
      order: order,
      onAccept: () => _handleAcceptOrder(order),
      onReject: () => _handleRejectOrder(order),
      onViewDetails: () => _handleViewOrderDetails(order),
    );
  }

  /// Handle accepting an order
  Future<void> _handleAcceptOrder(Order order) async {
    try {
      debugPrint('✅ Accepting order: ${order.id}');
      await _orderService.acceptMerchantOrder(order.id);
      _showSuccessMessage('Order accepted successfully');
    } catch (error) {
      debugPrint('❌ Error accepting order: $error');
      _showErrorMessage('Failed to accept order');
    }
  }

  /// Handle rejecting an order
  Future<void> _handleRejectOrder(Order order) async {
    try {
      debugPrint('❌ Rejecting order: ${order.id}');
      await _orderService.rejectMerchantOrder(order.id, reason: 'Restaurant is busy');
      _showSuccessMessage('Order rejected');
    } catch (error) {
      debugPrint('❌ Error rejecting order: $error');
      _showErrorMessage('Failed to reject order');
    }
  }

  /// Handle viewing order details - navigate to orders page
  void _handleViewOrderDetails(Order order) {
    if (_context == null) return;
    
    debugPrint('👁️ Viewing order details: ${order.id}');
    
    // Navigate back to the dashboard and show orders page (index 0)
    Navigator.of(_context!).popUntil((route) => route.isFirst);
    
    // TODO: Add logic to highlight specific order when BusinessDashboard supports it
    // For now, this will navigate to the orders page where users can find the order
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    if (_context == null) return;
    
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    if (_context == null) return;
    
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show a floating order notification
  void showOrderNotification({
    required Order order,
    required VoidCallback onAccept,
    required VoidCallback onReject,
    required VoidCallback onViewDetails,
    Duration autoHideDuration = const Duration(seconds: 15),
  }) {
    if (_context == null) {
      debugPrint('❌ FloatingOrderNotificationService not initialized');
      return;
    }

    // Remove existing overlay if any
    hideOrderNotification();

    // Create new overlay
    _currentOverlay = OverlayEntry(
      builder: (context) => _FloatingOrderOverlay(
        order: order,
        onAccept: () {
          hideOrderNotification();
          onAccept();
        },
        onReject: () {
          hideOrderNotification();
          onReject();
        },
        onViewDetails: () {
          hideOrderNotification();
          onViewDetails();
        },
        onDismiss: hideOrderNotification,
        autoHideDuration: autoHideDuration,
      ),
    );

    // Insert overlay
    Overlay.of(_context!).insert(_currentOverlay!);
  }

  /// Hide the current floating order notification
  void hideOrderNotification() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Check if a notification is currently showing
  bool get isShowingNotification => _currentOverlay != null;

  /// Dispose the service
  void dispose() {
    _newOrderSubscription?.cancel();
    hideOrderNotification();
    _context = null;
  }
}

class _FloatingOrderOverlay extends StatefulWidget {
  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;
  final VoidCallback onDismiss;
  final Duration autoHideDuration;

  const _FloatingOrderOverlay({
    required this.order,
    required this.onAccept,
    required this.onReject,
    required this.onViewDetails,
    required this.onDismiss,
    required this.autoHideDuration,
  });

  @override
  State<_FloatingOrderOverlay> createState() => _FloatingOrderOverlayState();
}

class _FloatingOrderOverlayState extends State<_FloatingOrderOverlay> {
  late final Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.autoHideDuration;
    
    // Auto-hide after specified duration
    Future.delayed(_duration, () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    
    // Position the notification based on screen size
    double? top;
    double? left;
    double? right;
    double? bottom;

    if (isDesktop) {
      // Desktop: Top-right corner
      top = mediaQuery.padding.top + 16;
      right = 16;
    } else if (isTablet) {
      // Tablet: Top-center
      top = mediaQuery.padding.top + 16;
      left = (screenWidth - 400) / 2;
    } else {
      // Mobile: Top-center with margins
      top = mediaQuery.padding.top + 16;
      left = 16;
      right = 16;
    }

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Material(
        color: Colors.transparent,
        child: FloatingOrderCard(
          order: widget.order,
          onAccept: widget.onAccept,
          onReject: widget.onReject,
          onTap: widget.onViewDetails,
          onDismiss: widget.onDismiss,
        ),
      ),
    );
  }
}

/// Extension to easily show floating order notifications from any widget
extension FloatingOrderNotificationExtension on BuildContext {
  void showFloatingOrderNotification({
    required Order order,
    required VoidCallback onAccept,
    required VoidCallback onReject,
    required VoidCallback onViewDetails,
    Duration autoHideDuration = const Duration(seconds: 15),
  }) {
    FloatingOrderNotificationService().showOrderNotification(
      order: order,
      onAccept: onAccept,
      onReject: onReject,
      onViewDetails: onViewDetails,
      autoHideDuration: autoHideDuration,
    );
  }

  void hideFloatingOrderNotification() {
    FloatingOrderNotificationService().hideOrderNotification();
  }
}
