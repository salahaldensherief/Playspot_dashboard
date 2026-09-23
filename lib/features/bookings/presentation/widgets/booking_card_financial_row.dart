import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_info_chip.dart';

class BookingCardFinancialRow extends StatelessWidget {
  final Booking booking;
  final bool isPaid;
  final VoidCallback onShowDiscount;

  const BookingCardFinancialRow({
    super.key,
    required this.booking,
    required this.isPaid,
    required this.onShowDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final discount = booking.discountAmount;
    final hasDiscount = discount != null && discount > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(
                AppStrings.totalPrice,
                fontSize: 10.5.sp,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Flexible(
                    child: AppText.subHeading(
                      '${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                      color: AppColors.neonBlue,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                    ),
                  ),
                  if (hasDiscount) ...[
                    SizedBox(width: 6.w),
                    BookingInfoChip(
                      label: '-${discount.toStringAsFixed(0)} ${AppStrings.egp}',
                      color: AppColors.warning,
                      bordered: true,
                    ),
                  ],
                  SizedBox(width: 6.w),
                  Tooltip(
                    message: AppStrings.applyDiscount,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: onShowDiscount,
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.local_offer_outlined,
                          size: 14.r,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        isPaid
            ? StatusBadge.success(AppStrings.paid.toUpperCase())
            : StatusBadge.warning(AppStrings.unpaid.toUpperCase()),
      ],
    );
  }
}
