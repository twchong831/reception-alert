import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsService {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  String? _url;

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void connect(String serverIp, {String? teamId, bool admin = false}) {
    if (admin) {
      _url = 'ws://$serverIp:8803/ws/admin';
    } else if (teamId != null) {
      _url = 'ws://$serverIp:8803/ws/team/$teamId';
    } else {
      return;
    }
    _doConnect();
  }

  void connectAs(String serverIp) {
    _url = 'ws://$serverIp:8803/ws/as';
    _doConnect();
  }

  void connectCeo(String serverIp) {
    _url = 'ws://$serverIp:8803/ws/ceo';
    _doConnect();
  }

  void connectSecretary(String serverIp) {
    _url = 'ws://$serverIp:8803/ws/secretary';
    _doConnect();
  }

  void _doConnect() {
    if (_url == null) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url!));
      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            _controller.add(message);
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _doConnect);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}
