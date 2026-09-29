import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/features/audit/presentation/widgets/audit_timeline.dart';

class ShiftAuditLogsTab extends StatelessWidget {
  final String? shiftId;

  const ShiftAuditLogsTab({super.key, this.shiftId});

  @override
  Widget build(BuildContext context) {
    if (shiftId == null || shiftId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: AuditTimeline(
        entityType: 'shift',
        entityId: shiftId!,
      ),
    );
  }
}
