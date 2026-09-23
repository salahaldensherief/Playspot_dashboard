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

class ExtendSessionDialog extends StatefulWidget {
  final Booking booking;
  final ValueChanged<int>? onExtendMinutes;

  const ExtendSessionDialog({
    super.key,
    required this.booking,
    this.onExtendMinutes,
  });

  static Future<void> show(BuildContext context, Booking booking, {ValueChanged<int>? onExtendMinutes}) {
    return showDialog(
      context: context,
      builder: (_) => ExtendSessionDialog(booking: booking, onExtendMinutes: onExtendMinutes),
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
      widget.onExtendMinutes!(_selectedMinutes);
      return;
    }

    setState(() => _isLoading = true);

    final dashboardCubit = context.read<DashboardCubit>();
    final bookingCubit = context.read<BookingCubit>();

    final success = await dashboardCubit.extendSession(widget.booking.id, _selectedMinutes);
    if (!success) {
      await bookingCubit.extendBookingDuration(widget.booking.id, _selectedMinutes);
    }

    if (!mounted) return;

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
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
      actionsPadding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.neonBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: const Icon(Icons.add_alarm_rounded, color: AppColors.neonBlue),
          ),
          SizedBox(width: 12.w),
          AppText.subHeading(
            AppStrings.extendTime,
            color: AppColors.neonBlue,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
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
                Icon(Icons.meeting_room_outlined, size: 16.r, color: AppColors.textSecondary),
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
                  '+$mins دقيقة',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.neonBlue,
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  side: BorderSide(
                    color: isSelected ? AppColors.neonBlue : AppColors.borderDefault,
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
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.text,
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        AppButton(
          text: AppStrings.extendTime,
          variant: AppButtonVariant.primary,
          isLoading: _isLoading,
          onPressed: _handleConfirm,
        ),
      ],
    );
  }
}
