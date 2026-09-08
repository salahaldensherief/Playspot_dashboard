import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class AddLoungeAdminDialog extends StatefulWidget {
  final bool isLoading;
  final Function(String email, String password, String name, String loungeName)? onSave;

  const AddLoungeAdminDialog({
    super.key, 
    this.isLoading = false,
    this.onSave,
  });

  @override
  State<AddLoungeAdminDialog> createState() => _AddLoungeAdminDialogState();
}

class _AddLoungeAdminDialogState extends State<AddLoungeAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loungeNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _loungeNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.onSave != null) {
        widget.onSave!(
          _emailController.text.trim(),
          _passwordController.text.trim().isEmpty ? 'LoungeOwner@123' : _passwordController.text.trim(),
          _nameController.text.trim(),
          _loungeNameController.text.trim(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: "Create Lounge & Owner",
      width: 550.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: "Create Lounge & Owner",
          isLoading: widget.isLoading,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.subHeading("1. Lounge Details", fontSize: 15.sp, color: AppColors.neonPurple),
              SizedBox(height: 12.h),
              AppTextField(
                label: AppStrings.loungeName,
                hintText: AppStrings.loungeNameHint,
                controller: _loungeNameController,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 20.h),
              const Divider(color: AppColors.divider),
              SizedBox(height: 16.h),
              AppText.subHeading("2. Owner Details", fontSize: 15.sp, color: AppColors.neonBlue),
              SizedBox(height: 12.h),
              AppTextField(
                label: AppStrings.fullName,
                hintText: AppStrings.ownerNameHint,
                controller: _nameController,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                label: AppStrings.email,
                hintText: AppStrings.ownerEmailHint,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidator.validateEmail,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                label: AppStrings.password,
                hintText: AppStrings.passwordHint,
                controller: _passwordController,
                isPassword: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
