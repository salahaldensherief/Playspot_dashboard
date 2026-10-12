import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import 'start_session_button.dart';
import 'manual_payment_verification_dialog.dart';
import 'session_live_clock.dart';

class CashierSessionTile extends StatelessWidget {
  final Booking booking;
  final bool selected;
  final VoidCallback onSelect;

  const CashierSessionTile({
    super.key,
    required this.booking,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);

    final isPaid = booking.paymentStatus == PaymentStatus.paid;
    final isOpenTime = booking.isOpenEnded;

    final Color accentColor = selected
        ? AppColors.neonBlue
        : (isOpenTime ? AppColors.success : AppColors.neonPurple);

    return Semantics(
      selected: selected,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.12)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: 0.7)
                : AppColors.borderDefault,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11.r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSelect,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Room name + Status Badges
                    Row(
                      children: [
                        Icon(
                          Icons.sports_esports_rounded,
                          size: 15.r,
                          color: accentColor,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: AppText.subHeading(
                            booking.roomName.isNotEmpty
                                ? booking.roomName
                                : AppStrings.roomLabel,
                            fontSize: 13.sp,
                            color: AppColors.textPrimary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: isPaid
                                  ? AppColors.success.withValues(alpha: 0.4)
                                  : AppColors.warning.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            isPaid ? AppStrings.paid : AppStrings.unpaid,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isPaid
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),

                    // Customer Row
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13.r,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: AppText.body(
                            booking.userName ?? AppStrings.anonymous,
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOpenTime) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neonCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'cashier.open'.tr(),
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: AppColors.neonCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 6.h),

                    // Live Clock Row
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mutedBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13.r,
                            color: accentColor,
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: RepaintBoundary(
                              child: SessionLiveClock(booking: booking),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Action Controls & Alert Badge Bar
                    if (booking.status == BookingStatus.pendingVerification) ...[
                      SizedBox(height: 8.h),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => ManualPaymentVerificationDialog(
                              booking: booking,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6.r),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 13.r,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                AppStrings.pendingVerification,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (booking.status == BookingStatus.upcoming && isPaid) ...[
                      SizedBox(height: 8.h),
                      SizedBox(
                        width: double.infinity,
                        height: 28.h,
                        child: StartSessionButton(
                          bookingId: booking.id,
                          bookingDate: booking.date,
                          startTime: booking.startTime,
                          height: 28.h,
                        ),
                      ),
                    ] else if (booking.status == BookingStatus.pending) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => context
                                  .read<BookingCubit>()
                                  .approveBooking(booking.id),
                              borderRadius: BorderRadius.circular(6.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: AppColors.success.withValues(alpha: 0.4),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  AppStrings.confirmBooking,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: InkWell(
                              onTap: () => context
                                  .read<BookingCubit>()
                                  .rejectBooking(booking.id),
                              borderRadius: BorderRadius.circular(6.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(alpha: 0.4),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  AppStrings.reject,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
