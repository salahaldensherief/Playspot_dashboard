import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class AddLoungeAdminDialog extends StatefulWidget {
  final bool isLoading;
  final Function(String email, String password, String name, String loungeName, String? city)? onSave;

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
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _loungeNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.onSave != null) {
        widget.onSave!(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
          _loungeNameController.text,
          _cityController.text.isEmpty ? null : _cityController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppStrings.addLoungeAdmin,
      width: 500.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: AppStrings.createAdmin,
          isLoading: widget.isLoading,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: AppStrings.fullName,
              hintText: AppStrings.ownerNameHint,
              controller: _nameController,
              validator: (val) => val == null || val.isEmpty ? AppStrings.fieldRequired : null,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: AppStrings.email,
              hintText: AppStrings.ownerEmailHint,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (val) => val == null || !val.contains('@') ? AppStrings.invalidEmail : null,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: AppStrings.password,
              hintText: AppStrings.passwordHint,
              controller: _passwordController,
              isPassword: true,
              validator: (val) => val == null || val.length < 6 ? AppStrings.passwordTooShort : null,
            ),
            SizedBox(height: 24.h),
            const Divider(color: AppColors.divider),
            SizedBox(height: 24.h),
            AppTextField(
              label: AppStrings.loungeName,
              hintText: AppStrings.loungeNameHint,
              controller: _loungeNameController,
              validator: (val) => val == null || val.isEmpty ? AppStrings.fieldRequired : null,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: AppStrings.city,
              hintText: AppStrings.cityHint,
              controller: _cityController,
            ),
          ],
        ),
      ),
    );
  }
}
