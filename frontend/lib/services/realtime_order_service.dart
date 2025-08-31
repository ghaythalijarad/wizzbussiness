import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/order.dart';
import '../models/delivery_address.dart';
import 'package:hadhir_business/config/app_config.dart';
import 'order_service.dart';
import 'app_auth_service.dart';
import 'audio_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final realtimeOrderServiceProvider = Provider<RealtimeOrderService>((ref) {
  return RealtimeOrderService();
});

/// Real-time order service for merchant notifications
class RealtimeOrderService {
  static final RealtimeOrderService _instance =
      RealtimeOrderService._internal();
  factory RealtimeOrderService() => _instance;
  RealtimeOrderService._internal();

  // Services
  final AudioNotificationService _audioService = AudioNotificationService();

  // WebSocket connection
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;
  bool _isConnected = false;
  bool _manualDisconnect = false;
  int _reconnectAttempts = 0;
  String? _businessId;
  String? _authToken;
  bool _isDisposed = false;

  // Sound notification tracking to prevent duplicates
  final Set<String> _soundPlayedForOrders = <String>{};
  Timer? _soundTrackingCleanupTimer;

  // Stream controllers
  StreamController<Order>? _newOrderController;
  StreamController<Map<String, dynamic>>? _orderUpdateController;
  StreamController<bool>? _connectionController;

  // Services
  final OrderService _orderService = OrderService();

  // Configuration
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const Duration pingInterval = Duration(seconds: 30);
  static const Duration pollingFallbackInterval = Duration(seconds: 15);

  // Streams - Initialize controllers on first access
  Stream<Order> get newOrderStream {
    _ensureControllersInitialized();
    return _newOrderController!.stream;
  }

  Stream<Map<String, dynamic>> get orderUpdateStream {
    _ensureControllersInitialized();
    return _orderUpdateController!.stream;
  }

  Stream<bool> get connectionStream {
    _ensureControllersInitialized();
    return _connectionController!.stream;
  }

  // Getters
  bool get isConnected => _isConnected;
  String? get businessId => _businessId;

  /// Ensure stream controllers are initialized
  void _ensureControllersInitialized() {
    if (_newOrderController == null || _newOrderController!.isClosed) {
      _newOrderController = StreamController<Order>.broadcast();
    }
    if (_orderUpdateController == null || _orderUpdateController!.isClosed) {
      _orderUpdateController =
          StreamController<Map<String, dynamic>>.broadcast();
    }
    if (_connectionController == null || _connectionController!.isClosed) {
      _connectionController = StreamController<bool>.broadcast();
    }
  }

  // Safe methods to add to stream controllers
  void _safeAddToNewOrderController(Order order) {
    if (!_isDisposed &&
        _newOrderController != null &&
        !_newOrderController!.isClosed) {
      _newOrderController!.add(order);
      
      // Play sound notification for new order (with deduplication)
      _playNewOrderNotificationSoundOnce(order);
    }
  }

  void _safeAddToOrderUpdateController(Map<String, dynamic> update) {
    if (!_isDisposed &&
        _orderUpdateController != null &&
        !_orderUpdateController!.isClosed) {
      _orderUpdateController!.add(update);
      
      // Play sound notification for order updates
      _playOrderUpdateNotificationSound(update);
    }
  }

  void _safeAddToConnectionController(bool connected) {
    if (!_isDisposed &&
        _connectionController != null &&
        !_connectionController!.isClosed) {
      _connectionController!.add(connected);
    }
  }

  /// Play sound notification for new orders (with deduplication)
  void _playNewOrderNotificationSoundOnce(Order order) {
    try {
      // Check if we've already played sound for this order
      if (_soundPlayedForOrders.contains(order.id)) {
        debugPrint('🔇 Sound already played for order: ${order.id}, skipping');
        return;
      }

      // Mark this order as having sound played
      _soundPlayedForOrders.add(order.id);

      // Determine if order should be treated as urgent
      bool isUrgent = order.totalAmount > 100.0; // Orders over $100 are urgent

      // Play appropriate sound based on urgency
      _audioService.playNotificationSound('new_order', isUrgent: isUrgent);

      debugPrint(
          '🔊 Sound notification played for order: ${order.id} (${isUrgent ? 'URGENT' : 'NORMAL'})');

      // Start cleanup timer if not already running
      _startSoundTrackingCleanup();
    } catch (e) {
      debugPrint('❌ Error playing sound notification: $e');
    }
  }

  /// Start cleanup timer to remove old order IDs from sound tracking
  void _startSoundTrackingCleanup() {
    _soundTrackingCleanupTimer?.cancel();
    _soundTrackingCleanupTimer =
        Timer.periodic(const Duration(minutes: 5), (_) {
      // Keep only recent order IDs (last 50 orders)
      if (_soundPlayedForOrders.length > 50) {
        final ordersToRemove = _soundPlayedForOrders.length - 50;
        final ordersList = _soundPlayedForOrders.toList();
        for (int i = 0; i < ordersToRemove; i++) {
          _soundPlayedForOrders.remove(ordersList[i]);
        }
        debugPrint(
            '🧹 Cleaned up ${ordersToRemove} old order IDs from sound tracking');
      }
    });
  }

  /// Play sound notification for order updates
  void _playOrderUpdateNotificationSound(Map<String, dynamic> update) {
    try {
      final status = update['status']?.toString() ?? '';
      final orderId = update['orderId']?.toString() ?? 'unknown';

      // Play different sounds based on update type
      switch (status.toLowerCase()) {
        case 'confirmed':
        case 'ready':
        case 'pickedup':
        case 'delivered':
          _audioService.playNotificationSound('order_update');
          debugPrint('🔊 Order update sound played for: $orderId ($status)');
          break;
        case 'cancelled':
        case 'returned':
          _audioService.playNotificationSound('order_update');
          debugPrint(
              '🔊 Order status change sound played for: $orderId ($status)');
          break;
        default:
          debugPrint('📝 Order update received (no sound): $orderId ($status)');
      }
    } catch (e) {
      debugPrint('❌ Error playing order update sound: $e');
    }
  }

  /// Initialize the service with business context
  Future<void> initialize(String businessId) async {
    _isDisposed = false; // Mark as active
    _ensureControllersInitialized();

    _businessId = businessId;
    _authToken = await AppAuthService.getAccessToken();

    // Initialize audio service
    await _audioService.initialize();
    debugPrint('🔊 Audio notification service initialized');

    if (_authToken == null || _authToken!.isEmpty) {
      debugPrint('❌ No auth token available for WebSocket connection');
      _startPollingFallback();
      return;
    }

    debugPrint(
        '✅ Initializing RealtimeOrderService with businessId: $_businessId');
    await _connectWebSocket();
    _startPollingFallback(); // Always have polling as backup
  }

  /// Connect to WebSocket
  Future<void> _connectWebSocket() async {
    if (_businessId == null || _businessId!.isEmpty) {
      debugPrint('❌ Cannot connect WebSocket: businessId is null or empty');
      return;
    }

    if (_authToken == null || _authToken!.isEmpty) {
      debugPrint('❌ Cannot connect WebSocket: auth token is null or empty');
      return;
    }

    if (_isDisposed) {
      debugPrint('❌ Cannot connect WebSocket: service is disposed');
      return;
    }

    _manualDisconnect = false; // Reset manual disconnect flag on new connection attempt

    try {
      // Get current user data for userId parameter
      final currentUser = await AppAuthService.getCurrentUser();
      final userId = currentUser?['userId'] ?? currentUser?['user']?['userId'];

      // Build WebSocket URL with proper parameters for unified tracking
      final wsUrl = '${AppConfig.webSocketUrl}'
          '?businessId=$_businessId'
          '&entityType=merchant'
          '&userId=${userId ?? _businessId}'
          '&merchantId=$_businessId'; // Keep for backward compatibility
      
      debugPrint('🔌 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['websocket'],
      );

      // Listen for messages
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDisconnection,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _safeAddToConnectionController(true);
      _startPing();

      debugPrint('✅ WebSocket connected successfully');

      // Send subscription message
      _sendWebSocketMessage({
        'type': 'SUBSCRIBE_ORDERS',
        'businessId': _businessId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      debugPrint('❌ WebSocket connection failed: $error');
      _handleWebSocketError(error);
    }
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic data) {
    if (_isDisposed) return;

    try {
      final message = json.decode(data);
      debugPrint('📦 Raw WebSocket message received: $message');
      
      // Handle different message structures from backend
      String? messageType;
      Map<String, dynamic>? payload;
      
      // Check for 'type' field (current backend format from order stream)
      if (message['type'] != null) {
        messageType = message['type'];
        payload = message['payload'] ?? message;
      }
      // Check for 'action' field (legacy format)
      else if (message['action'] != null) {
        messageType = message['action'];
        payload = message['payload'] ?? message;
      }
      // Check for direct message types
      else if (message['orderId'] != null || message['id'] != null) {
        messageType = 'NEW_ORDER';
        payload = message;
      }

      debugPrint('📦 WebSocket message type: $messageType');

      switch (messageType) {
        case 'NEW_ORDER':
        case 'actionable_order_notification':
        case 'new_order':
          _handleNewOrder(payload ?? message);
          break;
        case 'ORDER_UPDATE':
        case 'order_update':
          _safeAddToOrderUpdateController(payload ?? message);
          break;
        case 'CONNECTION_ESTABLISHED':
        case 'connection_established':
        case 'SUBSCRIBED':
          debugPrint('✅ WebSocket connection established.');
          break;
        case 'PONG':
          debugPrint('🏓 Received PONG response');
          break;
        default:
          debugPrint('🤷 Unhandled WebSocket message type: $messageType');
          debugPrint('📄 Full message: $message');
      }
    } catch (e) {
      debugPrint('❌ Error processing WebSocket message: $e');
      debugPrint('Raw data: $data');
    }
  }

  /// Handle new order messages
  void _handleNewOrder(Map<String, dynamic> message) {
    try {
      debugPrint('🔍 Processing new order notification: $message');
      
      // Try different possible data structures
      Map<String, dynamic>? orderData;
      
      // First, try the 'data' field (current backend format from order stream)
      if (message['data'] is Map<String, dynamic>) {
        orderData = message['data'] as Map<String, dynamic>;
        debugPrint('📦 Found order data in "data" field');
      }
      // Try the 'payload.data' structure
      else if (message['payload'] is Map<String, dynamic>) {
        final payload = message['payload'] as Map<String, dynamic>;
        if (payload['data'] is Map<String, dynamic>) {
          orderData = payload['data'] as Map<String, dynamic>;
          debugPrint('📦 Found order data in "payload.data" field');
        } else {
          // payload itself might contain order data
          orderData = payload;
          debugPrint('📦 Using payload as order data');
        }
      }
      // Try the 'notification' field
      else if (message['notification'] is Map<String, dynamic>) {
        final notification = message['notification'] as Map<String, dynamic>;
        if (notification['data'] is Map<String, dynamic>) {
          orderData = notification['data'] as Map<String, dynamic>;
          debugPrint('📦 Found order data in "notification.data" field');
        }
      }
      // Try the message itself as order data
      else if (message.containsKey('orderId') || message.containsKey('id')) {
        orderData = message;
        debugPrint('📦 Using message root as order data');
      }

      if (orderData != null) {
        debugPrint('📋 Order data to process: $orderData');

        // For messages from order stream, we need to reconstruct the full order
        // The stream only sends orderId and businessId, we need the full order details
        if (orderData.containsKey('orderId') &&
            orderData.containsKey('businessId') &&
            !orderData.containsKey('customerName')) {
          debugPrint(
              '🔄 Detected order stream message, fetching full order details');
          _fetchAndAddOrder(orderData['orderId'], orderData['businessId']);
          return;
        }
        
        // Ensure we have the required fields for Order.fromJson
        if (!orderData.containsKey('orderId') && orderData.containsKey('id')) {
          orderData['orderId'] = orderData['id'];
        }
        
        try {
          final order = Order.fromJson(orderData);
          _safeAddToNewOrderController(order);
          debugPrint('✅ Successfully parsed new order: ${order.id}');
        } catch (parseError) {
          debugPrint('❌ Error parsing order data: $parseError');
          debugPrint('📄 Order data: $orderData');
          
          // Create a minimal order object as fallback
          final fallbackOrder = _createFallbackOrder(
              orderData, orderData['businessId']?.toString() ?? 'unknown');
          if (fallbackOrder != null) {
            _safeAddToNewOrderController(fallbackOrder);
            debugPrint('🔄 Created fallback order: ${fallbackOrder.id}');
          }
        }
      } else {
        debugPrint('❌ No valid order data found in message: $message');
      }
    } catch (error) {
      debugPrint('❌ Error handling new order notification: $error');
      debugPrint('📄 Original message: $message');
    }
  }

  /// Fetch full order details when we only have orderId from stream
  void _fetchAndAddOrder(String orderId, String businessId) async {
    try {
      debugPrint('🔍 Fetching full order details for: $orderId');

      // Fetch fresh orders from the server to get the new order
      final orders = await _orderService.getMerchantOrders(businessId);
      final newOrder = orders.firstWhere(
        (order) => order.id == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      _safeAddToNewOrderController(newOrder);
      debugPrint('✅ Successfully fetched and added order: ${newOrder.id}');
    } catch (error) {
      debugPrint('❌ Error fetching order details: $error');

      // Create a minimal placeholder order
      final placeholderOrder = Order(
        id: orderId,
        businessId: businessId, // Add businessId parameter
        customerId: 'unknown',
        customerName: 'New Order (Loading...)',
        customerPhone: 'N/A',
        deliveryAddress: DeliveryAddress(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          street: 'Loading address...',
          city: 'Unknown',
          district: 'Unknown',
          country: 'Iraq',
          customerId: 'unknown',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        items: [],
        totalAmount: 0.0,
        createdAt: DateTime.now(),
        status: OrderStatus.pending,
        notes: 'Order details loading...',
      );

      _safeAddToNewOrderController(placeholderOrder);
      debugPrint('🔄 Added placeholder order, will refresh from server');

      // Trigger a refresh after a short delay
      Timer(const Duration(seconds: 2), () {
        _fetchAndAddOrder(orderId, businessId);
      });
    }
  }

  /// Create a fallback order when parsing fails
  Order? _createFallbackOrder(Map<String, dynamic> data, String businessId) {
    try {
      final orderId = data['orderId'] ?? data['id'] ?? 'unknown-${DateTime.now().millisecondsSinceEpoch}';
      
      return Order(
        id: orderId.toString(),
        businessId: businessId, // Add businessId parameter
        customerId: data['customerId']?.toString() ?? 'unknown',
        customerName: data['customerName']?.toString() ?? 'Unknown Customer',
        customerPhone: data['customerPhone']?.toString() ?? 'N/A',
        deliveryAddress: DeliveryAddress(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          street: data['deliveryAddress']?['street']?.toString() ?? 'Unknown Address',
          city: data['deliveryAddress']?['city']?.toString() ?? 'Unknown City',
          district:
              data['deliveryAddress']?['district']?.toString() ?? 'Unknown',
          state: data['deliveryAddress']?['state']?.toString(),
          country: data['deliveryAddress']?['country']?.toString() ?? 'Iraq',
          customerId: (data['customerId']?.toString() ?? 'unknown'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        items: [], // Will be populated later when full order is fetched
        totalAmount: (data['totalAmount'] ?? data['total'] ?? 0).toDouble(),
        createdAt: DateTime.now(),
        status: OrderStatus.pending,
        notes: data['notes']?.toString(),
      );
    } catch (error) {
      debugPrint('❌ Error creating fallback order: $error');
      return null;
    }
  }

  /// Handle WebSocket error
  void _handleWebSocketError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _isConnected = false;
    _safeAddToConnectionController(false);
    _stopPing();
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleWebSocketDisconnection() {
    debugPrint('🔌 WebSocket disconnected');
    _isConnected = false;
    _safeAddToConnectionController(false);
    _stopPing();
    if (!_isDisposed && !_manualDisconnect) {
      _scheduleReconnect();
    }
  }

  /// Send message through WebSocket
  void _sendWebSocketMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
        debugPrint('📤 WebSocket message sent: ${message['type']}');
      } catch (error) {
        debugPrint('❌ Error sending WebSocket message: $error');
      }
    }
  }

  /// Send merchant logout notification via WebSocket (public method)
  void sendMerchantLogout({required String businessId, required String userId}) {
    debugPrint('🔌 Sending merchant logout notification');
    _sendWebSocketMessage({
      'type': 'MERCHANT_LOGOUT',
      'businessId': businessId,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'reason': 'user_logout',
    });
  }

  /// Start periodic ping to keep connection alive
  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (_isConnected) {
        _sendWebSocketMessage({
          'type': 'PING',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Stop ping timer
  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_isDisposed || _reconnectAttempts >= maxReconnectAttempts) {
      debugPrint(
          '❌ Max reconnection attempts reached or service disposed. Using polling fallback.');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      _reconnectAttempts++;
      debugPrint('🔄 WebSocket reconnection attempt $_reconnectAttempts');
      _connectWebSocket();
    });
  }

  /// Start polling fallback for when WebSocket is not available
  void _startPollingFallback() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollingFallbackInterval, (_) async {
      if (!_isConnected && _businessId != null && !_isDisposed) {
        await _pollForNewOrders();
      }
    });
    debugPrint(
        '📊 Polling fallback started (${pollingFallbackInterval.inSeconds}s interval)');
  }

  /// Poll for new orders when WebSocket is not available
  List<String> _lastKnownOrderIds = [];

  Future<void> _pollForNewOrders() async {
    try {
      final orders = await _orderService.getMerchantOrders(_businessId);
      final currentOrderIds = orders.map((o) => o.id).toList();

      // Find new orders
      final newOrderIds = currentOrderIds
          .where((id) => !_lastKnownOrderIds.contains(id))
          .toList();

      for (final orderId in newOrderIds) {
        final order = orders.firstWhere((o) => o.id == orderId);
        if (order.status == OrderStatus.pending) {
          _safeAddToNewOrderController(order);
          debugPrint('🆕 New order found via polling: ${order.id}');
        }
      }

      _lastKnownOrderIds = currentOrderIds;
    } catch (error) {
      debugPrint('❌ Error polling for orders: $error');
    }
  }

  /// Refresh connection with new auth token
  Future<void> refreshConnection() async {
    _authToken = await AppAuthService.getAccessToken();
    if (_authToken != null && _businessId != null) {
      await disconnect();
      await _connectWebSocket();
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    _manualDisconnect = true;
    _channel?.sink.close();
    _stopPing();
    _reconnectTimer?.cancel();
    _isConnected = false;
    _safeAddToConnectionController(false);
    debugPrint('🔌 WebSocket disconnected manually');
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    debugPrint('🗑️ Disposing RealtimeOrderService...');
    _isDisposed = true;
    disconnect();
    _newOrderController?.close();
    _orderUpdateController?.close();
    _connectionController?.close();
    _soundTrackingCleanupTimer?.cancel();
    _audioService.dispose();
    debugPrint('✅ RealtimeOrderService disposed');
  }
}
