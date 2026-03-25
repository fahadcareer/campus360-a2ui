import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

class WebSocketService {
  late WebSocketChannel _channel;
  final String userId;
  final String token;
  final Function(dynamic) onMessageReceived;

  WebSocketService({
    required this.userId,
    required this.token,
    required this.onMessageReceived,
  }) {
    _connect();
  }

  void _connect() {
    final url = '${ApiConfig.websocketChat}/$userId?token=$token';
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel.stream.listen((message) {
      final decoded = jsonDecode(message);
      onMessageReceived(decoded);
    });
  }

  void sendMessage(String text) {
    _channel.sink.add(jsonEncode({'message': text}));
  }

  void sendAction(String action, dynamic value) {
    _channel.sink.add(jsonEncode({'action': action, 'value': value}));
  }

  void dispose() {
    _channel.sink.close();
  }
}
