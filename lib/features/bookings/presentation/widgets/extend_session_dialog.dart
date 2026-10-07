import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';

class ExtendSessionDialog extends StatefulWidget {
  final Booking booking;
  final ValueChanged<int>? onExtendMinutes;

  const ExtendSessionDialog({
    super.key,
    required this.booking,
    this.onExtendMinutes,
  });

  static Future<void> show(
    BuildContext context,
    Booking booking, {
    ValueChanged<int>? onExtendMinutes,
  }) {
    final dashboardCubit = context.read<DashboardCubit?>();
    final bookingCubit = context.read<BookingCubit?>();

    return showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          if (dashboardCubit != null) BlocProvider.value(value: dashboardCubit),
          if (bookingCubit != null) BlocProvider.value(value: bookingCubit),
        ],
        child: ExtendSessionDialog(
          booking: booking,
          onExtendMinutes: onExtendMinutes,
        ),
      ),
    );
  }

  @override
  State<ExtendSessionDialog> createState() => _ExtendSessionDialogState();
}

class _ExtendSessionDialogState extends State<ExtendSessionDialog> {
  int _selectedMinutes = 30;
  bool _isLoading = false;

  static const List<int> _durations = [15, 30, 60, 90, 120];

  Future<void> _handleConfirm() async {
    if (_isLoading) return;

    if (widget.onExtendMinutes != null) {
      Navigator.of(context).pop();
      widget.onExtendMinutes?.call(_selectedMinutes);
      return;
    }

    setState(() => _isLoading = true);

    final dashboardCubit = context.read<DashboardCubit>();
    final bookingCubit = context.read<BookingCubit>();

    final success = await dashboardCubit.extendSession(
      widget.booking.id,
      _selectedMinutes,
    );
    if (success) {
      bookingCubit.startWatchingBookings(
        loungeId: widget.booking.loungeId,
        forceRefresh: true,
      );
    }

    if (!mounted) return;

    if (!success) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('booking_extension_failed'.tr()),
          backgroundColor: AppColors.danger),
      );
      return;
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.timeExtendedSuccess),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: AppStrings.extendTime,
      icon: Icons.add_alarm_rounded,
      width: 420.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.text,
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        SizedBox(width: 8.w),
        AppButton(
          text: AppStrings.extendTime,
          variant: AppButtonVariant.primary,
          isLoading: _isLoading,
          onPressed: _handleConfirm,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.mutedBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  size: 16.r,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: AppText.body(
                    '${widget.booking.roomName} • ${widget.booking.userName ?? AppStrings.anonymous}',
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _durations.map((mins) {
              final isSelected = _selectedMinutes == mins;
              return ChoiceChip(
                label: Text(
                  'extend_minutes_short'.tr(args: [(mins).toString()]),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.neonBlue,
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.neonBlue
                        : AppColors.borderDefault,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedMinutes = mins);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
