import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage.dart';
import '../reception_screen.dart';

class ReceptionSetupScreen extends StatefulWidget {
  const ReceptionSetupScreen({super.key});

  @override
  State<ReceptionSetupScreen> createState() => _ReceptionSetupScreenState();
}

class _ReceptionSetupScreenState extends State<ReceptionSetupScreen> {
  final _ipController = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = AppStorage(prefs);
      await storage.setRole('reception');
      await storage.setServerIp(ip);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ReceptionScreen(serverIp: ip)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('접수 태블릿 설정')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('서버 IP를 입력해주세요', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('저장', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
