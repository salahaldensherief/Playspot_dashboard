import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../core/responsive/app_breakpoints.dart';
import 'active_session_stat_tile.dart';

class ActiveSessionsStatsBar extends StatelessWidget {
  final int activeCount;
  final double totalRevenue;
  final int extrasCount;

  const ActiveSessionsStatsBar({
    super.key,
    required this.activeCount,
    required this.totalRevenue,
    required this.extrasCount,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tiles = <Widget>[
            ActiveSessionStatTile(
              title: AppStrings.activeSessions,
              value: '$activeCount',
              icon: Icons.sports_esports,
              color: AppColors.neonBlue,
            ),
            ActiveSessionStatTile(
              title: AppStrings.activeSessionRevenue,
              value: '${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
              icon: Icons.account_balance_wallet,
              color: AppColors.neonGreen,
            ),
            ActiveSessionStatTile(
              title: AppStrings.totalActiveExtras,
              value: '$extrasCount',
              icon: Icons.restaurant,
              color: AppColors.neonCyan,
            ),
          ];
          if (AppBreakpoints.isMobileWidth(constraints.maxWidth)) {
            return Column(
              children: [
                for (var index = 0; index < tiles.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  tiles[index],
                ],
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                if (index > 0) const SizedBox(width: 16),
                Expanded(child: tiles[index]),
              ],
            ],
          );
        },
      ),
    );
  }
}
