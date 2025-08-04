import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';

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

  WebSocketService({
    required this.onMessage,
    required this.onDone,
    required this.onError,
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
        onMessage(jsonDecode(message));
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
