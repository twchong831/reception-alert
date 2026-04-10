import 'package:flutter/material.dart';
import '../models/as_ticket.dart';

class AsCard extends StatelessWidget {
  final AsTicket ticket;
  final VoidCallback? onProgress;
  final VoidCallback? onDone;

  const AsCard({
    super.key,
    required this.ticket,
    this.onProgress,
    this.onDone,
  });

  Color get _statusColor {
    switch (ticket.status) {
      case 'received':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (ticket.status) {
      case 'received':
        return '접수됨';
      case 'in_progress':
        return '처리중';
      case 'done':
        return '완료';
      default:
        return ticket.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  ticket.customerName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('제품: ${ticket.productName}'),
            Text('증상: ${ticket.symptom}'),
            Text('연락처: ${ticket.contactNumber}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ticket.status == 'received' && onProgress != null)
                  ElevatedButton(
                      onPressed: onProgress, child: const Text('처리시작')),
                if (ticket.status == 'in_progress' && onDone != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                      onPressed: onDone, child: const Text('완료')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
