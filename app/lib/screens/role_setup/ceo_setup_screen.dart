import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage.dart';
import '../ceo_screen.dart';

class CeoSetupScreen extends StatefulWidget {
  const CeoSetupScreen({super.key});

  @override
  State<CeoSetupScreen> createState() => _CeoSetupScreenState();
}

class _CeoSetupScreenState extends State<CeoSetupScreen> {
  final _ipController = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = AppStorage(prefs);
      await storage.setRole('ceo');
      await storage.setServerIp(ip);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => CeoScreen(serverIp: ip)),
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
      appBar: AppBar(title: const Text('대표이사 태블릿 설정')),
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
