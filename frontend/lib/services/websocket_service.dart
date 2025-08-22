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
  String? _lastBusinessId; // added
  final Ref ref;

  WebSocketService({
    required this.onMessage,
    required this.onDone,
    required this.onError,
    required this.ref,
  });

  void connect(String url, String token, {String? businessId}) {
    _lastUrl = url;
    _lastToken = token;
    _lastBusinessId = businessId ?? _lastBusinessId;
    _disconnect(); // Clean up previous connection state
    _connect();
  }

  void _connect() {
    if (_lastUrl == null || _lastToken == null) {
      print("WebSocket: URL or token not available for connection.");
      return;
    }
    print("WebSocket: Attempting to connect to $_lastUrl");

    // Build URI with required query params (businessId + entityType)
    Uri base = Uri.parse(_lastUrl!);
    final qp = Map<String, String>.from(base.queryParameters);
    if (_lastBusinessId != null && _lastBusinessId!.isNotEmpty) {
      qp['businessId'] = _lastBusinessId!;
      qp['entityType'] = 'merchant';
    }
    final uri = base.replace(queryParameters: qp);
    print("WebSocket: Final URI: $uri");

    // Ensure Bearer prefix (avoid duplicating if already present)
    final bearerHeader = _lastToken!.startsWith('Bearer ')
        ? _lastToken!
        : 'Bearer ${_lastToken!}';
    final headers = {'Authorization': bearerHeader};

    try {
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: headers,
        pingInterval: const Duration(seconds: 30),
      );
    } catch (e) {
      print("WebSocket: Immediate connect exception: $e");
      _scheduleReconnect();
      return;
    }

    print("WebSocket: Connection initiated.");
    _reconnectAttempts = 0; // Reset on successful initiation

    _channelSubscription = _channel!.stream.listen(
      (message) {
        print("WebSocket: Message received: $message");
        dynamic decodedMessage;
        try {
          decodedMessage = jsonDecode(message);
        } catch (_) {
          print("WebSocket: Non-JSON message");
          decodedMessage = message;
        }

        // Minimal example NEW_ORDER handling retained
        if (decodedMessage is Map &&
            decodedMessage['type'] == 'NEW_ORDER' &&
            decodedMessage['payload']?['data']?['actions'] != null) {
          final orderId = decodedMessage['payload']['data']['orderId'];
          final notificationService = ref.read(notificationServiceProvider);
          notificationService.addOrderNotification(
            title: 'New Order!',
            message: 'You have a new order: $orderId',
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
}
