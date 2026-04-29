import 'package:dio/dio.dart';

class ApiService {
  late final Dio _dio;

  ApiService(String serverIp) {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://$serverIp:8803',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  // --- Teams ---
  Future<List<dynamic>> getTeams() async {
    final res = await _dio.get('/api/teams');
    return res.data as List;
  }

  Future<Map<String, dynamic>> createTeam(String name) async {
    final res = await _dio.post('/api/teams', data: {'name': name});
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteTeam(String id) async {
    await _dio.delete('/api/teams/$id');
  }

  // --- Auth ---
  Future<Map<String, dynamic>> authTeam(String code) async {
    final res = await _dio.post('/api/auth/team', data: {'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<bool> authAdmin(String password) async {
    final res = await _dio.post('/api/auth/admin', data: {'password': password});
    return (res.data as Map<String, dynamic>)['success'] == true;
  }

  // --- Visit ---
  Future<Map<String, dynamic>> createVisit({
    required String teamId,
    required String visitorName,
    required String visitorCompany,
    required String purpose,
  }) async {
    final res = await _dio.post('/api/visit', data: {
      'teamId': teamId,
      'visitorName': visitorName,
      'visitorCompany': visitorCompany,
      'purpose': purpose,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateVisitStatus(String id, String status) async {
    await _dio.patch('/api/visit/$id', data: {'status': status});
  }

  Future<List<dynamic>> getVisits({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final res = await _dio.get('/api/visit', queryParameters: params);
    return res.data as List;
  }

  // --- AS ---
  Future<Map<String, dynamic>> createAsTicket({
    required String customerName,
    required String contactNumber,
    required String productName,
    required String symptom,
    required bool privacyAgreed,
  }) async {
    final res = await _dio.post('/api/as', data: {
      'customerName': customerName,
      'contactNumber': contactNumber,
      'productName': productName,
      'symptom': symptom,
      'privacyAgreed': privacyAgreed,
    });
    return res.data as Map<String, dynamic>;
  }

  // --- Products ---
  Future<List<String>> getProducts() async {
    final res = await _dio.get('/api/products');
    return (res.data as List).map((e) => e as String).toList();
  }

  Future<void> addProduct(String name) async {
    await _dio.post('/api/products', data: {'name': name});
  }

  Future<void> deleteProduct(String name) async {
    await _dio.delete('/api/products/${Uri.encodeComponent(name)}');
  }

  // --- Admin ---
  Future<int> purgeExpiredData() async {
    final res = await _dio.post('/api/admin/purge-expired');
    return (res.data as Map<String, dynamic>)['purged'] as int;
  }

  // --- CEO ---
  Future<Map<String, dynamic>> createCeoRequest({
    required String type,
    String? message,
  }) async {
    final res = await _dio.post('/api/ceo/requests', data: {
      'type': type,
      if (message != null) 'message': message,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCeoRequests({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final res = await _dio.get('/api/ceo/requests', queryParameters: params);
    return res.data as List;
  }

  Future<void> updateCeoRequestStatus(String id, String status) async {
    await _dio.patch('/api/ceo/requests/$id', data: {'status': status});
  }

  Future<void> updateAsStatus(String id, String status) async {
    await _dio.patch('/api/as/$id', data: {'status': status});
  }

  Future<List<dynamic>> getAsTickets({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final res = await _dio.get('/api/as', queryParameters: params);
    return res.data as List;
  }
}
