import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(widget.option == null ? AppStrings.addReward : AppStrings.editReward, style: const TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 600.w,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: AppTextField(
                      controller: _titleArController,
                      label: AppStrings.nameAr,
                      validator: (v) => v?.isEmpty == true ? AppStrings.fieldRequired : null,
                    )),
                    SizedBox(width: 16.w),
                    Expanded(child: AppTextField(
                      controller: _titleEnController,
                      label: AppStrings.nameEn,
                      validator: (v) => v?.isEmpty == true ? AppStrings.fieldRequired : null,
                    )),
                  ],
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _descArController,
                  label: "Description (Arabic)",
                  maxLines: 2,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _descEnController,
                  label: "Description (English)",
                  maxLines: 2,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: AppTextField(
                      controller: _pointsCostController,
                      label: AppStrings.pointsCost,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                        final val = int.tryParse(v);
                        if (val == null || val <= 0) return AppStrings.invalidNumber;
                        return null;
                      },
                    )),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.rewardType, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                          SizedBox(height: 8.h),
                          DropdownButtonFormField<String>(
                            value: _rewardType,
                            dropdownColor: AppColors.cardBackground,
                            items: const [
                              DropdownMenuItem(value: 'discount_fixed', child: Text('Fixed Discount', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: 'free_hour', child: Text('Free Hour', style: TextStyle(color: AppColors.textPrimary))),
                            ],
                            onChanged: (v) => setState(() => _rewardType = v!),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.scaffoldBackground,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
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
                      if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return AppStrings.invalidNumber;
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
        AppButton(
          text: AppStrings.saveChanges,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(RedemptionOptionEntity(
                id: widget.option?.id ?? '',
                titleAr: _titleArController.text,
                titleEn: _titleEnController.text,
                descriptionAr: _descArController.text,
                descriptionEn: _descEnController.text,
                pointsCost: int.parse(_pointsCostController.text),
                rewardType: _rewardType,
                rewardValue: _rewardType == 'discount_fixed' ? double.parse(_rewardValueController.text) : 0,
                isActive: widget.option?.isActive ?? true,
              ));
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
