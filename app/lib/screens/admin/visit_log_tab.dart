import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/visit.dart';
import '../../widgets/visit_card.dart';

class VisitLogTab extends StatefulWidget {
  final ApiService api;
  final Stream<Map<String, dynamic>> wsStream;

  const VisitLogTab({super.key, required this.api, required this.wsStream});

  @override
  State<VisitLogTab> createState() => _VisitLogTabState();
}

class _VisitLogTabState extends State<VisitLogTab> {
  List<Visit> _visits = [];
  String? _statusFilter;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = widget.wsStream.listen((msg) {
      final type = msg['type'];
      if (type == 'visit' || type == 'visit_update') _load();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.getVisits(status: _statusFilter);
      setState(() {
        _visits = data.map((j) => Visit.fromJson(j as Map<String, dynamic>)).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _filterChip('전체', null),
              const SizedBox(width: 8),
              _filterChip('대기', 'pending'),
              const SizedBox(width: 8),
              _filterChip('확인', 'confirmed'),
              const SizedBox(width: 8),
              _filterChip('완료', 'done'),
            ],
          ),
        ),
        Expanded(
          child: _visits.isEmpty
              ? const Center(child: Text('기록이 없습니다'))
              : ListView.builder(
                  itemCount: _visits.length,
                  itemBuilder: (ctx, i) => VisitCard(visit: _visits[i]),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? status) {
    final selected = _statusFilter == status;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 16)),
      selected: selected,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onSelected: (_) {
        setState(() => _statusFilter = status);
        _load();
      },
    );
  }
}
