import 'package:flutter/material.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../domain/entities/live_sessions_operations_groups.dart';
import '../../domain/entities/booking.dart';
import 'cashier_session_tile.dart';

class CashierSessionRail extends StatelessWidget {
  final LiveSessionsOperationsGroups groups;
  final String selectedId;
  final ValueChanged<Booking> onSelect;
  final bool isCompact;
  const CashierSessionRail({
    super.key,
    required this.groups,
    required this.selectedId,
    required this.onSelect,
    required this.isCompact,
  });
  @override
  Widget build(BuildContext context) {
    final sections = [
      (AppStrings.needsAttention, groups.needsAttention, AppColors.warning),
      (AppStrings.openTimeSessions, groups.openTime, AppColors.neonCyan),
      (AppStrings.runningSessions, groups.running, AppColors.neonBlue),
      (AppStrings.upcomingSessions, groups.upcoming, AppColors.textSecondary),
    ];
    return ListView(
      shrinkWrap: isCompact,
      physics: isCompact ? const NeverScrollableScrollPhysics() : null,
      children: [
        for (final (title, bookings, color) in sections)
          if (bookings.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 14, 10, 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${bookings.length}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            for (final booking in bookings)
              CashierSessionTile(
                key: ValueKey(booking.id),
                booking: booking,
                selected: selectedId == booking.id,
                onSelect: () => onSelect(booking),
              ),
          ],
      ],
    );
  }
}
