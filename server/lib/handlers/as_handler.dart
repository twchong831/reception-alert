import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../models/as_ticket.dart';
import '../store.dart';
import '../services/ws_manager.dart';

Router asRouter(Store store, WsManager wsManager) {
  final router = Router();
  final uuid = Uuid();

  // GET /api/as — AS 목록 조회
  router.get('/', (Request request) {
    final status = request.url.queryParameters['status'];
    final list = store.getAsTickets(status: status);
    return Response.ok(
      jsonEncode(list.map((t) => t.toJson()).toList()),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /api/as — AS 접수
  router.post('/', (Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final privacyAgreed = body['privacyAgreed'] as bool? ?? false;
    if (!privacyAgreed) {
      return Response(400,
          body: jsonEncode({'error': '개인정보 수집·이용에 동의해주세요'}),
          headers: {'content-type': 'application/json'});
    }

    final ticket = AsTicket(
      id: uuid.v4(),
      customerName: body['customerName'] as String? ?? '',
      contactNumber: body['contactNumber'] as String? ?? '',
      productName: body['productName'] as String? ?? '',
      symptom: body['symptom'] as String? ?? '',
      privacyAgreed: true,
      privacyAgreedAt: DateTime.now(),
    );

    store.insertAsTicket(ticket);

    final message = {
      'type': 'as_ticket',
      'data': ticket.toJson(),
    };

    wsManager.sendToAs(message);
    wsManager.sendToAdmins(message);

    return Response.ok(
      jsonEncode(ticket.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  // PATCH /api/as/<id> — AS 상태 업데이트
  router.patch('/<id>', (Request request, String id) async {
    final ticket = store.getAsTicket(id);
    if (ticket == null) {
      return Response(404,
          body: jsonEncode({'error': 'AS 접수를 찾을 수 없습니다'}),
          headers: {'content-type': 'application/json'});
    }

    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final newStatus = body['status'] as String?;
    if (newStatus != null) {
      store.updateAsTicketStatus(id, newStatus);
      ticket.status = newStatus;
    }

    final updateMessage = {
      'type': 'as_update',
      'data': ticket.toJson(),
    };
    wsManager.sendToAs(updateMessage);
    wsManager.sendToAdmins(updateMessage);

    return Response.ok(
      jsonEncode(ticket.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}
