import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';

class PayoutStatusBadge extends StatelessWidget {
  final String status;

  const PayoutStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'pending':
        return StatusBadge.warning('PENDING');
      case 'approved':
        return StatusBadge.info('APPROVED');
      case 'processing':
        return const StatusBadge(text: 'PROCESSING', color: Colors.purpleAccent);
      case 'paid':
        return StatusBadge.success('PAID');
      case 'failed':
        return StatusBadge.danger('FAILED');
      case 'cancelled':
        return const StatusBadge(text: 'CANCELLED', color: Colors.grey);
      case 'reversed':
        return const StatusBadge(text: 'REVERSED', color: Colors.deepOrange);
      case 'needs_review':
        return const StatusBadge(text: 'NEEDS REVIEW', color: Colors.redAccent);
      default:
        return StatusBadge(text: status.toUpperCase(), color: Colors.white);
    }
  }
}
