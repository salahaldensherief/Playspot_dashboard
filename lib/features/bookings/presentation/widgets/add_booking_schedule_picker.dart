import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';

class AddBookingSchedulePicker extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;

  const AddBookingSchedulePicker({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.onDateChanged,
    required this.onStartTimeChanged,
  });

  TimeOfDay _calculateEndTime(TimeOfDay start, int durationMinutes) {
    final totalMinutes = start.hour * 60 + start.minute + durationMinutes;
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) onDateChanged(date);
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (time != null) onStartTimeChanged(time);
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontWeight: FontWeight.bold),
        SizedBox(height: 8.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.neonBlue),
                SizedBox(width: 8.w),
                Expanded(
                  child: AppText.body(
                    value,
                    fontSize: 13.sp,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildPickerField(
                label: AppStrings.date,
                value: DateFormat('yyyy-MM-dd').format(selectedDate),
                icon: Icons.calendar_today,
                onTap: () => _pickDate(context),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              flex: 2,
              child: _buildPickerField(
                label: AppStrings.opensAt,
                value: startTime.format(context),
                icon: Icons.access_time,
                onTap: () => _pickStartTime(context),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              flex: 3,
              child: BlocBuilder<BookingCubit, BookingState>(
                buildWhen: (p, c) => p.selectedDurationMinutes != c.selectedDurationMinutes,
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(AppStrings.duration, fontWeight: FontWeight.bold),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: AppColors.neonBlue, size: 20),
                              onPressed: state.selectedDurationMinutes > 15
                                  ? () => context
                                      .read<BookingCubit>()
                                      .updateSelectedDuration(state.selectedDurationMinutes - 15)
                                  : null,
                            ),
                            AppText.body(
                              state.selectedDurationMinutes < 60
                                  ? "${state.selectedDurationMinutes} min"
                                  : "${(state.selectedDurationMinutes / 60.0).toStringAsFixed(2)} hrs",
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: AppColors.neonBlue, size: 20),
                              onPressed: () => context
                                  .read<BookingCubit>()
                                  .updateSelectedDuration(state.selectedDurationMinutes + 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        BlocBuilder<BookingCubit, BookingState>(
          buildWhen: (p, c) => p.selectedDurationMinutes != c.selectedDurationMinutes,
          builder: (context, state) {
            final endTime = _calculateEndTime(startTime, state.selectedDurationMinutes);
            return AppText.body(
              "Ends at: ${endTime.format(context)} (${state.selectedDurationMinutes / 60.0} hrs total)",
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            );
          },
        ),
      ],
    );
  }
}
