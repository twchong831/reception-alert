import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../models/ceo_request.dart';
import '../store.dart';
import '../services/ws_manager.dart';

Router ceoRouter(Store store, WsManager wsManager) {
  final router = Router();
  final uuid = Uuid();

  // GET /api/ceo/requests — 요청 목록 조회
  router.get('/requests', (Request request) {
    final status = request.url.queryParameters['status'];
    final list = store.getCeoRequests(status: status);
    return Response.ok(
      jsonEncode(list.map((r) => r.toJson()).toList()),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /api/ceo/requests — 대표이사 요청 생성
  router.post('/requests', (Request request) async {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final type = body['type'] as String?;
    if (type == null || !['coffee', 'call'].contains(type)) {
      return Response(400,
          body: jsonEncode({'error': '유효하지 않은 요청 타입입니다'}),
          headers: {'content-type': 'application/json'});
    }

    final ceoRequest = CeoRequest(
      id: uuid.v4(),
      type: type,
      message: body['message'] as String?,
    );

    store.insertCeoRequest(ceoRequest);

    final message = {
      'type': 'ceo_request',
      'data': ceoRequest.toJson(),
    };

    wsManager.sendToSecretary(message);

    return Response.ok(
      jsonEncode(ceoRequest.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  // PATCH /api/ceo/requests/<id> — 요청 상태 업데이트
  router.patch('/requests/<id>', (Request request, String id) async {
    final ceoRequest = store.getCeoRequest(id);
    if (ceoRequest == null) {
      return Response(404,
          body: jsonEncode({'error': '요청을 찾을 수 없습니다'}),
          headers: {'content-type': 'application/json'});
    }

    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final newStatus = body['status'] as String?;
    if (newStatus != null) {
      store.updateCeoRequestStatus(id, newStatus);
      ceoRequest.status = newStatus;
    }

    final updateMessage = {
      'type': 'ceo_request_update',
      'data': ceoRequest.toJson(),
    };
    wsManager.sendToSecretary(updateMessage);
    wsManager.sendToCeo(updateMessage);

    return Response.ok(
      jsonEncode(ceoRequest.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}
