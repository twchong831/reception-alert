import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/team.dart';

class TeamManageTab extends StatefulWidget {
  final ApiService api;
  final Stream<Map<String, dynamic>> wsStream;

  const TeamManageTab({super.key, required this.api, required this.wsStream});

  @override
  State<TeamManageTab> createState() => _TeamManageTabState();
}

class _TeamManageTabState extends State<TeamManageTab> {
  List<Team> _teams = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = widget.wsStream.listen((msg) {
      final type = msg['type'];
      if (type == 'team_created' || type == 'team_deleted') _load();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.getTeams();
      setState(() {
        _teams = data.map((j) => Team.fromJson(j as Map<String, dynamic>)).toList();
      });
    } catch (_) {}
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('팀 추가'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: '팀명'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              try {
                final result = await widget.api.createTeam(name);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _load();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('팀 생성 완료 - 등록코드: ${result['registrationCode']}'),
                    duration: const Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('실패: $e')),
                );
              }
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('팀 추가'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _teams.length,
            itemBuilder: (ctx, i) {
              final team = _teams[i];
              return ListTile(
                title: Text(team.name, style: const TextStyle(fontSize: 18)),
                subtitle: Text('등록코드: ${team.registrationCode}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('팀 삭제'),
                        content: Text('${team.name} 팀을 삭제하시겠습니까?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.api.deleteTeam(team.id);
                      _load();
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
