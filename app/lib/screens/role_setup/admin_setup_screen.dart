import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage.dart';
import '../../core/api_service.dart';
import '../admin/admin_screen.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _ipController = TextEditingController();
  final _pwController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    final ip = _ipController.text.trim();
    final pw = _pwController.text.trim();
    if (ip.isEmpty || pw.isEmpty) return;

    setState(() => _loading = true);
    try {
      final api = ApiService(ip);
      final success = await api.authAdmin(pw);
      if (!success) throw Exception('비밀번호가 올바르지 않습니다');

      final prefs = await SharedPreferences.getInstance();
      final storage = AppStorage(prefs);
      await storage.setRole('admin');
      await storage.setServerIp(ip);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AdminScreen(serverIp: ip)),
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
      appBar: AppBar(title: const Text('관리자 로그인')),
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
                  controller: _pwController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '관리자 비밀번호',
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('로그인', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
