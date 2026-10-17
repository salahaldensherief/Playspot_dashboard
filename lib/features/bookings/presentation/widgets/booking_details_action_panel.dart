import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'swap_room_dialog.dart';
import '../../../analytics/presentation/dashboard_cubit.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../../../../core/utils/permission_extension.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../domain/services/booking_schedule.dart';
import 'session_time_builder.dart';

class BookingDetailsActionPanel extends StatefulWidget {
  final Booking booking;
  final bool isLoading;
  final VoidCallback onConfirmCashPayment;

  const BookingDetailsActionPanel({
    super.key,
    required this.booking,
    required this.isLoading,
    required this.onConfirmCashPayment,
  });

  @override
  State<BookingDetailsActionPanel> createState() =>
      _BookingDetailsActionPanelState();
}

class _BookingDetailsActionPanelState extends State<BookingDetailsActionPanel> {
  bool _busy = false;
  bool _confirming = false;
  Booking get booking => widget.booking;
  bool get isLoading => widget.isLoading || _busy;

  Future<void> _run(Future<bool> Function() action) async {
    if (isLoading) return;
    setState(() => _busy = true);
    try {
      final success = await action();
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<BookingCubit>().state.errorMessage ??
                  AppStrings.actionFailed,
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.actionFailed),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() => _run(() async {
    if (!context.hasPermission('sessions_control')) return false;
    if (!booking.isOpenTime) {
      return context.read<DashboardCubit>().endSession(booking.id);
    }
    final result = await context.read<BookingCubit>().completeOpenTimeSession(
      booking.id,
    );
    return result?['success'] == true &&
        result?['booking_id'] == booking.id &&
        result?['status'] == 'completed';
  });

  Future<void> _cancel() async {
    if (isLoading || _confirming || !context.hasPermission('bookings.manage')) {
      return;
    }
    _confirming = true;
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.cancelBooking,
      message: 'cancel_booking_confirmation'.tr(),
    );
    _confirming = false;
    if (!mounted ||
        confirmed != true ||
        !context.hasPermission('bookings.manage')) {
      return;
    }
    await _run(() => context.read<BookingCubit>().rejectBooking(booking.id));
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    context.select((PermissionsCubit? cubit) => cubit?.state);
    context.select((LoginCubit? cubit) => cubit?.state.user);
    final cubit = context.read<BookingCubit>();
    final isPending = booking.status == BookingStatus.pending;
    final isInProgress = booking.status == BookingStatus.inProgress;
    final isUpcoming = booking.status == BookingStatus.upcoming;
    final isUnpaid = booking.paymentStatus != PaymentStatus.paid;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(color: AppColors.neonBlue),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPending)
          AppButton(
            text: 'accept_booking_now'.tr(),
            variant: AppButtonVariant.primary,
            backgroundColor: AppColors.success,
            height: 40.h,
            onPressed: context.hasPermission('bookings.manage')
                ? () => _run(() => cubit.approveBooking(booking.id))
                : null,
          ),
        if (booking.canStartSession)
          SessionTimeBuilder(
            builder: (context, now) {
              if (!BookingSchedule.canStart(booking.startDateTime, now)) {
                return const SizedBox.shrink();
              }
              return AppButton(
                text: 'start_session_now'.tr(),
                variant: AppButtonVariant.primary,
                height: 40.h,
                onPressed: context.hasPermission('sessions_control')
                    ? () => _run(() => cubit.startBookingSession(booking.id))
                    : null,
              );
            },
          ),
        if (isInProgress)
          AppButton(
            text: 'finish_and_bill_session'.tr(),
            variant: AppButtonVariant.primary,
            height: 40.h,
            onPressed: context.hasPermission('sessions_control')
                ? _finish
                : null,
          ),
        if (isUnpaid && !isPending) ...[
          SizedBox(height: 8.h),
          AppButton(
            text: AppStrings.confirmCash,
            variant: AppButtonVariant.primary,
            backgroundColor: AppColors.neonBlue,
            height: 40.h,
            onPressed: context.hasPermission('billing_checkout')
                ? widget.onConfirmCashPayment
                : null,
          ),
        ],
        SizedBox(height: 8.h),
        Row(
          children: [
            if (isInProgress || isUpcoming)
              Expanded(
                child: AppButton(
                  text: AppStrings.swapRoom,
                  variant: AppButtonVariant.outlined,
                  height: 36.h,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SwapRoomDialog(
                        bookingId: booking.id,
                        currentRoomId: booking.roomId,
                      ),
                    );
                  },
                ),
              ),
            if (isInProgress || isUpcoming) SizedBox(width: 8.w),
            if (booking.status != BookingStatus.cancelled &&
                booking.status != BookingStatus.completed)
              Expanded(
                child: AppButton(
                  text: AppStrings.cancelBooking,
                  variant: AppButtonVariant.danger,
                  height: 36.h,
                  onPressed: context.hasPermission('bookings.manage')
                      ? _cancel
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
