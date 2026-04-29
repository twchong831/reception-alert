import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

import 'models/team.dart';
import 'models/visit.dart';
import 'models/as_ticket.dart';
import 'models/ceo_request.dart';

class Store {
  final String dataDir;
  late final Database _db;

  Store({this.dataDir = '/app/data'});

  // --- 초기화 ---

  Future<void> load() async {
    final dir = Directory(dataDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _db = sqlite3.open('$dataDir/visitor.db');
    _createTables();
    _migrate();

    print('SQLite DB opened: $dataDir/visitor.db');
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        registration_code TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS visits (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        visitor_name TEXT NOT NULL DEFAULT '',
        visitor_company TEXT NOT NULL DEFAULT '',
        purpose TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (team_id) REFERENCES teams(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS as_tickets (
        id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL DEFAULT '',
        contact_number TEXT NOT NULL DEFAULT '',
        product_name TEXT NOT NULL DEFAULT '',
        symptom TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'received',
        privacy_agreed INTEGER NOT NULL DEFAULT 0,
        privacy_agreed_at TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS ceo_requests (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        message TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        confirmed_at TEXT
      )
    ''');

    // 인덱스
    _db.execute('CREATE INDEX IF NOT EXISTS idx_ceo_requests_status ON ceo_requests(status)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_ceo_requests_created_at ON ceo_requests(created_at)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_visits_team_id ON visits(team_id)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_visits_status ON visits(status)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_visits_created_at ON visits(created_at)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_as_status ON as_tickets(status)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_as_created_at ON as_tickets(created_at)');
  }

  /// 기존 DB에 새 컬럼이 없을 경우 추가
  void _migrate() {
    final columns = _db
        .select("PRAGMA table_info(as_tickets)")
        .map((r) => r['name'] as String)
        .toSet();

    if (!columns.contains('privacy_agreed')) {
      _db.execute('ALTER TABLE as_tickets ADD COLUMN privacy_agreed INTEGER NOT NULL DEFAULT 0');
    }
    if (!columns.contains('privacy_agreed_at')) {
      _db.execute('ALTER TABLE as_tickets ADD COLUMN privacy_agreed_at TEXT');
    }
    if (!columns.contains('completed_at')) {
      _db.execute('ALTER TABLE as_tickets ADD COLUMN completed_at TEXT');
    }
    if (!columns.contains('customer_name')) {
      _db.execute("ALTER TABLE as_tickets ADD COLUMN customer_name TEXT NOT NULL DEFAULT ''");
      // 기존 company_name 데이터를 customer_name으로 복사
      if (columns.contains('company_name')) {
        _db.execute('UPDATE as_tickets SET customer_name = company_name');
      }
    }
  }

  void dispose() {
    _db.dispose();
  }

  // ==================== Teams ====================

  /// 핸들러 호환용: teams Map 뷰
  Map<String, Team> get teams {
    final map = <String, Team>{};
    final results = _db.select('SELECT * FROM teams ORDER BY created_at');
    for (final row in results) {
      final team = _teamFromRow(row);
      map[team.id] = team;
    }
    return map;
  }

  Team? getTeam(String id) {
    final results = _db.select('SELECT * FROM teams WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _teamFromRow(results.first);
  }

  Team? getTeamByCode(String code) {
    final results = _db.select(
      'SELECT * FROM teams WHERE registration_code = ?', [code],
    );
    if (results.isEmpty) return null;
    return _teamFromRow(results.first);
  }

  void insertTeam(Team team) {
    _db.execute(
      'INSERT INTO teams (id, name, registration_code, created_at) VALUES (?, ?, ?, ?)',
      [team.id, team.name, team.registrationCode, team.createdAt.toIso8601String()],
    );
  }

  void deleteTeam(String id) {
    _db.execute('DELETE FROM teams WHERE id = ?', [id]);
  }

  // 핸들러 호환: saveTeams()는 이제 no-op (insert/delete가 즉시 반영)
  Future<void> saveTeams() async {}

  // ==================== Visits ====================

  /// 핸들러 호환용: visits Map 뷰
  Map<String, Visit> get visits {
    final map = <String, Visit>{};
    final results = _db.select('SELECT * FROM visits ORDER BY created_at DESC');
    for (final row in results) {
      final visit = _visitFromRow(row);
      map[visit.id] = visit;
    }
    return map;
  }

  List<Visit> getVisits({String? status, String? teamId, int? limit, int? offset}) {
    var sql = 'SELECT * FROM visits WHERE 1=1';
    final params = <Object?>[];

    if (status != null) {
      sql += ' AND status = ?';
      params.add(status);
    }
    if (teamId != null) {
      sql += ' AND team_id = ?';
      params.add(teamId);
    }

    sql += ' ORDER BY created_at DESC';

    if (limit != null) {
      sql += ' LIMIT ?';
      params.add(limit);
      if (offset != null) {
        sql += ' OFFSET ?';
        params.add(offset);
      }
    }

    return _db.select(sql, params).map(_visitFromRow).toList();
  }

  Visit? getVisit(String id) {
    final results = _db.select('SELECT * FROM visits WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _visitFromRow(results.first);
  }

  void insertVisit(Visit visit) {
    _db.execute(
      'INSERT INTO visits (id, team_id, visitor_name, visitor_company, purpose, status, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        visit.id, visit.teamId, visit.visitorName, visit.visitorCompany,
        visit.purpose, visit.status, visit.createdAt.toIso8601String(),
      ],
    );
  }

  void updateVisitStatus(String id, String status) {
    _db.execute('UPDATE visits SET status = ? WHERE id = ?', [status, id]);
  }

  // 핸들러 호환: saveVisits()는 이제 no-op
  Future<void> saveVisits() async {}

  // ==================== AS Tickets ====================

  /// 핸들러 호환용: asTickets Map 뷰
  Map<String, AsTicket> get asTickets {
    final map = <String, AsTicket>{};
    final results = _db.select('SELECT * FROM as_tickets ORDER BY created_at DESC');
    for (final row in results) {
      final ticket = _asTicketFromRow(row);
      map[ticket.id] = ticket;
    }
    return map;
  }

  List<AsTicket> getAsTickets({String? status, int? limit, int? offset}) {
    var sql = 'SELECT * FROM as_tickets WHERE 1=1';
    final params = <Object?>[];

    if (status != null) {
      sql += ' AND status = ?';
      params.add(status);
    }

    sql += ' ORDER BY created_at DESC';

    if (limit != null) {
      sql += ' LIMIT ?';
      params.add(limit);
      if (offset != null) {
        sql += ' OFFSET ?';
        params.add(offset);
      }
    }

    return _db.select(sql, params).map(_asTicketFromRow).toList();
  }

  AsTicket? getAsTicket(String id) {
    final results = _db.select('SELECT * FROM as_tickets WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _asTicketFromRow(results.first);
  }

  void insertAsTicket(AsTicket ticket) {
    _db.execute(
      'INSERT INTO as_tickets (id, customer_name, contact_number, product_name, symptom, status, privacy_agreed, privacy_agreed_at, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        ticket.id, ticket.customerName, ticket.contactNumber, ticket.productName,
        ticket.symptom, ticket.status,
        ticket.privacyAgreed ? 1 : 0,
        ticket.privacyAgreedAt?.toIso8601String(),
        ticket.createdAt.toIso8601String(),
      ],
    );
  }

  void updateAsTicketStatus(String id, String status) {
    if (status == 'done') {
      _db.execute(
        'UPDATE as_tickets SET status = ?, completed_at = ? WHERE id = ?',
        [status, DateTime.now().toIso8601String(), id],
      );
    } else {
      _db.execute('UPDATE as_tickets SET status = ? WHERE id = ?', [status, id]);
    }
  }

  /// 보관기간 만료된 AS 개인정보 삭제 (완료 후 retentionDays일 경과)
  int purgeExpiredAsTickets({int retentionDays = 365}) {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays)).toIso8601String();
    final result = _db.select(
      'SELECT COUNT(*) as cnt FROM as_tickets WHERE status = ? AND completed_at IS NOT NULL AND completed_at < ?',
      ['done', cutoff],
    );
    final count = result.first['cnt'] as int;

    if (count > 0) {
      // 개인정보만 익명화 (기록 자체는 통계용으로 보존)
      _db.execute(
        'UPDATE as_tickets SET contact_number = ?, customer_name = ? '
        'WHERE status = ? AND completed_at IS NOT NULL AND completed_at < ?',
        ['삭제됨', '삭제됨', 'done', cutoff],
      );
    }
    return count;
  }

  // 핸들러 호환: saveAsTickets()는 이제 no-op
  Future<void> saveAsTickets() async {}

  // ==================== CEO Requests ====================

  List<CeoRequest> getCeoRequests({String? status, int? limit, int? offset}) {
    var sql = 'SELECT * FROM ceo_requests WHERE 1=1';
    final params = <Object?>[];

    if (status != null) {
      sql += ' AND status = ?';
      params.add(status);
    }

    sql += ' ORDER BY created_at DESC';

    if (limit != null) {
      sql += ' LIMIT ?';
      params.add(limit);
      if (offset != null) {
        sql += ' OFFSET ?';
        params.add(offset);
      }
    }

    return _db.select(sql, params).map(_ceoRequestFromRow).toList();
  }

  CeoRequest? getCeoRequest(String id) {
    final results = _db.select('SELECT * FROM ceo_requests WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _ceoRequestFromRow(results.first);
  }

  void insertCeoRequest(CeoRequest request) {
    _db.execute(
      'INSERT INTO ceo_requests (id, type, message, status, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        request.id, request.type, request.message,
        request.status, request.createdAt.toIso8601String(),
      ],
    );
  }

  void updateCeoRequestStatus(String id, String status) {
    if (status == 'confirmed') {
      _db.execute(
        'UPDATE ceo_requests SET status = ?, confirmed_at = ? WHERE id = ?',
        [status, DateTime.now().toIso8601String(), id],
      );
    } else {
      _db.execute('UPDATE ceo_requests SET status = ? WHERE id = ?', [status, id]);
    }
  }

  // ==================== Products ====================

  List<String> getProducts() {
    return _db
        .select('SELECT name FROM products ORDER BY name')
        .map((row) => row['name'] as String)
        .toList();
  }

  void insertProduct(String name) {
    _db.execute(
      'INSERT INTO products (name, created_at) VALUES (?, ?)',
      [name, DateTime.now().toIso8601String()],
    );
  }

  void deleteProduct(String name) {
    _db.execute('DELETE FROM products WHERE name = ?', [name]);
  }

  /// .env의 PRODUCT_LIST를 DB에 초기 시드 (DB에 아무것도 없을 때만)
  void seedProducts(List<String> products) {
    final existing = getProducts();
    if (existing.isNotEmpty) return;
    for (final name in products) {
      insertProduct(name);
    }
  }

  // ==================== Row mappers ====================

  Team _teamFromRow(Row row) => Team(
        id: row['id'] as String,
        name: row['name'] as String,
        registrationCode: row['registration_code'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  Visit _visitFromRow(Row row) => Visit(
        id: row['id'] as String,
        teamId: row['team_id'] as String,
        visitorName: row['visitor_name'] as String,
        visitorCompany: row['visitor_company'] as String,
        purpose: row['purpose'] as String,
        status: row['status'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  CeoRequest _ceoRequestFromRow(Row row) => CeoRequest(
        id: row['id'] as String,
        type: row['type'] as String,
        message: row['message'] as String?,
        status: row['status'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        confirmedAt: row['confirmed_at'] != null
            ? DateTime.parse(row['confirmed_at'] as String)
            : null,
      );

  AsTicket _asTicketFromRow(Row row) => AsTicket(
        id: row['id'] as String,
        customerName: row['customer_name'] as String,
        contactNumber: row['contact_number'] as String,
        productName: row['product_name'] as String,
        symptom: row['symptom'] as String,
        status: row['status'] as String,
        privacyAgreed: (row['privacy_agreed'] as int) == 1,
        privacyAgreedAt: row['privacy_agreed_at'] != null
            ? DateTime.parse(row['privacy_agreed_at'] as String)
            : null,
        createdAt: DateTime.parse(row['created_at'] as String),
        completedAt: row['completed_at'] != null
            ? DateTime.parse(row['completed_at'] as String)
            : null,
      );
}
