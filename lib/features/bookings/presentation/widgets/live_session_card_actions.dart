import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_icon_badge.dart';
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

  Future<void> _handleEndSession(BuildContext context) async {
    if (onEndSession != null) {
      onEndSession!();
      return;
    }

    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.confirmEndSession,
      message: AppStrings.confirmEndSessionMessage,
      confirmText: AppStrings.endSession,
      cancelText: AppStrings.cancel,
      confirmColor: AppColors.danger,
    );

    if (confirmed == true && context.mounted) {
      final dashboardCubit = context.read<DashboardCubit>();
      final success = await dashboardCubit.endSession(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? AppStrings.sessionEndedSuccess : AppStrings.actionFailed),
            backgroundColor: success ? AppColors.success : AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAddExtrasDialog(BuildContext context) {
    final dashboardCubit = context.read<DashboardCubit>();
    final bookingCubit = context.read<BookingCubit>();

    AddExtrasDialog.show(
      context,
      bookingId: booking.id,
      loungeId: booking.loungeId,
      onConfirm: (extras, totalCost) async {
        final success = await dashboardCubit.addExtrasToSession(booking.id, extras, totalCost);
        if (success) {
          bookingCubit.startWatchingBookings(loungeId: booking.loungeId, forceRefresh: true);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? AppStrings.extrasAddedSuccess : AppStrings.actionFailed),
              backgroundColor: success ? AppColors.success : AppColors.danger,
            ),
          );
        }
      },
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
        AppIconBadge(
          icon: Icons.add_shopping_cart,
          color: AppColors.neonCyan,
          size: h,
          iconSize: 17.r,
          tooltip: AppStrings.addExtrasToSession,
          onTap: () => _showAddExtrasDialog(context),
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
