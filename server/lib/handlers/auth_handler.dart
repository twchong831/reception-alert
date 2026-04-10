import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config.dart';
import '../store.dart';

Router authRouter(Store store, Config config) {
  final router = Router();

  // POST /api/auth/team — 등록코드로 팀 인증
  router.post('/team', (Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final code = body['code'] as String?;

    if (code == null || code.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': '등록코드를 입력해주세요'}),
          headers: {'content-type': 'application/json'});
    }

    final team = store.getTeamByCode(code);

    if (team == null) {
      return Response(401,
          body: jsonEncode({'error': '유효하지 않은 등록코드입니다'}),
          headers: {'content-type': 'application/json'});
    }

    return Response.ok(
      jsonEncode({'teamId': team.id, 'teamName': team.name}),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /api/auth/admin — 관리자 인증
  router.post('/admin', (Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final password = body['password'] as String?;

    if (password != config.adminPassword) {
      return Response(401,
          body: jsonEncode({'error': '비밀번호가 올바르지 않습니다'}),
          headers: {'content-type': 'application/json'});
    }

    return Response.ok(
      jsonEncode({'success': true}),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}
