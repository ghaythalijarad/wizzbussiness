import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/order.dart';
import '../config/app_config.dart';
import 'order_service.dart';
import 'app_auth_service.dart';

/// Real-time order service for merchant notifications
class RealtimeOrderService extends ChangeNotifier {
  static final RealtimeOrderService _instance =
      RealtimeOrderService._internal();
  factory RealtimeOrderService() => _instance;
  RealtimeOrderService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  String? _businessId;
  String? _authToken;
  bool _isDisposed = false;

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
    if (_isDisposed) return;
    
    _newOrderController ??= StreamController<Order>.broadcast();
    _orderUpdateController ??= StreamController<Map<String, dynamic>>.broadcast();
    _connectionController ??= StreamController<bool>.broadcast();
  }

  // Safe methods to add to stream controllers
  void _safeAddToNewOrderController(Order order) {
    if (!_isDisposed && _newOrderController != null && !_newOrderController!.isClosed) {
      _newOrderController!.add(order);
    }
  }
  
  void _safeAddToOrderUpdateController(Map<String, dynamic> update) {
    if (!_isDisposed && _orderUpdateController != null && !_orderUpdateController!.isClosed) {
      _orderUpdateController!.add(update);
    }
  }
  
  void _safeAddToConnectionController(bool connected) {
    if (!_isDisposed && _connectionController != null && !_connectionController!.isClosed) {
      _connectionController!.add(connected);
    }
  }

  /// Initialize the service with business context
  Future<void> initialize(String businessId) async {
    if (_isDisposed) {
      debugPrint('❌ Cannot initialize disposed RealtimeOrderService');
      return;
    }
    
    _businessId = businessId;
    _authToken = await AppAuthService.getAccessToken();

    if (_authToken == null || _authToken!.isEmpty) {
      debugPrint('❌ No auth token available for WebSocket connection');
      _startPollingFallback();
      return;
    }

    debugPrint('✅ Initializing RealtimeOrderService with businessId: $_businessId');
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

    try {
      final wsUrl = '${AppConfig.webSocketUrl}?merchantId=$_businessId';
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
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      debugPrint('📨 WebSocket message received: ${message['type']}');

      switch (message['type']) {
        case 'CONNECTION_ESTABLISHED':
          debugPrint('🎉 WebSocket connection established');
          break;

        case 'ORDER_NOTIFICATION':
          _handleOrderNotification(message);
          break;

        case 'NEW_ORDER':
          _handleNewOrderNotification(message);
          break;

        case 'ORDER_STATUS_UPDATE':
          _handleOrderStatusUpdate(message);
          break;

        case 'PONG':
          // Keep-alive response
          break;

        default:
          debugPrint('📦 Unknown message type: ${message['type']}');
      }
    } catch (error) {
      debugPrint('❌ Error parsing WebSocket message: $error');
    }
  }

  /// Handle new order notification
  void _handleNewOrderNotification(Map<String, dynamic> message) {
    try {
      final orderData = message['data'] as Map<String, dynamic>?;
      final notification = message['notification'] as Map<String, dynamic>?;

      if (orderData != null) {
        final order = Order.fromJson(orderData);
        _safeAddToNewOrderController(order);
        debugPrint('🆕 New order notification: ${order.id}');
      } else if (notification != null && notification['data'] != null) {
        final order = Order.fromJson(notification['data']);
        _safeAddToNewOrderController(order);
        debugPrint('🆕 New order from notification: ${order.id}');
      }
    } catch (error) {
      debugPrint('❌ Error handling new order notification: $error');
    }
  }

  /// Handle order notification
  void _handleOrderNotification(Map<String, dynamic> message) {
    try {
      final notification = message['notification'] as Map<String, dynamic>?;
      if (notification == null) return;

      final notificationType = notification['type'] as String?;

      switch (notificationType) {
        case 'NEW_ORDER':
          _handleNewOrderNotification(message);
          break;
        default:
          _safeAddToOrderUpdateController(message);
      }
    } catch (error) {
      debugPrint('❌ Error handling order notification: $error');
    }
  }

  /// Handle order status update
  void _handleOrderStatusUpdate(Map<String, dynamic> message) {
    _safeAddToOrderUpdateController(message);
    debugPrint(
        '📊 Order status update: ${message['orderId']} -> ${message['newStatus']}');
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
    _scheduleReconnect();
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
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint(
          '❌ Max reconnection attempts reached. Using polling fallback.');
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
      if (!_isConnected && _businessId != null) {
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
    _channel?.sink.close();
    _stopPing();
    _reconnectTimer?.cancel();
    _isConnected = false;
    _safeAddToConnectionController(false);
    debugPrint('🔌 WebSocket disconnected manually');
  }

  /// Dispose resources
  @override
  void dispose() {
    _isDisposed = true;
    disconnect();
    _pollingTimer?.cancel();
    
    // Safely close stream controllers
    _newOrderController?.close();
    _orderUpdateController?.close();
    _connectionController?.close();
    
    _newOrderController = null;
    _orderUpdateController = null;
    _connectionController = null;
    
    super.dispose();
  }
}
