import 'package:flutter/material.dart';
import '../models/visit.dart';

class VisitCard extends StatelessWidget {
  final Visit visit;
  final VoidCallback? onConfirm;
  final VoidCallback? onDone;

  const VisitCard({
    super.key,
    required this.visit,
    this.onConfirm,
    this.onDone,
  });

  Color get _statusColor {
    switch (visit.status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (visit.status) {
      case 'pending':
        return '대기중';
      case 'confirmed':
        return '확인됨';
      case 'done':
        return '완료';
      default:
        return visit.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        visit.visitorName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(color: _statusColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${visit.visitorCompany} | ${visit.purpose}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            if (visit.status == 'pending' && onConfirm != null)
              ElevatedButton(onPressed: onConfirm, child: const Text('확인')),
            if (visit.status == 'confirmed' && onDone != null) ...[
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onDone, child: const Text('완료')),
            ],
          ],
        ),
      ),
    );
  }
}
