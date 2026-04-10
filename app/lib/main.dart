import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage.dart';
import 'screens/role_setup/role_select_screen.dart';
import 'screens/reception_screen.dart';
import 'screens/team_screen.dart';
import 'screens/as_screen.dart';
import 'screens/admin/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 태블릿 가로/세로 모두 허용
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // 전체화면 (상태바/네비게이션바 숨김)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await SharedPreferences.getInstance();
  final storage = AppStorage(prefs);

  runApp(VisitorApp(storage: storage));
}

class VisitorApp extends StatelessWidget {
  final AppStorage storage;

  const VisitorApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '방문 알림 시스템',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final role = storage.role;
    final serverIp = storage.serverIp;

    if (role == null || serverIp == null) {
      return const RoleSelectScreen();
    }

    switch (role) {
      case 'reception':
        return ReceptionScreen(serverIp: serverIp);
      case 'team':
        final teamId = storage.teamId;
        final teamName = storage.teamName;
        if (teamId == null || teamName == null) {
          return const RoleSelectScreen();
        }
        return TeamScreen(
          serverIp: serverIp,
          teamId: teamId,
          teamName: teamName,
        );
      case 'as':
        return AsScreen(serverIp: serverIp);
      case 'admin':
        return AdminScreen(serverIp: serverIp);
      default:
        return const RoleSelectScreen();
    }
  }
}
