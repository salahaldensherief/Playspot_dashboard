import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_extras_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/extend_session_dialog.dart';

class LiveSessionCardActions extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onEndSession;
  final VoidCallback? onExtendSession;
  final ValueChanged<int>? onExtendMinutes;

  const LiveSessionCardActions({
    super.key,
    required this.booking,
    this.onEndSession,
    this.onExtendSession,
    this.onExtendMinutes,
  });

  void _handleEndSession(BuildContext context) {
    if (onEndSession != null) {
      onEndSession!();
      return;
    }

    final dashboardCubit = context.read<DashboardCubit>();
    final bookingCubit = context.read<BookingCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Row(
          children: [
            const Icon(Icons.stop_circle, color: AppColors.danger),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText.subHeading(
                AppStrings.confirmEndSession,
                color: AppColors.danger,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        content: AppText.body(
          AppStrings.confirmEndSessionMessage,
          fontSize: 13.sp,
          color: AppColors.textPrimary,
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppButton(
            text: AppStrings.endSession,
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await dashboardCubit.endSession(booking.id);
              if (!success) {
                await bookingCubit.changeBookingStatus(booking.id, BookingStatus.completed);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.sessionEndedSuccess),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddExtrasDialog(BuildContext context) {
    final dashboardCubit = context.read<DashboardCubit>();

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => AddExtrasDialog(
        bookingId: booking.id,
        loungeId: booking.loungeId,
        onConfirm: (extras, totalCost) async {
          final success = await dashboardCubit.addExtrasToSession(booking.id, extras, totalCost);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? AppStrings.extrasAddedSuccess : AppStrings.actionFailed),
                backgroundColor: success ? AppColors.success : AppColors.danger,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double h = 36.h;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: AppStrings.endSession,
            icon: Icons.stop_circle_outlined,
            variant: AppButtonVariant.outlined,
            height: h,
            onPressed: () => _handleEndSession(context),
          ),
        ),
        SizedBox(width: 6.w),
        Tooltip(
          message: AppStrings.addExtrasToSession,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () => _showAddExtrasDialog(context),
            child: Container(
              width: h,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.35)),
              ),
              child: Icon(Icons.add_shopping_cart, size: 17.r, color: AppColors.neonCyan),
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: AppButton(
            text: AppStrings.extendTime,
            icon: Icons.add_alarm_rounded,
            variant: AppButtonVariant.primary,
            height: h,
            onPressed: () {
              if (onExtendSession != null) {
                onExtendSession!();
              } else {
                ExtendSessionDialog.show(context, booking, onExtendMinutes: onExtendMinutes);
              }
            },
          ),
        ),
      ],
    );
  }
}
