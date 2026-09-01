import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final Function(T?) onChanged;
  final String? Function(T?)? validator;

  const CustomDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.mutedBackground,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.neonBlue),
            ),
          ),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(itemLabel(e)),
          )).toList(),
          onChanged: onChanged,
          validator: validator,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 24.r),
        ),
      ],
    );
  }
}
