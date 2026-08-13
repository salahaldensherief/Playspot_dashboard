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
  String _selectedIcon = 'sports_esports';

  final List<Map<String, dynamic>> _availableIcons = [
    {'key': 'sports_esports', 'icon': Icons.sports_esports},
    {'key': 'videogame_asset', 'icon': Icons.videogame_asset},
    {'key': 'local_cafe', 'icon': Icons.local_cafe},
    {'key': 'fastfood', 'icon': Icons.fastfood},
    {'key': 'games', 'icon': Icons.games},
    {'key': 'tv', 'icon': Icons.tv},
    {'key': 'personal_video', 'icon': Icons.personal_video},
    {'key': 'headset', 'icon': Icons.headset},
    {'key': 'mouse', 'icon': Icons.mouse},
    {'key': 'groups', 'icon': Icons.groups},
    {'key': 'star', 'icon': Icons.star},
    {'key': 'celebration', 'icon': Icons.celebration},
  ];

  @override
  void initState() {
    super.initState();
    _nameAr = TextEditingController(text: widget.category?.nameAr);
    _nameEn = TextEditingController(text: widget.category?.nameEn);
    _selectedIcon = widget.category?.iconKey ?? 'sports_esports';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final category = CategoryEntity(
        id: widget.category?.id ?? '',
        nameAr: _nameAr.text,
        nameEn: _nameEn.text,
        iconKey: _selectedIcon,
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
              SizedBox(height: 24.h),
              Text(
                AppStrings.promoIcon, // أو نستخدم "Category Icon"
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Wrap(
                  spacing: 16.r,
                  runSpacing: 16.r,
                  children: _availableIcons.map((item) {
                    final bool isSelected = _selectedIcon == item['key'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = item['key']),
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.neonBlue.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isSelected ? AppColors.neonBlue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          item['icon'],
                          color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
                          size: 24.r,
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
