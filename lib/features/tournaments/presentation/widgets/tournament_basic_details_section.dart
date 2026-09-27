import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text_field.dart';

class TournamentBasicDetailsSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController gameTitleController;
  final TextEditingController entryFeeController;
  final TextEditingController prizePoolController;
  final int treeSize;
  final ValueChanged<int?> onTreeSizeChanged;

  const TournamentBasicDetailsSection({
    super.key,
    required this.titleController,
    required this.gameTitleController,
    required this.entryFeeController,
    required this.prizePoolController,
    required this.treeSize,
    required this.onTreeSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: titleController,
          label: AppStrings.tournamentTitle,
          validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: gameTitleController,
                label: AppStrings.gameTitle,
                validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.treeSize,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  ),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<int>(
                    initialValue: treeSize,
                    dropdownColor: AppColors.cardBackground,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.mutedBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.borderDefault),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 8, child: Text('8')),
                      DropdownMenuItem(value: 16, child: Text('16')),
                      DropdownMenuItem(value: 32, child: Text('32')),
                    ],
                    onChanged: onTreeSizeChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: entryFeeController,
                label: AppStrings.entryFee,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                controller: prizePoolController,
                label: AppStrings.prizePool,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
