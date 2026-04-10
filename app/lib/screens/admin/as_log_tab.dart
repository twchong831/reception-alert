import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/as_ticket.dart';
import '../../widgets/as_card.dart';

class AsLogTab extends StatefulWidget {
  final ApiService api;
  final Stream<Map<String, dynamic>> wsStream;

  const AsLogTab({super.key, required this.api, required this.wsStream});

  @override
  State<AsLogTab> createState() => _AsLogTabState();
}

class _AsLogTabState extends State<AsLogTab> {
  List<AsTicket> _tickets = [];
  String? _statusFilter;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = widget.wsStream.listen((msg) {
      final type = msg['type'];
      if (type == 'as_ticket' || type == 'as_update') _load();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.getAsTickets(status: _statusFilter);
      setState(() {
        _tickets = data.map((j) => AsTicket.fromJson(j as Map<String, dynamic>)).toList();
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
              _filterChip('접수', 'received'),
              const SizedBox(width: 8),
              _filterChip('처리중', 'in_progress'),
              const SizedBox(width: 8),
              _filterChip('완료', 'done'),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _purgeExpired,
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('만료 데이터 파기'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),
        Expanded(
          child: _tickets.isEmpty
              ? const Center(child: Text('AS 접수 내역이 없습니다'))
              : ListView.builder(
                  itemCount: _tickets.length,
                  itemBuilder: (ctx, i) {
                    final ticket = _tickets[i];
                    return AsCard(
                      ticket: ticket,
                      onProgress: () async {
                        await widget.api.updateAsStatus(ticket.id, 'in_progress');
                        _load();
                      },
                      onDone: () async {
                        await widget.api.updateAsStatus(ticket.id, 'done');
                        _load();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _purgeExpired() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('개인정보 파기'),
        content: const Text(
          'AS 처리 완료 후 1년이 경과한 개인정보(회사명, 연락처)를 '
          '익명화 처리합니다.\n\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('파기 실행'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final count = await widget.api.purgeExpiredData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count건의 개인정보가 파기되었습니다')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파기 실패: $e')),
      );
    }
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
