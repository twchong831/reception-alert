import 'package:flutter/material.dart';
import 'reception_setup_screen.dart';
import 'team_register_screen.dart';
import 'as_setup_screen.dart';
import 'admin_setup_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '역할을 선택해주세요',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              _RoleButton(
                icon: Icons.desk,
                label: '접수 태블릿',
                subtitle: '1층 로비 방문객 접수용',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceptionSetupScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                icon: Icons.notifications_active,
                label: '팀 알림 태블릿',
                subtitle: '방문 알림 수신용',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeamRegisterScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                icon: Icons.build_circle,
                label: 'AS 접수 태블릿',
                subtitle: 'AS 접수 알림 수신 및 처리용',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AsSetupScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                icon: Icons.admin_panel_settings,
                label: '관리자 태블릿',
                subtitle: '팀 관리 및 기록 조회용',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSetupScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
