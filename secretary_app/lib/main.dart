import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  launchAtStartup.setup(
    appName: '비서 알림',
    appPath: Platform.resolvedExecutable,
  );

  const windowOptions = WindowOptions(
    size: Size(420, 340),
    center: true,
    title: '비서 알림',
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const SecretaryApp());
}

class SecretaryApp extends StatelessWidget {
  const SecretaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '비서 알림',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SecretaryHome(),
    );
  }
}

class SecretaryHome extends StatefulWidget {
  const SecretaryHome({super.key});

  @override
  State<SecretaryHome> createState() => _SecretaryHomeState();
}

class _SecretaryHomeState extends State<SecretaryHome> with WindowListener {
  final _ipController = TextEditingController(text: '192.168.1.21');
  final SystemTray _systemTray = SystemTray();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  String? _serverIp;
  bool _connected = false;

  // 알림 큐
  final List<Map<String, dynamic>> _alarmQueue = [];
  bool _alarmShowing = false;
  String _alarmSound = 'alarm.wav';
  bool _autoStart = false;

  static const _alarmSounds = {
    'alarm.wav': '기본 알림',
    'alarm2.wav': '띵동',
    'alarm3.wav': '비프음',
    'alarm4.wav': '차임벨',
    'alarm5.wav': '긴급 알림',
  };

  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    _initSystemTray();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    final savedAlarm = prefs.getString('alarm_sound');
    _autoStart = await launchAtStartup.isEnabled();
    if (savedAlarm != null) _alarmSound = savedAlarm;
    if (savedIp != null) {
      _ipController.text = savedIp;
      _serverIp = savedIp;
      setState(() {});
      _doConnect();
    } else {
      setState(() {});
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_serverIp != null) await prefs.setString('server_ip', _serverIp!);
    await prefs.setString('alarm_sound', _alarmSound);
  }

  bool _trayInitialized = false;

  Future<void> _initSystemTray() async {
    try {
      // exe 옆에 tray_icon.ico 복사 (없으면 assets에서 복사)
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final trayIconPath = p.join(exeDir, 'tray_icon.ico');
      if (!File(trayIconPath).existsSync()) {
        final candidates = [
          p.join(exeDir, 'data', 'flutter_assets', 'assets', 'icon', 'app_icon.ico'),
          p.join(Directory.current.path, 'windows', 'runner', 'resources', 'app_icon.ico'),
        ];
        for (final src in candidates) {
          if (File(src).existsSync()) {
            File(src).copySync(trayIconPath);
            break;
          }
        }
      }

      if (!File(trayIconPath).existsSync()) {
        print('System tray: 아이콘 파일을 찾을 수 없음, 트레이 비활성화');
        return;
      }

      await _systemTray.initSystemTray(
        title: '비서 알림',
        iconPath: trayIconPath,
      );

      final menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(label: '열기', onClicked: (_) => _showWindow()),
        MenuSeparator(),
        MenuItemLabel(label: '종료', onClicked: (_) => _quit()),
      ]);
      await _systemTray.setContextMenu(menu);

      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          _showWindow();
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });

      _trayInitialized = true;
    } catch (e) {
      print('System tray 초기화 실패 (디버그 모드에서는 정상): $e');
    }
  }

  void _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  void _quit() async {
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    if (_trayInitialized) await _systemTray.destroy();
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    // 닫기 버튼 클릭 시 트레이로 최소화
    await windowManager.hide();
  }

  void _connect() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _serverIp = ip);
    _saveSettings();
    _doConnect();
  }

  void _doConnect() {
    if (_serverIp == null) return;

    try {
      _channel?.sink.close();
    } catch (_) {}

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$_serverIp:8803/ws/secretary'),
      );
      setState(() => _connected = true);

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            _onMessage(message);
          } catch (_) {}
        },
        onDone: () {
          if (mounted) setState(() => _connected = false);
          _scheduleReconnect();
        },
        onError: (_) {
          if (mounted) setState(() => _connected = false);
          _scheduleReconnect();
        },
      );
    } catch (_) {
      setState(() => _connected = false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _doConnect);
  }

  void _onMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final data = message['data'] as Map<String, dynamic>?;

    if (type == 'ceo_request' && data != null) {
      final reqType = data['type'] as String? ?? '';
      final reqMessage = data['message'] as String?;
      final reqId = data['id'] as String? ?? '';

      setState(() {
        _alarmQueue.add({
          'id': reqId,
          'type': reqType,
          'message': reqMessage,
        });
        if (!_alarmShowing) {
          _alarmShowing = true;
          _showAlarmPopup();
        }
      });
    } else if (type == 'ceo_request_update' && data != null) {
      final reqId = data['id'] as String? ?? '';
      final status = data['status'] as String? ?? '';
      if (status == 'confirmed' || status == 'done') {
        final removed = _alarmQueue.where((a) => a['id'] == reqId).isNotEmpty;
        setState(() {
          _alarmQueue.removeWhere((a) => a['id'] == reqId);
          if (_alarmQueue.isEmpty && _alarmShowing) {
            _alarmShowing = false;
          }
        });
        if (removed && _alarmQueue.isEmpty) {
          _player.stop();
          windowManager.setAlwaysOnTop(false);
          windowManager.hide();
        }
      }
    }
  }

  Future<void> _showAlarmPopup() async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setAlwaysOnTop(true);

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/$_alarmSound'));
  }

  void _confirmAlarm() async {
    await _player.stop();

    if (_alarmQueue.isNotEmpty) {
      final alarm = _alarmQueue.removeAt(0);
      _sendStatusUpdate(alarm['id'] as String, 'confirmed');
    }

    if (_alarmQueue.isEmpty) {
      setState(() => _alarmShowing = false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.hide();
    } else {
      setState(() {});
      await _player.play(AssetSource('sounds/$_alarmSound'));
    }
  }

  void _showAlarmSoundPicker() {
    final previewPlayer = AudioPlayer();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('알람음 선택'),
          content: SizedBox(
            width: 250,
            height: 250,
            child: ListView(
              shrinkWrap: true,
              children: _alarmSounds.entries.map((e) => ListTile(
                dense: true,
                title: Text(e.value),
                trailing: _alarmSound == e.key
                    ? const Icon(Icons.check, color: Colors.indigo)
                    : null,
                onTap: () async {
                  previewPlayer.stop();
                  await previewPlayer.play(AssetSource('sounds/${e.key}'));
                  setState(() => _alarmSound = e.key);
                  _saveSettings();
                  setDialogState(() {});
                },
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                previewPlayer.stop();
                previewPlayer.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendStatusUpdate(String id, String status) {
    if (_serverIp == null) return;
    try {
      final uri = Uri.parse('http://$_serverIp:8803/api/ceo/requests/$id');
      HttpClient().patchUrl(uri).then((request) {
        request.headers.set('Content-Type', 'application/json');
        request.write(jsonEncode({'status': status}));
        return request.close();
      }).then((response) {
        response.drain();
      }).catchError((_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_alarmShowing && _alarmQueue.isNotEmpty) {
      return _buildAlarmView();
    }

    if (_serverIp != null) {
      return _buildConnectedView();
    }

    return _buildSetupView();
  }

  Widget _buildSetupView() {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications, size: 48, color: Colors.indigo),
              const SizedBox(height: 12),
              const Text(
                '비서 알림 시스템',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '대표이사 요청을 실시간으로 수신합니다',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    hintText: '예: 192.168.0.100',
                    border: OutlineInputBorder(),
                    labelText: '서버 IP',
                    prefixIcon: Icon(Icons.dns),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _connect,
                  icon: const Icon(Icons.link),
                  label: const Text('연결', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedView() {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _connected ? Icons.check_circle : Icons.sync,
                size: 48,
                color: _connected ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 12),
              Text(
                _connected ? '서버 연결됨' : '재연결 중...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _connected ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _serverIp ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                '대표이사 요청 대기 중\n창을 닫으면 트레이로 최소화됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.power_settings_new, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('자동 시작', style: TextStyle(fontSize: 13)),
                  Switch(
                    value: _autoStart,
                    onChanged: (v) async {
                      if (v) {
                        await launchAtStartup.enable();
                      } else {
                        await launchAtStartup.disable();
                      }
                      setState(() => _autoStart = v);
                    },
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showAlarmSoundPicker,
                icon: const Icon(Icons.music_note, size: 18),
                label: Text('알람음: ${_alarmSounds[_alarmSound] ?? _alarmSound}', style: const TextStyle(fontSize: 13)),
              ),
              TextButton.icon(
                onPressed: () async {
                  _channel?.sink.close();
                  _reconnectTimer?.cancel();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('server_ip');
                  setState(() {
                    _serverIp = null;
                    _connected = false;
                  });
                },
                icon: const Icon(Icons.link_off, size: 18),
                label: const Text('연결 해제', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmView() {
    final alarm = _alarmQueue.first;
    final reqType = alarm['type'] as String;
    final reqMessage = alarm['message'] as String?;
    final isCoffee = reqType == 'coffee';

    // 메시지에 물/차가 포함되어 있으면 아이콘과 타이틀 조정
    IconData icon;
    String title;
    if (!isCoffee) {
      icon = Icons.call;
      title = '호출';
    } else if (reqMessage != null && !reqMessage.contains('커피')) {
      icon = Icons.local_drink;
      title = '음료 요청';
    } else {
      icon = Icons.coffee;
      title = '음료 요청';
    }

    return Scaffold(
      backgroundColor:
          isCoffee ? const Color(0xFF8B4513) : const Color(0xFF1565C0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (reqMessage != null && reqMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reqMessage,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
            if (_alarmQueue.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '외 ${_alarmQueue.length - 1}건 대기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            SizedBox(
              width: 180,
              height: 52,
              child: ElevatedButton(
                onPressed: _confirmAlarm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isCoffee
                      ? const Color(0xFF8B4513)
                      : const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('확인', style: TextStyle(fontSize: 22)),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
