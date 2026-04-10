import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _keyRole = 'role';
  static const _keyServerIp = 'server_ip';
  static const _keyTeamId = 'team_id';
  static const _keyTeamName = 'team_name';

  final SharedPreferences _prefs;

  AppStorage(this._prefs);

  // Role: reception, team, admin
  String? get role => _prefs.getString(_keyRole);
  Future<void> setRole(String role) => _prefs.setString(_keyRole, role);

  String? get serverIp => _prefs.getString(_keyServerIp);
  Future<void> setServerIp(String ip) => _prefs.setString(_keyServerIp, ip);

  String? get teamId => _prefs.getString(_keyTeamId);
  Future<void> setTeamId(String id) => _prefs.setString(_keyTeamId, id);

  String? get teamName => _prefs.getString(_keyTeamName);
  Future<void> setTeamName(String name) => _prefs.setString(_keyTeamName, name);

  Future<void> clear() => _prefs.clear();
}
