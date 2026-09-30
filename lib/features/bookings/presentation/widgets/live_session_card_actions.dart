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
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';

class LiveSessionCardActions extends StatefulWidget {
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

  @override
  State<LiveSessionCardActions> createState() => _LiveSessionCardActionsState();
}

class _LiveSessionCardActionsState extends State<LiveSessionCardActions> {
  bool _isCompleting = false;

  Future<void> _handleEndSession(BuildContext context) async {
    if (widget.onEndSession != null) {
      widget.onEndSession!();
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
      final bookingCubit = context.read<BookingCubit>();
      final success = await dashboardCubit.endSession(widget.booking.id);
      if (!success && context.mounted) {
        await bookingCubit.changeBookingStatus(widget.booking.id, BookingStatus.completed);
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
    }
  }

  void _showAddExtrasDialog(BuildContext context) {
    final dashboardCubit = context.read<DashboardCubit>();
    final bookingCubit = context.read<BookingCubit>();

    AddExtrasDialog.show(
      context,
      bookingId: widget.booking.id,
      loungeId: widget.booking.loungeId,
      onConfirm: (extras, totalCost) async {
        final success = await dashboardCubit.addExtrasToSession(widget.booking.id, extras, totalCost);
        if (success) {
          bookingCubit.startWatchingBookings(loungeId: widget.booking.loungeId, forceRefresh: true);
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

  Future<void> _handleCompleteOpenTime(BuildContext context) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

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
        setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double h = 36.h;
    final booking = widget.booking;

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
          child: booking.isOpenEnded
              ? AppButton(
                  text: AppStrings.completeAndCalculate,
                  icon: Icons.price_check_rounded,
                  variant: AppButtonVariant.primary,
                  height: h,
                  isLoading: _isCompleting,
                  onPressed: _isCompleting ? null : () => _handleCompleteOpenTime(context),
                )
              : AppButton(
                  text: AppStrings.extendTime,
                  icon: Icons.add_alarm_rounded,
                  variant: AppButtonVariant.primary,
                  height: h,
                  onPressed: () {
                    if (widget.onExtendSession != null) {
                      widget.onExtendSession!();
                    } else {
                      ExtendSessionDialog.show(context, booking, onExtendMinutes: widget.onExtendMinutes);
                    }
                  },
                ),
        ),
      ],
    );
  }
}
