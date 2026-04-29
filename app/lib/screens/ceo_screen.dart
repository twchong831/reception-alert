import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/ws_service.dart';
import '../models/ceo_request.dart';

class CeoScreen extends StatefulWidget {
  final String serverIp;

  const CeoScreen({super.key, required this.serverIp});

  @override
  State<CeoScreen> createState() => _CeoScreenState();
}

class _CeoScreenState extends State<CeoScreen> {
  late final ApiService _api;
  late final WsService _ws;
  StreamSubscription? _wsSub;

  List<CeoRequest> _recentRequests = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.serverIp);
    _ws = WsService();
    _ws.connectCeo(widget.serverIp);
    _wsSub = _ws.stream.listen(_onWsMessage);
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    try {
      final data = await _api.getCeoRequests();
      setState(() {
        _recentRequests = data
            .map((j) => CeoRequest.fromJson(j as Map<String, dynamic>))
            .take(2)
            .toList();
      });
    } catch (_) {}
  }

  void _onWsMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    if (type == 'ceo_request_update') {
      _loadRecent();
    }
  }

  Future<void> _sendRequest(String type) async {
    if (_sending) return;

    String? message;
    if (type == 'coffee') {
      message = await _showDrinkDialog();
      if (message == null) return; // 취소
    }

    setState(() => _sending = true);
    try {
      await _api.createCeoRequest(type: type, message: message);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(type == 'coffee' ? '음료 요청을 보냈습니다' : '호출을 보냈습니다'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRecent();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요청 실패: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<String?> _showDrinkDialog() async {
    int coffeeCount = 1;
    int waterCount = 0;
    int teaCount = 0;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Widget counterRow(String label, int count, ValueChanged<int> onChanged) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontSize: 18)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: count > 0
                            ? () => onChanged(count - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onChanged(count + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final total = coffeeCount + waterCount + teaCount;

          return AlertDialog(
            title: const Text('음료 요청'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  counterRow('커피', coffeeCount, (v) {
                    setDialogState(() => coffeeCount = v);
                  }),
                  const Divider(),
                  counterRow('물', waterCount, (v) {
                    setDialogState(() => waterCount = v);
                  }),
                  counterRow('차', teaCount, (v) {
                    setDialogState(() => teaCount = v);
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: total > 0
                    ? () {
                        final parts = <String>[];
                        if (coffeeCount > 0) parts.add('커피 ${coffeeCount}잔');
                        if (waterCount > 0) parts.add('물 ${waterCount}잔');
                        if (teaCount > 0) parts.add('차 ${teaCount}잔');
                        Navigator.pop(ctx, parts.join(', '));
                      }
                    : null,
                child: const Text('요청'),
              ),
            ],
          );
        },
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              _currentTime(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRequestButton(
                  icon: Icons.coffee,
                  label: '커피 요청',
                  color: const Color(0xFF8B4513),
                  onTap: () => _sendRequest('coffee'),
                ),
                const SizedBox(width: 48),
                _buildRequestButton(
                  icon: Icons.call,
                  label: '호출',
                  color: const Color(0xFF1565C0),
                  onTap: () => _sendRequest('call'),
                ),
              ],
            ),
            const Spacer(),
            if (_recentRequests.isNotEmpty) _buildRecentList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _currentTime() {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRequestButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _sending ? null : onTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: _sending ? color.withValues(alpha: 0.5) : color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 요청',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ..._recentRequests.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      r.type == 'coffee' ? Icons.coffee : Icons.call,
                      size: 20,
                      color: r.type == 'coffee'
                          ? const Color(0xFF8B4513)
                          : const Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 8),
                    Text(r.typeLabel, style: const TextStyle(fontSize: 14)),
                    if (r.message != null && r.message!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.message!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    _statusChip(r.status),
                    const SizedBox(width: 8),
                    Text(
                      '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        label = '확인';
        break;
      case 'done':
        color = Colors.grey;
        label = '완료';
        break;
      default:
        color = Colors.orange;
        label = '대기';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
