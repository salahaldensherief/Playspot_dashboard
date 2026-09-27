import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../domain/entities/loyalty_task_entity.dart';

class EditTaskDialog extends StatefulWidget {
  final LoyaltyTaskEntity task;
  final ValueChanged<LoyaltyTaskEntity> onSave;

  const EditTaskDialog({
    super.key,
    required this.task,
    required this.onSave,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleArController;
  late TextEditingController _titleEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _pointsController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _titleArController = TextEditingController(text: widget.task.titleAr);
    _titleEnController = TextEditingController(text: widget.task.titleEn);
    _descriptionArController = TextEditingController(text: widget.task.descriptionAr);
    _descriptionEnController = TextEditingController(text: widget.task.descriptionEn);
    _pointsController = TextEditingController(text: '${widget.task.pointsReward}');
    _isActive = widget.task.isActive;
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final points = int.tryParse(_pointsController.text) ?? widget.task.pointsReward;

      final updated = LoyaltyTaskEntity(
        id: widget.task.id,
        titleAr: _titleArController.text.trim(),
        titleEn: _titleEnController.text.trim(),
        descriptionAr: _descriptionArController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim(),
        pointsReward: points,
        completedCount: widget.task.completedCount,
        isActive: _isActive,
      );

      widget.onSave(updated);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 500.w,
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.subHeading(AppStrings.editTask, fontSize: 20.sp),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderDefault, height: 24),
              SizedBox(height: 12.h),

              // Title AR & EN
              AppTextField(
                controller: _titleArController,
                label: AppStrings.taskNameAr,
                validator: (val) => val == null || val.trim().isEmpty ? AppStrings.fieldRequired : null,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _titleEnController,
                label: AppStrings.taskNameEn,
                validator: (val) => val == null || val.trim().isEmpty ? AppStrings.fieldRequired : null,
              ),
              SizedBox(height: 12.h),

              // Description AR & EN
              AppTextField(
                controller: _descriptionArController,
                label: AppStrings.taskDescAr,
                maxLines: 2,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _descriptionEnController,
                label: AppStrings.taskDescEn,
                maxLines: 2,
              ),
              SizedBox(height: 12.h),

              // Points
              AppTextField(
                controller: _pointsController,
                label: AppStrings.rewardPoints,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppStrings.fieldRequired;
                  if (int.tryParse(val) == null) return AppStrings.invalidNumber;
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Active status toggle
              SwitchListTile(
                value: _isActive,
                activeThumbColor: AppColors.neonBlue,
                title: AppText.body(AppStrings.taskStatus),
                subtitle: AppText.body(_isActive ? AppStrings.active : AppStrings.inactive, fontSize: 12.sp, color: AppColors.textSecondary),
                onChanged: (val) => setState(() => _isActive = val),
              ),
              SizedBox(height: 24.h),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    text: AppStrings.saveChanges,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
