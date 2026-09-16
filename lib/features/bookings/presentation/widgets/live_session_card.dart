import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import '../../../analytics/presentation/dashboard_cubit.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import 'add_extras_dialog.dart';
import 'radial_countdown_ring.dart';
import 'session_ticker.dart';
import 'station_control_drawer.dart';
import 'swap_room_dialog.dart';

/// Interactive UI Card Widget for live active gaming sessions.
/// Listens to global SessionTickerScope without running individual timers.
class LiveSessionCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onEndSession;
  final VoidCallback? onExtendSession;
  final Function(int additionalMinutes)? onExtendMinutes;
  final double? width;

  const LiveSessionCard({
    super.key,
    required this.booking,
    this.onEndSession,
    this.onExtendSession,
    this.onExtendMinutes,
    this.width,
  });

  @override
  State<LiveSessionCard> createState() => _LiveSessionCardState();
}

class _LiveSessionCardState extends State<LiveSessionCard> {

  Duration get _remainingDuration {
    return widget.booking.remainingDuration();
  }

  bool get _isExpired => widget.booking.isSessionExpired();

  String _formatTime12Hour(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, hour, minute);
        return DateFormat('hh:mm a').format(dt);
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.abs();
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    if (totalSeconds >= 3600) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Read broadcast ticker to rebuild synchronously on tick
    SessionTickerScope.nowOf(context);

    final isExpired = _isExpired;
    final remaining = _remainingDuration;
    final formattedTime = _formatDuration(remaining);
    final String formattedDurationHrs = (widget.booking.durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');

    return Container(
      width: widget.width ?? 320.w,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isExpired ? AppColors.danger : AppColors.neonBlue.withValues(alpha: 0.4),
          width: isExpired ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpired
                ? AppColors.danger.withValues(alpha: 0.2)
                : AppColors.neonBlue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Room & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_esports,
                    size: 16.r,
                    color: isExpired ? AppColors.danger : AppColors.neonBlue,
                  ),
                  SizedBox(width: 4.w),
                  AppText.subHeading(
                    widget.booking.roomName,
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: 4.w),
                  IconButton(
                    icon: Icon(Icons.swap_horiz, size: 16.r, color: AppColors.neonBlue),
                    tooltip: AppStrings.swapRoom,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showSwapRoomDialog(context),
                  ),
                  SizedBox(width: 2.w),
                  IconButton(
                    icon: Icon(Icons.tune_rounded, size: 16.r, color: AppColors.neonPurple),
                    tooltip: 'Station Control Drawer',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => StationControlDrawer.show(
                      context,
                      booking: widget.booking,
                      onEndSession: widget.onEndSession,
                    ),
                  ),
                ],
              ),
              StatusBadge.success(AppStrings.inProgress.toUpperCase()),
            ],
          ),
          SizedBox(height: 6.h),

          // Customer Name, Phone & Telemetry Tags
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(
                      widget.booking.userName ?? AppStrings.anonymous,
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    if (widget.booking.userPhone != null && widget.booking.userPhone?.isNotEmpty == true) ...[
                      SizedBox(height: 1.h),
                      AppText.body(
                        widget.booking.userPhone ?? '',
                        fontSize: 10.sp,
                        color: AppColors.neonBlue,
                      ),
                    ],
                  ],
                ),
              ),
              // Total Price Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3)),
                ),
                child: AppText.subHeading(
                  '${widget.booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                  fontSize: 11.sp,
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Live Timer Container with Radial Countdown Ring
          InkWell(
            onTap: () => StationControlDrawer.show(
              context,
              booking: widget.booking,
              onEndSession: widget.onEndSession,
            ),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isExpired
                    ? AppColors.danger.withValues(alpha: 0.12)
                    : AppColors.neonBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isExpired ? AppColors.danger : AppColors.neonBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        RadialCountdownRing(
                          totalDuration: Duration(minutes: widget.booking.durationMinutes),
                          remainingDuration: remaining,
                          isExpired: isExpired,
                          isOpenEnded: widget.booking.isOpenEnded,
                          showText: false,
                          size: 32.0,
                          strokeWidth: 3.0,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.body(
                                isExpired ? AppStrings.timeExpired : AppStrings.remainingTime,
                                fontSize: 10.sp,
                                color: isExpired ? AppColors.danger : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              AppText.body(
                                '${_formatTime12Hour(widget.booking.startTime)} ($formattedDurationHrs ${AppStrings.hours})',
                                fontSize: 9.sp,
                                color: AppColors.textMuted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppText.subHeading(
                      isExpired ? '-$formattedTime' : formattedTime,
                      fontSize: 16.sp,
                      color: isExpired ? AppColors.danger : AppColors.neonBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildActiveSessionRequests(context),
          SizedBox(height: 6.h),

          // Quick Time Extensions Bar (+15m, +30m, +1h)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _handleExtendMinutes(context, 15),
                  borderRadius: BorderRadius.circular(4.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '+15m',
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: InkWell(
                  onTap: () => _handleExtendMinutes(context, 30),
                  borderRadius: BorderRadius.circular(4.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '+30m',
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: InkWell(
                  onTap: () => _handleExtendMinutes(context, 60),
                  borderRadius: BorderRadius.circular(4.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '+1h',
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Actions Row: End Session, Add Extras, Extend Time
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: AppStrings.endSession,
                  icon: Icons.stop_circle_outlined,
                  variant: AppButtonVariant.outlined,
                  height: 30.h,
                  onPressed: () => _handleEndSession(context),
                ),
              ),
              SizedBox(width: 4.w),
              IconButton(
                icon: Icon(Icons.add_shopping_cart, size: 16.r, color: AppColors.neonCyan),
                tooltip: AppStrings.addExtrasToSession,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                ),
                onPressed: () => _showAddExtrasDialog(context),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: AppButton(
                  text: AppStrings.extendTime,
                  icon: Icons.add_alarm_rounded,
                  variant: AppButtonVariant.primary,
                  height: 30.h,
                  onPressed: () => _handleExtendSession(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddExtrasDialog(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? widget.booking.loungeId;
    final dashboardCubit = context.read<DashboardCubit>();

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => AddExtrasDialog(
        bookingId: widget.booking.id,
        loungeId: loungeId,
        onConfirm: (extras, totalCost) async {
          final success = await dashboardCubit.addExtrasToSession(widget.booking.id, extras, totalCost);
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

  void _handleEndSession(BuildContext context) {
    if (widget.onEndSession != null) {
      widget.onEndSession!();
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
              final success = await dashboardCubit.endSession(widget.booking.id);
              if (!success) {
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
            },
          ),
        ],
      ),
    );
  }

  void _handleExtendSession(BuildContext context) {
    if (widget.onExtendSession != null) {
      widget.onExtendSession!();
      return;
    }

    int selectedMinutes = 30;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogInnerContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          title: Row(
            children: [
              const Icon(Icons.add_alarm, color: AppColors.neonBlue),
              SizedBox(width: 8.w),
              Expanded(
                child: AppText.subHeading(
                  AppStrings.extendTime,
                  color: AppColors.neonBlue,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(
                '${widget.booking.roomName} - ${widget.booking.userName ?? AppStrings.anonymous}',
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                children: [30, 60, 90, 120].map((mins) {
                  final isSelected = selectedMinutes == mins;
                  return ChoiceChip(
                    label: AppText.body(
                      '+$mins ${AppStrings.minutesUnit}',
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12.sp,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.neonBlue,
                    backgroundColor: AppColors.cardBackground,
                    onSelected: (selected) {
                      if (selected) {
                        setDialogState(() {
                          selectedMinutes = mins;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            AppButton(
              text: AppStrings.cancel,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppButton(
              text: AppStrings.extendTime,
              variant: AppButtonVariant.primary,
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _handleExtendMinutes(context, selectedMinutes);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExtendMinutes(BuildContext context, int minutes) async {
    if (widget.onExtendMinutes != null) {
      widget.onExtendMinutes!(minutes);
      return;
    }

    final dashboardCubit = context.read<DashboardCubit>();
    final success = await dashboardCubit.extendSession(widget.booking.id, minutes);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.timeExtendedSuccess),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final errorMsg = dashboardCubit.state.errorMessage ?? 'لا يمكن تمديد الحجز لأن هناك حجزاً آخر يبدأ بعد وقت حجزك مباشرة.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildActiveSessionRequests(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      builder: (context, requestsState) {
        final sessionRequests = requestsState.requests.where((r) {
          if (r.isAttended) return false;
          final matchBooking = r.bookingId != null && r.bookingId == widget.booking.id;
          final matchRoom = r.roomId != null && r.roomId == widget.booking.roomId;
          return matchBooking || matchRoom;
        }).toList();

        if (sessionRequests.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: EdgeInsets.only(top: 8.h),
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 14),
                  SizedBox(width: 4.w),
                  Text(
                    'طلبات الجلسة الحالية (${sessionRequests.length})',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ...sessionRequests.map((req) {
                final title = req.titleAr.isNotEmpty ? req.titleAr : req.titleEn;
                final body = req.bodyAr.isNotEmpty ? req.bodyAr : req.bodyEn;
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '• $title ${body.isNotEmpty ? "($body)" : ""}',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 10.sp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      InkWell(
                        onTap: () {
                          context.read<ClientRequestsCubit>().markAsAttended(
                            req.id,
                            isCanteenOrder: req.isCanteenOrder,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'تم التنفيذ',
                            style: TextStyle(color: Colors.black, fontSize: 9.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showSwapRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => SwapRoomDialog(
        bookingId: widget.booking.id,
        currentRoomId: widget.booking.roomId,
      ),
    );
  }
}
