import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:uuid/uuid.dart';
import '../../../data/entities/city_entity.dart';

class CityDialog extends StatefulWidget {
  final CityEntity? city;
  final Function(CityEntity) onSave;

  const CityDialog({super.key, this.city, required this.onSave});

  @override
  State<CityDialog> createState() => _CityDialogState();
}

class _CityDialogState extends State<CityDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameArController = TextEditingController(text: widget.city?.nameAr);
    _nameEnController = TextEditingController(text: widget.city?.nameEn);
    _isActive = widget.city?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(CityEntity(
        id: widget.city?.id ?? const Uuid().v4(),
        nameAr: _nameArController.text,
        nameEn: _nameEnController.text,
        isActive: _isActive,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 450.w,
        padding: EdgeInsets.all(32.r),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.city == null ? 'Add City' : 'Edit City',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24.h),
              AppTextField(
                label: AppStrings.nameAr,
                hintText: 'الاسم بالعربية',
                controller: _nameArController,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.nameEn,
                hintText: 'City Name (English)',
                controller: _nameEnController,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v ?? true),
                    activeColor: AppColors.neonBlue,
                  ),
                  Text('Is Active', style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp)),
                ],
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
