import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:uuid/uuid.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../cubit/extras_cubit.dart';
import '../../domain/entities/extra_entity.dart';

class ExtraDialog extends StatefulWidget {
  final String loungeId;
  final ExtraEntity? extra;
  const ExtraDialog({super.key, required this.loungeId, this.extra});

  @override
  State<ExtraDialog> createState() => _ExtraDialogState();
}

class _ExtraDialogState extends State<ExtraDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  String _selectedCategory = 'Drinks';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.extra?.name);
    _priceController = TextEditingController(text: widget.extra?.price.toString());
    _selectedCategory = widget.extra?.category ?? 'Drinks';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final extra = ExtraEntity(
        id: widget.extra?.id ?? const Uuid().v4(),
        loungeId: widget.loungeId,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        category: _selectedCategory,
        isOutOfStock: widget.extra?.isOutOfStock ?? false,
      );

      if (widget.extra == null) {
        try {
          context.read<ExtrasCubit>().addExtra(extra);
        } catch (e) {
          context.read<OnboardingCubit>().addNewExtra(extra);
        }
      } else {
        // TODO: Implement updateExtra in Cubit
        // context.read<ExtrasCubit>().updateExtra(extra);
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
              AppText.heading(
                widget.extra == null ? AppStrings.addExtraItem : 'Edit Item', 
                fontSize: 24.sp
              ),
              SizedBox(height: 24.h),
              AppTextField(
                label: AppStrings.itemName,
                hintText: AppStrings.addItemHint,
                controller: _nameController,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.priceEgp,
                hintText: AppStrings.priceHint,
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: AppValidator.validateNumber,
              ),
              SizedBox(height: 16.h),
              CustomDropdown<String>(
                label: AppStrings.category,
                value: _selectedCategory,
                items: const ['Drinks', 'Snacks', 'Services', 'Others'],
                itemLabel: (s) {
                  switch (s) {
                    case 'Drinks': return AppStrings.drinks;
                    case 'Snacks': return AppStrings.snacks;
                    case 'Services': return AppStrings.services;
                    default: return AppStrings.others;
                  }
                },
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
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
                    text: widget.extra == null ? AppStrings.addItem : 'Update Item',
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
