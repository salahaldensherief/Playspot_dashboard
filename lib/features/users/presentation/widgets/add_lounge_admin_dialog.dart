import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 500.w,
        padding: EdgeInsets.all(32.r),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.addLoungeAdmin,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                SizedBox(height: 24.h),
                AppTextField(
                  label: AppStrings.fullName,
                  hintText: 'Enter owner name',
                  controller: _nameController,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  label: AppStrings.email,
                  hintText: 'owner@lounge.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  label: AppStrings.password,
                  hintText: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (val) => val == null || val.length < 6 ? 'Too short' : null,
                ),
                SizedBox(height: 24.h),
                const Divider(color: AppColors.divider),
                SizedBox(height: 24.h),
                AppTextField(
                  label: AppStrings.loungeName,
                  hintText: 'e.g. Nova Gaming',
                  controller: _loungeNameController,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  label: AppStrings.city,
                  hintText: 'e.g. Cairo',
                  controller: _cityController,
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
                      text: AppStrings.createAdmin,
                      isLoading: widget.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
