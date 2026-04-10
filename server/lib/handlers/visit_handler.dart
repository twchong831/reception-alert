import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../models/visit.dart';
import '../store.dart';
import '../services/ws_manager.dart';

Router visitRouter(Store store, WsManager wsManager) {
  final router = Router();
  final uuid = Uuid();

  // GET /api/visit — 방문 기록 조회
  router.get('/', (Request request) {
    final status = request.url.queryParameters['status'];
    final list = store.getVisits(status: status);
    return Response.ok(
      jsonEncode(list.map((v) => v.toJson()).toList()),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /api/visit — 방문 알림 전송
  router.post('/', (Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final teamId = body['teamId'] as String?;
    final team = teamId != null ? store.getTeam(teamId) : null;
    if (team == null) {
      return Response(400,
          body: jsonEncode({'error': '유효하지 않은 팀입니다'}),
          headers: {'content-type': 'application/json'});
    }

    final visit = Visit(
      id: uuid.v4(),
      teamId: teamId!,
      visitorName: body['visitorName'] as String? ?? '',
      visitorCompany: body['visitorCompany'] as String? ?? '',
      purpose: body['purpose'] as String? ?? '',
    );

    store.insertVisit(visit);

    final message = {
      'type': 'visit',
      'data': {
        ...visit.toJson(),
        'teamName': team.name,
      },
    };
    wsManager.sendToTeam(teamId, message);
    wsManager.sendToAdmins(message);

    return Response.ok(
      jsonEncode(visit.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  // PATCH /api/visit/<id> — 방문 상태 업데이트
  router.patch('/<id>', (Request request, String id) async {
    final visit = store.getVisit(id);
    if (visit == null) {
      return Response(404,
          body: jsonEncode({'error': '방문 기록을 찾을 수 없습니다'}),
          headers: {'content-type': 'application/json'});
    }

    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final newStatus = body['status'] as String?;
    if (newStatus != null) {
      store.updateVisitStatus(id, newStatus);
      visit.status = newStatus;
    }

    wsManager.sendToTeam(visit.teamId, {
      'type': 'visit_update',
      'data': visit.toJson(),
    });
    wsManager.sendToAdmins({
      'type': 'visit_update',
      'data': visit.toJson(),
    });

    return Response.ok(
      jsonEncode(visit.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}
