import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';

class RedemptionOptionDialog extends StatefulWidget {
  final RedemptionOptionEntity? option;
  final Function(RedemptionOptionEntity) onSave;

  const RedemptionOptionDialog({super.key, this.option, required this.onSave});

  @override
  State<RedemptionOptionDialog> createState() => _RedemptionOptionDialogState();
}

class _RedemptionOptionDialogState extends State<RedemptionOptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleArController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _descArController;
  late final TextEditingController _descEnController;
  late final TextEditingController _pointsCostController;
  late final TextEditingController _rewardValueController;
  String _rewardType = 'discount_fixed';

  @override
  void initState() {
    super.initState();
    _titleArController = TextEditingController(text: widget.option?.titleAr);
    _titleEnController = TextEditingController(text: widget.option?.titleEn);
    _descArController = TextEditingController(text: widget.option?.descriptionAr);
    _descEnController = TextEditingController(text: widget.option?.descriptionEn);
    _pointsCostController = TextEditingController(text: widget.option?.pointsCost.toString() ?? '');
    _rewardValueController = TextEditingController(text: widget.option?.rewardValue.toString() ?? '');
    _rewardType = widget.option?.rewardType ?? 'discount_fixed';
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _pointsCostController.dispose();
    _rewardValueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(RedemptionOptionEntity(
        id: widget.option?.id ?? '',
        titleAr: _titleArController.text.trim(),
        titleEn: _titleEnController.text.trim(),
        descriptionAr: _descArController.text.trim(),
        descriptionEn: _descEnController.text.trim(),
        pointsCost: int.tryParse(_pointsCostController.text.trim()) ?? 0,
        rewardType: _rewardType,
        rewardValue: _rewardType == 'discount_fixed'
            ? (double.tryParse(_rewardValueController.text.trim()) ?? 0.0)
            : 0.0,
        isActive: widget.option?.isActive ?? true,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: widget.option == null ? AppStrings.addReward : AppStrings.editReward,
      icon: Icons.card_giftcard_rounded,
      width: 600.w,
      actions: [
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _titleArController,
                    label: AppStrings.nameAr,
                    validator: (v) => v?.trim().isEmpty == true ? AppStrings.fieldRequired : null,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    controller: _titleEnController,
                    label: AppStrings.nameEn,
                    validator: (v) => v?.trim().isEmpty == true ? AppStrings.fieldRequired : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _descArController,
              label: AppStrings.descriptionArLabel,
              maxLines: 2,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _descEnController,
              label: AppStrings.descriptionEnLabel,
              maxLines: 2,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _pointsCostController,
                    label: AppStrings.pointsCost,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
                      final val = int.tryParse(v.trim());
                      if (val == null || val <= 0) return AppStrings.invalidNumber;
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.rewardType,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      DropdownButtonFormField<String>(
                        initialValue: _rewardType,
                        dropdownColor: AppColors.cardBackground,
                        items: [
                          DropdownMenuItem(
                            value: 'discount_fixed',
                            child: Text(
                              AppStrings.directDiscount,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'free_hour',
                            child: Text(
                              AppStrings.playHours,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _rewardType = v);
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.scaffoldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_rewardType == 'discount_fixed') ...[
              SizedBox(height: 16.h),
              AppTextField(
                controller: _rewardValueController,
                label: AppStrings.rewardValue,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
                  final val = double.tryParse(v.trim());
                  if (val == null || val < 0) return AppStrings.invalidNumber;
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
