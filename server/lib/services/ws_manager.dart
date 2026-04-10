import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsManager {
  // teamId -> list of connected WebSocket channels
  final Map<String, List<WebSocketChannel>> _connections = {};

  // admin connections
  final List<WebSocketChannel> _adminConnections = [];

  // AS 전용 connections
  final List<WebSocketChannel> _asConnections = [];

  void addConnection(String teamId, WebSocketChannel channel) {
    _connections.putIfAbsent(teamId, () => []);
    _connections[teamId]!.add(channel);

    channel.stream.listen(
      (_) {},
      onDone: () => _connections[teamId]?.remove(channel),
      onError: (_) => _connections[teamId]?.remove(channel),
    );
  }

  void addAdminConnection(WebSocketChannel channel) {
    _adminConnections.add(channel);

    channel.stream.listen(
      (_) {},
      onDone: () => _adminConnections.remove(channel),
      onError: (_) => _adminConnections.remove(channel),
    );
  }

  void addAsConnection(WebSocketChannel channel) {
    _asConnections.add(channel);

    channel.stream.listen(
      (_) {},
      onDone: () => _asConnections.remove(channel),
      onError: (_) => _asConnections.remove(channel),
    );
  }

  void sendToTeam(String teamId, Map<String, dynamic> message) {
    final data = jsonEncode(message);
    final channels = _connections[teamId];
    if (channels == null) return;

    final dead = <WebSocketChannel>[];
    for (final ch in channels) {
      try {
        ch.sink.add(data);
      } catch (_) {
        dead.add(ch);
      }
    }
    for (final ch in dead) {
      channels.remove(ch);
    }
  }

  void sendToAdmins(Map<String, dynamic> message) {
    final data = jsonEncode(message);
    final dead = <WebSocketChannel>[];
    for (final ch in _adminConnections) {
      try {
        ch.sink.add(data);
      } catch (_) {
        dead.add(ch);
      }
    }
    for (final ch in dead) {
      _adminConnections.remove(ch);
    }
  }

  void sendToAs(Map<String, dynamic> message) {
    final data = jsonEncode(message);
    final dead = <WebSocketChannel>[];
    for (final ch in _asConnections) {
      try {
        ch.sink.add(data);
      } catch (_) {
        dead.add(ch);
      }
    }
    for (final ch in dead) {
      _asConnections.remove(ch);
    }
  }
}
