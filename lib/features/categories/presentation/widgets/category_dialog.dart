import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import '../../domain/entities/category_entity.dart';

class CategoryDialog extends StatefulWidget {
  final CategoryEntity? category;
  final Function(CategoryEntity)? onSave;

  const CategoryDialog({super.key, this.category, this.onSave});

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameAr;
  late TextEditingController _nameEn;
  late TextEditingController _iconKey;

  @override
  void initState() {
    super.initState();
    _nameAr = TextEditingController(text: widget.category?.nameAr);
    _nameEn = TextEditingController(text: widget.category?.nameEn);
    _iconKey = TextEditingController(text: widget.category?.iconKey);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final category = CategoryEntity(
        id: widget.category?.id ?? '',
        nameAr: _nameAr.text,
        nameEn: _nameEn.text,
        iconKey: _iconKey.text,
      );

      if (widget.onSave != null) {
        widget.onSave!(category);
      }
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
        padding: EdgeInsets.all(32.r),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category == null ? AppStrings.addCategory : AppStrings.editCategory, 
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 24.h),
              AppTextField(
                label: AppStrings.nameAr,
                controller: _nameAr,
                hintText: AppStrings.nameAr,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.nameEn,
                controller: _nameEn,
                hintText: AppStrings.nameEn,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.iconKey,
                controller: _iconKey,
                hintText: 'e.g. sports_esports',
              ),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 16.w),
                  AppButton(
                    text: AppStrings.saveCategory,
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
