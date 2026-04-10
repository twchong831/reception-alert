import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage.dart';
import '../../core/api_service.dart';
import '../team_screen.dart';

class TeamRegisterScreen extends StatefulWidget {
  const TeamRegisterScreen({super.key});

  @override
  State<TeamRegisterScreen> createState() => _TeamRegisterScreenState();
}

class _TeamRegisterScreenState extends State<TeamRegisterScreen> {
  final _ipController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    final ip = _ipController.text.trim();
    final code = _codeController.text.trim();
    if (ip.isEmpty || code.isEmpty) return;

    setState(() => _loading = true);
    try {
      final api = ApiService(ip);
      final result = await api.authTeam(code);

      final prefs = await SharedPreferences.getInstance();
      final storage = AppStorage(prefs);
      await storage.setRole('team');
      await storage.setServerIp(ip);
      await storage.setTeamId(result['teamId'] as String);
      await storage.setTeamName(result['teamName'] as String);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => TeamScreen(
            serverIp: ip,
            teamId: result['teamId'] as String,
            teamName: result['teamName'] as String,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 실패: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀 알림 태블릿 등록')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    hintText: '예: 192.168.0.100',
                    border: OutlineInputBorder(),
                    labelText: '서버 IP',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    hintText: '예: KM-4829',
                    border: OutlineInputBorder(),
                    labelText: '등록코드',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('인증', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
