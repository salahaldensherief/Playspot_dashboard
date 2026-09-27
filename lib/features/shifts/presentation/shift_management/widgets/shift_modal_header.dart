import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../../domain/entities/shift_entity.dart';

class ShiftModalHeader extends StatelessWidget {
  final ShiftEntity shift;

  const ShiftModalHeader({
    super.key,
    required this.shift,
  });

  @override
  Widget build(BuildContext context) {
    final formattedStart = DateFormat('yyyy-MM-dd hh:mm a').format(shift.startTime);
    final formattedEnd = shift.endTime != null
        ? DateFormat('yyyy-MM-dd hh:mm a').format(shift.endTime!)
        : AppStrings.currentShiftOngoing;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.neonBlue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.query_stats_rounded, color: AppColors.neonBlue, size: 24.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppText.heading(AppStrings.shiftDetailsTitle(shift.id), fontSize: 18.sp),
                  SizedBox(width: 12.w),
                  shift.status == 'open'
                      ? StatusBadge.info(AppStrings.open)
                      : shift.isApproved
                          ? StatusBadge.success(AppStrings.approved)
                          : StatusBadge.warning(AppStrings.pendingApproval),
                ],
              ),
              SizedBox(height: 4.h),
              AppText.body(
                AppStrings.shiftFromTo(shift.cashierName ?? AppStrings.system, formattedStart, formattedEnd),
                color: AppColors.textSecondary,
                fontSize: 12.sp,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
