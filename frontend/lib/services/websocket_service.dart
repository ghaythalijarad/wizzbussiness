import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  IOWebSocketChannel? _channel;
  final Function(dynamic) onMessage;
  final Function() onDone;
  final Function(dynamic) onError;

  WebSocketService({
    required this.onMessage,
    required this.onDone,
    required this.onError,
  });

  void connect(String url, String token) {
    print("WebSocket: Connecting to $url");
    final headers = {'Authorization': token};
    _channel = IOWebSocketChannel.connect(
      Uri.parse(url),
      headers: headers,
    );

    _channel!.stream.listen(
      (message) {
        print("WebSocket: Message received: $message");
        onMessage(jsonDecode(message));
      },
      onDone: () {
        print("WebSocket: Connection closed.");
        onDone();
      },
      onError: (error) {
        print("WebSocket: Error: $error");
        onError(error);
      },
    );
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
