import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/team.dart';

class ReceptionScreen extends StatefulWidget {
  final String serverIp;

  const ReceptionScreen({super.key, required this.serverIp});

  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends State<ReceptionScreen> {
  late final ApiService _api;
  List<Team> _teams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.serverIp);
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final data = await _api.getTeams();
      setState(() {
        _teams = data.map((j) => Team.fromJson(j as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('팀 목록 로드 실패: $e')),
      );
    }
  }

  void _showVisitDialog(Team team) {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${team.name} 방문'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '방문자 성함'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: companyCtrl,
              decoration: const InputDecoration(labelText: '소속 회사'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: purposeCtrl,
              decoration: const InputDecoration(labelText: '방문 목적'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _api.createVisit(
                  teamId: team.id,
                  visitorName: nameCtrl.text.trim(),
                  visitorCompany: companyCtrl.text.trim(),
                  purpose: purposeCtrl.text.trim(),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('방문 알림이 전송되었습니다')),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('전송 실패: $e')),
                );
              }
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }

  void _showAsDialog() async {
    // 서버에서 제품 목록 가져오기
    List<String> products = [];
    try {
      products = await _api.getProducts();
    } catch (_) {}

    if (!mounted) return;

    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final symptomCtrl = TextEditingController();
    String? selectedProduct;
    bool privacyAgreed = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('AS 접수'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '성함'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(labelText: '연락처'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '제품명'),
                  initialValue: selectedProduct,
                  items: products
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedProduct = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: symptomCtrl,
                  decoration: const InputDecoration(labelText: '증상'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    '[개인정보 수집·이용 동의]\n\n'
                    '1. 수집 항목: 성함, 연락처\n'
                    '2. 수집 목적: AS 접수 처리 및 진행 상황 안내\n'
                    '3. 보관 기간: AS 처리 완료 후 1년\n'
                    '4. 동의를 거부할 수 있으며, 거부 시 AS 접수가 '
                    '제한됩니다.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: privacyAgreed,
                      onChanged: (v) =>
                          setDialogState(() => privacyAgreed = v ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        '개인정보 수집·이용에 동의합니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: privacyAgreed
                  ? () async {
                      try {
                        await _api.createAsTicket(
                          customerName: nameCtrl.text.trim(),
                          contactNumber: contactCtrl.text.trim(),
                          productName: selectedProduct ?? '',
                          symptom: symptomCtrl.text.trim(),
                          privacyAgreed: true,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AS 접수가 완료되었습니다')),
                        );
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('접수 실패: $e')),
                        );
                      }
                    }
                  : null,
              child: const Text('접수'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('방문 접수'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadTeams();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _teams.length,
                      itemBuilder: (ctx, i) {
                        final team = _teams[i];
                        return ElevatedButton(
                          onPressed: () => _showVisitDialog(team),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            team.name,
                            style: const TextStyle(fontSize: 22),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _showAsDialog,
                      icon: const Icon(Icons.build, size: 28),
                      label: const Text('AS 접수',
                          style: TextStyle(fontSize: 22)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
