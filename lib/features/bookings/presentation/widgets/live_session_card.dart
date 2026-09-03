import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/status_badge.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../rooms/presentation/cubit/room_cubit.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import 'swap_room_dialog.dart';

/// Interactive UI Card Widget for live active gaming sessions.
/// Displays dynamic real-time countdown timer, overdue alerts, and action handlers.
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
  Timer? _timer;
  late DateTime _targetEndTime;

  @override
  void initState() {
    super.initState();
    _targetEndTime = _calculateTargetEndTime();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant LiveSessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.durationMinutes != widget.booking.durationMinutes ||
        oldWidget.booking.startTime != widget.booking.startTime ||
        oldWidget.booking.date != widget.booking.date) {
      _targetEndTime = _calculateTargetEndTime();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _calculateTargetEndTime() {
    try {
      final date = widget.booking.date;
      final parts = widget.booking.startTime.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final start = DateTime(date.year, date.month, date.day, hour, minute);
        return start.add(Duration(minutes: widget.booking.durationMinutes));
      }
    } catch (e) {
      debugPrint('LiveSessionCard: Error parsing start time (${widget.booking.startTime}): $e');
    }
    return widget.booking.date.add(Duration(minutes: widget.booking.durationMinutes));
  }

  Duration get _remainingDuration {
    final now = DateTime.now();
    return _targetEndTime.difference(now);
  }

  bool get _isExpired => _remainingDuration.isNegative;

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
    final isExpired = _isExpired;
    final remaining = _remainingDuration;
    final formattedTime = _formatDuration(remaining);
    final String formattedDurationHrs = (widget.booking.durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');

    return Container(
      width: widget.width ?? 300.w,
      padding: EdgeInsets.all(14.r),
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
                    size: 18.r,
                    color: isExpired ? AppColors.danger : AppColors.neonBlue,
                  ),
                  SizedBox(width: 6.w),
                  AppText.subHeading(
                    widget.booking.roomName,
                    fontSize: 15.sp,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: 6.w),
                  IconButton(
                    icon: Icon(Icons.swap_horiz, size: 18.r, color: AppColors.neonBlue),
                    tooltip: AppStrings.swapRoom,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showSwapRoomDialog(context),
                  ),
                ],
              ),
              StatusBadge.success(AppStrings.inProgress.toUpperCase()),
            ],
          ),
          SizedBox(height: 10.h),

          // Customer Name & Phone
          AppText.body(
            widget.booking.userName ?? AppStrings.anonymous,
            fontSize: 13.sp,
            color: AppColors.textSecondary,
          ),
          if (widget.booking.userPhone != null && widget.booking.userPhone?.isNotEmpty == true) ...[
            SizedBox(height: 2.h),
            AppText.body(
              widget.booking.userPhone ?? '',
              fontSize: 11.sp,
              color: AppColors.neonBlue,
            ),
          ],
          SizedBox(height: 12.h),

          // Live Timer Container / Visual Expired Alert
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isExpired
                  ? AppColors.danger.withValues(alpha: 0.12)
                  : AppColors.neonBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isExpired ? AppColors.danger : AppColors.neonBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                      color: isExpired ? AppColors.danger : AppColors.neonBlue,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Column(
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
                          fontSize: 10.sp,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
                AppText.subHeading(
                  isExpired ? '-$formattedTime' : formattedTime,
                  fontSize: 18.sp,
                  color: isExpired ? AppColors.danger : AppColors.neonBlue,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Actions Row: End Session & Extend Time
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: AppStrings.endSession,
                  icon: Icons.stop_circle_outlined,
                  variant: AppButtonVariant.outlined,
                  height: 34.h,
                  onPressed: () => _handleEndSession(context),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: AppButton(
                  text: AppStrings.extendTime,
                  icon: Icons.add_alarm_rounded,
                  variant: AppButtonVariant.primary,
                  height: 34.h,
                  onPressed: () => _handleExtendSession(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleEndSession(BuildContext context) {
    if (widget.onEndSession != null) {
      widget.onEndSession!();
      return;
    }

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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: AppText.body(AppStrings.cancel, color: AppColors.textSecondary),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final cubit = context.read<BookingCubit>();
              await cubit.changeBookingStatus(
                widget.booking.id,
                BookingStatus.completed,
              );
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
            child: AppText.body(AppStrings.endSession, color: Colors.white, fontWeight: FontWeight.bold),
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
        builder: (context, setDialogState) => AlertDialog(
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
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: AppText.body(AppStrings.cancel, color: AppColors.textSecondary),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (widget.onExtendMinutes != null) {
                  widget.onExtendMinutes!(selectedMinutes);
                } else {
                  final cubit = context.read<BookingCubit>();
                  final success = await cubit.extendBookingDuration(widget.booking.id, selectedMinutes);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? AppStrings.timeExtendedSuccess : (cubit.state.errorMessage ?? AppStrings.actionFailed)),
                        backgroundColor: success ? AppColors.success : AppColors.danger,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: AppText.body(AppStrings.extendTime, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwapRoomDialog(BuildContext context) {
    final loginCubit = context.read<LoginCubit>();
    final roomCubit = context.read<RoomCubit>();
    final bookingCubit = context.read<BookingCubit>();

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: loginCubit),
          BlocProvider.value(value: roomCubit),
          BlocProvider.value(value: bookingCubit),
        ],
        child: SwapRoomDialog(
          bookingId: widget.booking.id,
          currentRoomId: widget.booking.roomId,
        ),
      ),
    );
  }
}
