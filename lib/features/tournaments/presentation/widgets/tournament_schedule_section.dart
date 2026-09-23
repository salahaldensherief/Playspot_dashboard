import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text_field.dart';

class TournamentScheduleSection extends StatelessWidget {
  final DateTime registrationOpensAt;
  final DateTime registrationClosesAt;
  final DateTime checkInOpensAt;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime> onRegistrationOpensChanged;
  final ValueChanged<DateTime> onRegistrationClosesChanged;
  final ValueChanged<DateTime> onCheckInOpensChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;

  const TournamentScheduleSection({
    super.key,
    required this.registrationOpensAt,
    required this.registrationClosesAt,
    required this.checkInOpensAt,
    required this.startDate,
    required this.endDate,
    required this.onRegistrationOpensChanged,
    required this.onRegistrationClosesChanged,
    required this.onCheckInOpensChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  Future<void> _selectDateTime(
    BuildContext context,
    DateTime initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              onPrimary: Colors.black,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.neonBlue,
                onPrimary: Colors.black,
                surface: AppColors.cardBackground,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child ?? const SizedBox(),
          );
        },
      );

      final finalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? initial.hour,
        pickedTime?.minute ?? initial.minute,
      );
      onPicked(finalDateTime);
    }
  }

  Widget _buildField(
    BuildContext context,
    String label,
    DateTime value,
    ValueChanged<DateTime> onPicked,
  ) {
    final formatted = DateFormat('yyyy/MM/dd HH:mm').format(value);
    return InkWell(
      onTap: () => _selectDateTime(context, value, onPicked),
      child: AbsorbPointer(
        child: AppTextField(
          initialValue: formatted,
          key: ValueKey('$label-$formatted'),
          label: label,
          enabled: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.schedule,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 16.w,
          runSpacing: 16.h,
          children: [
            SizedBox(
              width: 320.w,
              child: _buildField(
                context,
                AppStrings.regOpensAt,
                registrationOpensAt,
                onRegistrationOpensChanged,
              ),
            ),
            SizedBox(
              width: 320.w,
              child: _buildField(
                context,
                AppStrings.regClosesAt,
                registrationClosesAt,
                onRegistrationClosesChanged,
              ),
            ),
            SizedBox(
              width: 320.w,
              child: _buildField(
                context,
                AppStrings.checkInOpensAt,
                checkInOpensAt,
                onCheckInOpensChanged,
              ),
            ),
            SizedBox(
              width: 320.w,
              child: _buildField(
                context,
                AppStrings.startDate,
                startDate,
                onStartDateChanged,
              ),
            ),
            SizedBox(
              width: 320.w,
              child: _buildField(
                context,
                AppStrings.endDate,
                endDate,
                onEndDateChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
