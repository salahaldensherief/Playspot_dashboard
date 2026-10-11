import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_operations_summary.dart';

/// Displays next scheduled session on the same room resource and warns of conflicts.
class BookingNextSessionNotice extends StatelessWidget {
  final Booking booking;

  const BookingNextSessionNotice({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final allBookings = context.select((BookingCubit c) => c.state.bookings);
    final summary = SessionOperationsSummary.fromBookings(booking, allBookings);
    final nextBooking = summary.nextBooking;

    if (nextBooking == null) return const SizedBox.shrink();

    final hasConflict = summary.hasConflict;
    final nextUserName = nextBooking.userName?.trim().isNotEmpty == true
        ? (nextBooking.userName ?? AppStrings.anonymous)
        : AppStrings.anonymous;

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: hasConflict
            ? AppColors.danger.withValues(alpha: 0.12)
            : AppColors.mutedBackground.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: hasConflict
              ? AppColors.danger.withValues(alpha: 0.35)
              : AppColors.borderDefault.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasConflict
                ? Icons.warning_amber_rounded
                : Icons.next_plan_outlined,
            size: 13.r,
            color: hasConflict ? AppColors.danger : AppColors.neonBlue,
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: AppText.body(
              '${'cashier.next'.tr()}: $nextUserName · ${nextBooking.startTime}',
              fontSize: 10.5.sp,
              color: hasConflict ? AppColors.danger : AppColors.textSecondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasConflict) ...[
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'cashier.conflict'.tr(),
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
