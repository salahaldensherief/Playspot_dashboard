import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:uuid/uuid.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../cubit/extras_cubit.dart';
import '../../domain/entities/extra_entity.dart';

class AddExtraDialog extends StatefulWidget {
  final String loungeId;
  const AddExtraDialog({super.key, required this.loungeId});

  @override
  State<AddExtraDialog> createState() => _AddExtraDialogState();
}

class _AddExtraDialogState extends State<AddExtraDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Drinks';

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final extra = ExtraEntity(
        id: const Uuid().v4(),
        loungeId: widget.loungeId,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        category: _selectedCategory,
        isOutOfStock: false,
      );

      try {
        context.read<ExtrasCubit>().addExtra(extra);
      } catch (e) {
        context.read<OnboardingCubit>().addNewExtra(extra);
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
        width: 450.w,
        padding: EdgeInsets.all(32.r),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.heading(AppStrings.addExtraItem, fontSize: 24.sp),
              SizedBox(height: 24.h),
              AppTextField(
                label: AppStrings.itemName,
                hintText: AppStrings.addItemHint,
                controller: _nameController,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.priceEgp,
                hintText: AppStrings.priceHint,
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16.h),
              AppText.body(AppStrings.category, fontSize: 12.sp),
              SizedBox(height: 8.h),
              _buildCategoryDropdown(),
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
                    text: AppStrings.addItem,
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

  Widget _buildCategoryDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.divider.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
          items: [
            DropdownMenuItem(value: 'Drinks', child: Text(AppStrings.drinks)),
            DropdownMenuItem(value: 'Snacks', child: Text(AppStrings.snacks)),
            DropdownMenuItem(value: 'Services', child: Text(AppStrings.services)),
            DropdownMenuItem(value: 'Others', child: Text(AppStrings.others)),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
        ),
      ),
    );
  }
}
