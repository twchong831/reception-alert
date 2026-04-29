import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:visitor_server/config.dart';
import 'package:visitor_server/store.dart';
import 'package:visitor_server/services/ws_manager.dart';
import 'package:visitor_server/models/team.dart';
import 'package:visitor_server/handlers/auth_handler.dart';
import 'package:visitor_server/handlers/visit_handler.dart';
import 'package:visitor_server/handlers/as_handler.dart';
import 'package:visitor_server/handlers/ceo_handler.dart';

void main() async {
  final config = Config.load();
  config.printConfig();

  final store = Store(dataDir: config.dataDir);
  await store.load();
  store.seedProducts(config.productList);
  print('DB loaded: ${store.teams.length} teams, '
      '${store.visits.length} visits, '
      '${store.asTickets.length} AS tickets, '
      '${store.getProducts().length} products');

  final wsManager = WsManager();
  final uuid = Uuid();

  final router = Router();

  // --- REST API ---

  // 팀 목록 조회
  router.get('/api/teams', (Request request) {
    final list = store.teams.values.map((t) => t.toJson()).toList();
    return Response.ok(
      jsonEncode(list),
      headers: {'content-type': 'application/json'},
    );
  });

  // 팀 생성 + 등록코드 발급
  router.post('/api/teams', (Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final name = body['name'] as String?;
    if (name == null || name.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': '팀명을 입력해주세요'}),
          headers: {'content-type': 'application/json'});
    }

    final code = 'KM-${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
    final team = Team(
      id: uuid.v4(),
      name: name,
      registrationCode: code,
    );

    store.insertTeam(team);

    wsManager.sendToAdmins({
      'type': 'team_created',
      'data': team.toJson(),
    });

    return Response.ok(
      jsonEncode(team.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  // 팀 삭제
  router.delete('/api/teams/<id>', (Request request, String id) async {
    if (store.getTeam(id) == null) {
      return Response(404,
          body: jsonEncode({'error': '팀을 찾을 수 없습니다'}),
          headers: {'content-type': 'application/json'});
    }
    store.deleteTeam(id);

    wsManager.sendToAdmins({
      'type': 'team_deleted',
      'data': {'id': id},
    });

    return Response.ok(
      jsonEncode({'success': true}),
      headers: {'content-type': 'application/json'},
    );
  });

  // 관리자: 개인정보 만료 데이터 수동 파기
  router.post('/api/admin/purge-expired', (Request request) async {
    final count = store.purgeExpiredAsTickets(
      retentionDays: config.privacyRetentionDays,
    );
    return Response.ok(
      jsonEncode({'purged': count}),
      headers: {'content-type': 'application/json'},
    );
  });

  // 제품 목록 조회
  router.get('/api/products', (Request request) {
    return Response.ok(
      jsonEncode(store.getProducts()),
      headers: {'content-type': 'application/json'},
    );
  });

  // 제품 추가
  router.post('/api/products', (Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final name = body['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      return Response(400,
          body: jsonEncode({'error': '제품명을 입력해주세요'}),
          headers: {'content-type': 'application/json'});
    }
    try {
      store.insertProduct(name.trim());
    } catch (_) {
      return Response(409,
          body: jsonEncode({'error': '이미 등록된 제품입니다'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(
      jsonEncode({'success': true}),
      headers: {'content-type': 'application/json'},
    );
  });

  // 제품 삭제
  router.delete('/api/products/<name>', (Request request, String name) async {
    store.deleteProduct(Uri.decodeComponent(name));
    return Response.ok(
      jsonEncode({'success': true}),
      headers: {'content-type': 'application/json'},
    );
  });

  // auth, visit, as 라우터 마운트
  router.mount('/api/auth/', authRouter(store, config).call);
  router.mount('/api/visit', visitRouter(store, wsManager).call);
  router.mount('/api/as', asRouter(store, wsManager).call);
  router.mount('/api/ceo/', ceoRouter(store, wsManager).call);

  // --- WebSocket ---

  // /ws/team/:teamId — 팀 태블릿 WebSocket
  router.get('/ws/team/<teamId>', (Request request, String teamId) {
    final handler = webSocketHandler((WebSocketChannel channel) {
      print('Team WS connected: $teamId');
      wsManager.addConnection(teamId, channel);
    });
    return handler(request);
  });

  // /ws/as — AS 전용 WebSocket
  router.get('/ws/as', (Request request) {
    final handler = webSocketHandler((WebSocketChannel channel) {
      print('AS WS connected');
      wsManager.addAsConnection(channel);
    });
    return handler(request);
  });

  // /ws/ceo — 대표이사 WebSocket
  router.get('/ws/ceo', (Request request) {
    final handler = webSocketHandler((WebSocketChannel channel) {
      print('CEO WS connected');
      wsManager.addCeoConnection(channel);
    });
    return handler(request);
  });

  // /ws/secretary — 비서 WebSocket
  router.get('/ws/secretary', (Request request) {
    final handler = webSocketHandler((WebSocketChannel channel) {
      print('Secretary WS connected');
      wsManager.addSecretaryConnection(channel);
    });
    return handler(request);
  });

  // /ws/admin — 관리자 WebSocket
  router.get('/ws/admin', (Request request) {
    final handler = webSocketHandler((WebSocketChannel channel) {
      print('Admin WS connected');
      wsManager.addAdminConnection(channel);
    });
    return handler(request);
  });

  // CORS middleware for LAN access
  final handler = const Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // 서버 시작 시 만료 개인정보 파기 + 매일 자동 실행
  final purged = store.purgeExpiredAsTickets(
    retentionDays: config.privacyRetentionDays,
  );
  if (purged > 0) print('개인정보 파기: $purged건 익명화 처리');
  Timer.periodic(const Duration(hours: 24), (_) {
    final count = store.purgeExpiredAsTickets(
      retentionDays: config.privacyRetentionDays,
    );
    if (count > 0) print('개인정보 자동 파기: $count건 익명화 처리');
  });

  final server = await io.serve(handler, config.host, config.port);
  print('Server running on http://${server.address.host}:${server.port}');
}

Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};
