import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class AddBookingSummaryCard extends StatelessWidget {
  final RoomEntity? room;
  final int durationMinutes;
  final double extrasTotal;
  final double voucherDiscount;
  final String playMode;

  const AddBookingSummaryCard({
    super.key,
    required this.room,
    required this.durationMinutes,
    required this.extrasTotal,
    required this.voucherDiscount,
    this.playMode = 'single',
  });

  @override
  Widget build(BuildContext context) {
    if (room == null) return const SizedBox.shrink();

    final double durationHours = durationMinutes / 60.0;
    final double pricePerHour = playMode == 'multi'
        ? (room!.hourlyRateMulti > 0 ? room!.hourlyRateMulti : room!.pricePerHour)
        : (room!.hourlyRateSingle > 0 ? room!.hourlyRateSingle : room!.pricePerHour);
    final double roomTotal = durationHours * pricePerHour;
    final double grandTotal = (roomTotal + extrasTotal - voucherDiscount).clamp(0.0, double.infinity);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.neonBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(
                  "${AppStrings.schedule}: $durationHours ${AppStrings.gaming}",
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
                SizedBox(height: 2.h),
                AppText.body(
                  "${AppStrings.pricePerHour}: ${pricePerHour.toStringAsFixed(0)} ${AppStrings.egp}",
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
                if (extrasTotal > 0) ...[
                  SizedBox(height: 2.h),
                  AppText.body(
                    "مجموع الإضافات: ${extrasTotal.toStringAsFixed(0)} ${AppStrings.egp}",
                    color: AppColors.neonPurple,
                    fontSize: 12.sp,
                  ),
                ],
                if (voucherDiscount > 0) ...[
                  SizedBox(height: 2.h),
                  AppText.body(
                    "خصم القسيمة: -${voucherDiscount.toStringAsFixed(2)} ${AppStrings.egp}",
                    color: AppColors.success,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.body(
                AppStrings.totalPrice,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
              SizedBox(height: 4.h),
              AppText.subHeading(
                "${grandTotal.toStringAsFixed(2)} ${AppStrings.egp}",
                color: AppColors.neonBlue,
                fontSize: 18.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
