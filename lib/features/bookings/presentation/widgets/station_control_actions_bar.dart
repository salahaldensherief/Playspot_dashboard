import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_extras_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/swap_room_dialog.dart';

import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';

class StationControlActionsBar extends StatefulWidget {
  final Booking booking;

  const StationControlActionsBar({
    super.key,
    required this.booking,
  });

  @override
  State<StationControlActionsBar> createState() => _StationControlActionsBarState();
}

class _StationControlActionsBarState extends State<StationControlActionsBar> {
  bool _isCompletingOpenTime = false;

  Widget _buildExtensionButton(BuildContext context, int minutes) {
    final label = '+$minutes ${AppStrings.minutesUnit}';
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () async {
        final success = await context.read<DashboardCubit>().extendSession(widget.booking.id, minutes);
        if (success && context.mounted) {
          context.read<BookingCubit>().startWatchingBookings(loungeId: widget.booking.loungeId, forceRefresh: true);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.mutedBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.neonBlue,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCompleteOpenTime(BuildContext context) async {
    if (_isCompletingOpenTime) return;
    setState(() => _isCompletingOpenTime = true);

    try {
      final bookingCubit = context.read<BookingCubit>();
      final roomCubit = context.read<RoomCubit>();
      final result = await bookingCubit.completeOpenTimeSession(widget.booking.id);

      if (!context.mounted) return;

      if (result == null) {
        final message = bookingCubit.state.errorMessage ?? AppStrings.failedToCompleteOpenTime;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.danger),
        );
        return;
      }

      roomCubit.watchRooms(widget.booking.loungeId, forceRefresh: true);
      bookingCubit.startWatchingBookings(loungeId: widget.booking.loungeId, forceRefresh: true);
      final total = result['final_total'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            total == null
                ? AppStrings.openTimeCompletedSuccess
                : '${AppStrings.openTimeCompletedSuccess}. ${AppStrings.totalPrice}: $total ${AppStrings.egp}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompletingOpenTime = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (booking.isOpenEnded) ...[
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.all_inclusive_rounded, color: AppColors.neonCyan, size: 18.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        AppStrings.openTimeSessionActive,
                        style: TextStyle(
                          color: AppColors.neonCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                AppButton(
                  text: AppStrings.completeOpenTimeSession,
                  icon: Icons.price_check_rounded,
                  variant: AppButtonVariant.primary,
                  height: 38.h,
                  isLoading: _isCompletingOpenTime,
                  onPressed: _isCompletingOpenTime
                      ? null
                      : () => _handleCompleteOpenTime(context),
                ),
              ],
            ),
          ),
        ] else ...[
          // Quick Time Extension Bar (+15m, +30m, +1h)
          Text(
            AppStrings.extendTime,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _buildExtensionButton(context, 15)),
              SizedBox(width: 8.w),
              Expanded(child: _buildExtensionButton(context, 30)),
              SizedBox(width: 8.w),
              Expanded(child: _buildExtensionButton(context, 60)),
            ],
          ),
        ],
        SizedBox(height: 16.h),


        // Quick Actions Bar (Extras & Swap)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final dashboardCubit = context.read<DashboardCubit>();
                  final bookingCubit = context.read<BookingCubit>();

                  AddExtrasDialog.show(
                    context,
                    bookingId: booking.id,
                    loungeId: booking.loungeId,
                    onConfirm: (extras, totalCost) async {
                      final success = await dashboardCubit.addExtrasToSession(
                        booking.id,
                        extras,
                        totalCost,
                      );
                      if (success) {
                        bookingCubit.startWatchingBookings(loungeId: booking.loungeId, forceRefresh: true);
                      }
                    },
                  );
                },
                icon: Icon(Icons.fastfood_rounded, size: 16.sp, color: AppColors.neonPurple),
                label: Text(
                  AppStrings.addExtrasToSession,
                  style: TextStyle(
                    color: AppColors.neonPurple,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.neonPurple.withValues(alpha: 0.4)),
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SwapRoomDialog(
                      bookingId: booking.id,
                      currentRoomId: booking.roomId,
                    ),
                  );
                },
                icon: Icon(Icons.swap_horiz_rounded, size: 16.sp, color: AppColors.textPrimary),
                label: Text(
                  AppStrings.swapRoom,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderDefault),
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
