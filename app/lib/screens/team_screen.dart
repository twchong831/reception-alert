import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/api_service.dart';
import '../core/storage.dart';
import '../core/ws_service.dart';
import '../models/visit.dart';
import '../widgets/alarm_overlay.dart';
import '../widgets/visit_card.dart';

class TeamScreen extends StatefulWidget {
  final String serverIp;
  final String teamId;
  final String teamName;

  const TeamScreen({
    super.key,
    required this.serverIp,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late final ApiService _api;
  late final WsService _ws;
  StreamSubscription? _wsSub;

  List<Visit> _visits = [];
  final List<Map<String, dynamic>> _alarmQueue = [];
  bool _alarmShowing = false;
  String _alarmSound = 'alarm.wav';

  @override
  void initState() {
    super.initState();
    _loadAlarmSound();
    _api = ApiService(widget.serverIp);
    _ws = WsService();

    _ws.connect(widget.serverIp, teamId: widget.teamId);
    _wsSub = _ws.stream.listen(_onWsMessage);

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final visitData = await _api.getVisits();
      final visits = visitData
          .map((j) => Visit.fromJson(j as Map<String, dynamic>))
          .where((v) => v.teamId == widget.teamId && v.status != 'done')
          .toList();

      setState(() => _visits = visits);
    } catch (_) {}
  }

  void _onWsMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final data = message['data'] as Map<String, dynamic>?;
    if (data == null) return;

    switch (type) {
      case 'visit':
        final visit = Visit.fromJson(data);
        setState(() {
          _visits.insert(0, visit);
          _alarmQueue.add({
            'title': '방문 알림',
            'visitorName': visit.visitorName,
            'visitorCompany': visit.visitorCompany,
            'purpose': visit.purpose,
            'id': visit.id,
          });
          if (!_alarmShowing) _alarmShowing = true;
        });
        break;
      case 'visit_update':
        final visit = Visit.fromJson(data);
        setState(() {
          _visits.removeWhere((v) => v.id == visit.id);
          if (visit.status != 'done') _visits.insert(0, visit);
        });
        break;
    }
  }

  Future<void> _loadAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _alarmSound = AppStorage(prefs).alarmSound);
  }

  void _showAlarmSoundPicker() {
    final previewPlayer = AudioPlayer();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('알람음 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppStorage.alarmSounds.entries.map((e) => ListTile(
            title: Text(e.value),
            leading: Radio<String>(
              value: e.key,
              groupValue: _alarmSound,
              onChanged: (v) async {
                previewPlayer.stop();
                await previewPlayer.play(AssetSource('sounds/${e.key}'));
                final prefs = await SharedPreferences.getInstance();
                await AppStorage(prefs).setAlarmSound(e.key);
                setState(() => _alarmSound = e.key);
                if (ctx.mounted) (ctx as Element).markNeedsBuild();
              },
            ),
            onTap: () async {
              previewPlayer.stop();
              await previewPlayer.play(AssetSource('sounds/${e.key}'));
              final prefs = await SharedPreferences.getInstance();
              await AppStorage(prefs).setAlarmSound(e.key);
              setState(() => _alarmSound = e.key);
              if (ctx.mounted) (ctx as Element).markNeedsBuild();
            },
          )).toList(),
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
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('${widget.teamName} 알림'),
            actions: [
              IconButton(
                icon: const Icon(Icons.music_note),
                tooltip: '알람음 설정',
                onPressed: _showAlarmSoundPicker,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
          body: _visits.isEmpty
              ? const Center(
                  child: Text(
                    '대기 중인 방문이 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _visits.length,
                  itemBuilder: (ctx, i) {
                    final visit = _visits[i];
                    return VisitCard(
                      visit: visit,
                      onConfirm: () async {
                        await _api.updateVisitStatus(visit.id, 'confirmed');
                        _loadData();
                      },
                      onDone: () async {
                        await _api.updateVisitStatus(visit.id, 'done');
                        _loadData();
                      },
                    );
                  },
                ),
        ),
        if (_alarmShowing && _alarmQueue.isNotEmpty)
          AlarmOverlay(
            title: _alarmQueue.first['title'] as String,
            visitorName: _alarmQueue.first['visitorName'] as String,
            visitorCompany: _alarmQueue.first['visitorCompany'] as String,
            purpose: _alarmQueue.first['purpose'] as String,
            alarmSound: _alarmSound,
            onConfirm: () async {
              final alarm = _alarmQueue.first;
              setState(() {
                _alarmQueue.removeAt(0);
                if (_alarmQueue.isEmpty) _alarmShowing = false;
              });
              await _api.updateVisitStatus(alarm['id'] as String, 'confirmed');
              _loadData();
            },
          ),
      ],
    );
  }
}
