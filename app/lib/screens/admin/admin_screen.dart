import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/ws_service.dart';
import 'team_manage_tab.dart';
import 'visit_log_tab.dart';
import 'as_log_tab.dart';

class AdminScreen extends StatefulWidget {
  final String serverIp;

  const AdminScreen({super.key, required this.serverIp});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final ApiService _api;
  late final WsService _ws;

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.serverIp);
    _ws = WsService();
    _ws.connect(widget.serverIp, admin: true);
  }

  @override
  void dispose() {
    _ws.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('관리자'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group), text: '팀 관리'),
              Tab(icon: Icon(Icons.people), text: '방문 기록'),
              Tab(icon: Icon(Icons.build), text: 'AS 현황'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TeamManageTab(api: _api, wsStream: _ws.stream),
            VisitLogTab(api: _api, wsStream: _ws.stream),
            AsLogTab(api: _api, wsStream: _ws.stream),
          ],
        ),
      ),
    );
  }
}
