import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/ws_service.dart';
import '../models/as_ticket.dart';
import '../widgets/alarm_overlay.dart';
import '../widgets/as_card.dart';

class AsScreen extends StatefulWidget {
  final String serverIp;

  const AsScreen({super.key, required this.serverIp});

  @override
  State<AsScreen> createState() => _AsScreenState();
}

class _AsScreenState extends State<AsScreen> {
  late final ApiService _api;
  late final WsService _ws;
  StreamSubscription? _wsSub;

  List<AsTicket> _tickets = [];
  String? _statusFilter; // null = 진행중(received+in_progress), 'done' = 완료
  final List<Map<String, dynamic>> _alarmQueue = [];
  bool _alarmShowing = false;

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.serverIp);
    _ws = WsService();

    _ws.connectAs(widget.serverIp);
    _wsSub = _ws.stream.listen(_onWsMessage);

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _api.getAsTickets(status: _statusFilter);
      setState(() {
        _tickets = data
            .map((j) => AsTicket.fromJson(j as Map<String, dynamic>))
            .toList();
        // 진행중 필터일 때는 done 제외
        if (_statusFilter == null) {
          _tickets = _tickets.where((t) => t.status != 'done').toList();
        }
      });
    } catch (_) {}
  }

  void _onWsMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final data = message['data'] as Map<String, dynamic>?;
    if (data == null) return;

    switch (type) {
      case 'as_ticket':
        final ticket = AsTicket.fromJson(data);
        setState(() {
          if (_statusFilter == null) {
            _tickets.insert(0, ticket);
          }
          _alarmQueue.add({
            'title': 'AS 접수 알림',
            'visitorName': ticket.customerName,
            'visitorCompany': ticket.productName,
            'purpose': ticket.symptom,
            'id': ticket.id,
          });
          if (!_alarmShowing) _alarmShowing = true;
        });
        break;
      case 'as_update':
        _loadData();
        break;
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws.dispose();
    super.dispose();
  }

  void _showProductManager() async {
    List<String> products = [];
    try {
      products = await _api.getProducts();
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final addCtrl = TextEditingController();

          Future<void> refresh() async {
            try {
              products = await _api.getProducts();
              setDialogState(() {});
            } catch (_) {}
          }

          return AlertDialog(
            title: const Text('제품 관리'),
            content: SizedBox(
              width: 400,
              height: 400,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addCtrl,
                          decoration: const InputDecoration(
                            hintText: '새 제품명 입력',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final name = addCtrl.text.trim();
                          if (name.isEmpty) return;
                          try {
                            await _api.addProduct(name);
                            addCtrl.clear();
                            await refresh();
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('추가 실패: $e')),
                            );
                          }
                        },
                        child: const Text('추가'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: products.isEmpty
                        ? const Center(child: Text('등록된 제품이 없습니다'))
                        : ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (_, i) => ListTile(
                              title: Text(products[i]),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await _api.deleteProduct(products[i]);
                                  await refresh();
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('AS 접수 현황'),
            actions: [
              IconButton(
                icon: const Icon(Icons.inventory),
                tooltip: '제품 관리',
                onPressed: _showProductManager,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip('진행중', null),
                    _filterChip('접수', 'received'),
                    _filterChip('처리중', 'in_progress'),
                    _filterChip('완료', 'done'),
                  ],
                ),
              ),
              Expanded(
                child: _tickets.isEmpty
                    ? const Center(
                        child: Text(
                          'AS 접수 내역이 없습니다',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tickets.length,
                        itemBuilder: (ctx, i) {
                          final ticket = _tickets[i];
                          return AsCard(
                            ticket: ticket,
                            onProgress: () async {
                              await _api.updateAsStatus(ticket.id, 'in_progress');
                              _loadData();
                            },
                            onDone: () async {
                              await _api.updateAsStatus(ticket.id, 'done');
                              _loadData();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (_alarmShowing && _alarmQueue.isNotEmpty)
          AlarmOverlay(
            title: _alarmQueue.first['title'] as String,
            visitorName: _alarmQueue.first['visitorName'] as String,
            visitorCompany: _alarmQueue.first['visitorCompany'] as String,
            purpose: _alarmQueue.first['purpose'] as String,
            onConfirm: () async {
              final alarm = _alarmQueue.first;
              setState(() {
                _alarmQueue.removeAt(0);
                if (_alarmQueue.isEmpty) _alarmShowing = false;
              });
              await _api.updateAsStatus(alarm['id'] as String, 'in_progress');
              _loadData();
            },
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
        _loadData();
      },
    );
  }
}
