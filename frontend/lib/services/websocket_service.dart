import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';
import 'notification_service.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(
    ref: ref,
    onMessage: (data) {
      // Handle incoming messages globally or pass to another service
      print("Global WebSocket Message: $data");
    },
    onDone: () {
      print("Global WebSocket Closed");
    },
    onError: (error) {
      print("Global WebSocket Error: $error");
    },
  );
});

class WebSocketService {
  IOWebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  final Function(dynamic) onMessage;
  final Function() onDone;
  final Function(dynamic) onError;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _lastUrl;
  String? _lastToken;
  final Ref ref;

  WebSocketService({
    required this.onMessage,
    required this.onDone,
    required this.onError,
    required this.ref,
  });

  void connect(String url, String token) {
    _lastUrl = url;
    _lastToken = token;
    _disconnect(); // Clean up previous connection state
    _connect();
  }

  void _connect() {
    if (_lastUrl == null || _lastToken == null) {
      print("WebSocket: URL or token not available for connection.");
      return;
    }
    print("WebSocket: Attempting to connect to $_lastUrl");
    final headers = {'Authorization': _lastToken!};
    _channel = IOWebSocketChannel.connect(
      Uri.parse(_lastUrl!),
      headers: headers,
      pingInterval: const Duration(seconds: 30),
    );
    print("WebSocket: Connection established.");
    _reconnectAttempts = 0; // Reset on successful connection

    _channelSubscription = _channel!.stream.listen(
      (message) {
        print("WebSocket: Message received: $message");
        final decodedMessage = jsonDecode(message);

        // Check if this is an actionable order notification
        if (decodedMessage['type'] == 'NEW_ORDER' &&
            decodedMessage['payload']?['data']?['actions'] != null) {
          final orderId = decodedMessage['payload']['data']['orderId'];
          final notificationService = ref.read(notificationServiceProvider);
          notificationService.addOrderNotification(
            title: 'New Order!',
            body: 'You have a new order: $orderId',
            orderId: orderId,
          );
        }

        onMessage(decodedMessage);
      },
      onDone: () {
        print("WebSocket: Connection closed.");
        _channel = null;
        _channelSubscription = null;
        onDone();
        _scheduleReconnect();
      },
      onError: (error) {
        print("WebSocket: Error: $error");
        _channel = null;
        _channelSubscription = null;
        onError(error);
        _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;

    if (_reconnectAttempts >= 5) {
      print("WebSocket: Max reconnection attempts reached. Giving up.");
      return;
    }
    final delay = Duration(seconds: 2 * (_reconnectAttempts + 1));
    _reconnectAttempts++;
    print(
        "WebSocket: Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds} seconds.");
    _reconnectTimer = Timer(delay, _connect);
  }

  void disconnect() {
    print("WebSocket: Disconnecting manually.");
    _disconnect();
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _channelSubscription = null;
  }

  /// Send merchant status update when toggle is changed
  void sendMerchantStatusUpdate({
    required String businessId,
    required String userId,
    required bool isOnline,
  }) {
    if (_channel?.sink == null) {
      print("WebSocket: Cannot send status update - no active connection");
      return;
    }

    final message = {
      'type': 'BUSINESS_STATUS_UPDATE',
      'businessId': businessId,
      'userId': userId,
      'status': isOnline ? 'online' : 'offline',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _channel!.sink.add(jsonEncode(message));
      print("WebSocket: Merchant status update sent - $businessId: ${isOnline ? 'online' : 'offline'}");
    } catch (error) {
      print("WebSocket: Error sending merchant status update: $error");
    }
  }

  /// Send merchant logout notification
  void sendMerchantLogout({
    required String businessId,
    required String userId,
  }) {
    if (_channel?.sink == null) {
      print("WebSocket: Cannot send logout notification - no active connection");
      return;
    }

    final logoutMessage = {
      'type': 'MERCHANT_LOGOUT',
      'businessId': businessId,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'reason': 'user_logout',
    };

    try {
      _channel!.sink.add(jsonEncode(logoutMessage));
      print("WebSocket: Merchant logout notification sent - $businessId");
      
      // Wait a moment for the message to be sent before disconnecting
      Future.delayed(const Duration(milliseconds: 500), () {
        disconnect();
      });
    } catch (error) {
      print("WebSocket: Error sending logout notification: $error");
      // Still disconnect even if message fails
      disconnect();
    }
  }

  /// Send heartbeat/ping message
  void sendHeartbeat() {
    if (_channel?.sink == null) return;

    final message = {
      'type': 'HEARTBEAT',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (error) {
      print("WebSocket: Error sending heartbeat: $error");
    }
  }
}
