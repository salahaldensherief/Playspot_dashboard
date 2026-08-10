import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../cubit/admin_management_cubit.dart';
import '../cubit/admin_management_state.dart';

class AddLoungeAdminDialog extends StatefulWidget {
  const AddLoungeAdminDialog({super.key});

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
      context.read<AdminManagementCubit>().createLoungeAdmin(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        loungeName: _loungeNameController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminManagementCubit, AdminManagementState>(
      listener: (context, state) {
        if (state is AdminManagementSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.adminCreatedSuccess), backgroundColor: AppColors.success),
          );
          Navigator.pop(context);
        } else if (state is AdminManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
          );
        }
      },
      child: Dialog(
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
                  Divider(color: AppColors.divider),
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
                      BlocBuilder<AdminManagementCubit, AdminManagementState>(
                        builder: (context, state) {
                          return AppButton(
                            text: AppStrings.createAdmin,
                            isLoading: state is AdminManagementLoading,
                            onPressed: _submit,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
