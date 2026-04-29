import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _keyRole = 'role';
  static const _keyServerIp = 'server_ip';
  static const _keyTeamId = 'team_id';
  static const _keyTeamName = 'team_name';
  static const _keyAlarmSound = 'alarm_sound';

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

  // 알람음: alarm.wav, alarm2.wav, alarm3.wav, alarm4.wav, alarm5.wav
  String get alarmSound => _prefs.getString(_keyAlarmSound) ?? 'alarm.wav';
  Future<void> setAlarmSound(String sound) => _prefs.setString(_keyAlarmSound, sound);

  static const alarmSounds = {
    'alarm.wav': '기본 알림',
    'alarm2.wav': '띵동',
    'alarm3.wav': '비프음',
    'alarm4.wav': '차임벨',
    'alarm5.wav': '긴급 알림',
  };

  Future<void> clear() => _prefs.clear();
}
