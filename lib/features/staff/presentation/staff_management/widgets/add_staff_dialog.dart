import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:play_spot_dashboard/features/staff/data/entities/staff_entity.dart';
import 'package:play_spot_dashboard/features/staff/data/models/staff_params.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_cubit.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_state.dart';

class AddStaffDialog extends StatefulWidget {
  final String loungeId;
  final StaffCubit cubit; // Explicitly pass the cubit
  final StaffEntity? staff;

  const AddStaffDialog({super.key, required this.loungeId, required this.cubit, this.staff});

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late String _selectedRole;

  bool get isEdit => widget.staff != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff?.name);
    _emailController = TextEditingController(text: widget.staff?.email);
    _phoneController = TextEditingController(text: widget.staff?.phone);
    _passwordController = TextEditingController();
    _selectedRole = widget.staff?.role ?? 'cashier';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffCubit, StaffState>(
      bloc: widget.cubit, // Use the explicitly passed cubit instance
      listener: (context, state) {
        if (state.status.isSuccess) {
          Navigator.pop(context);
        }
        if (state.status.isFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Dialog(
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
                  isEdit ? AppStrings.editStaff : AppStrings.addStaff,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
                ),
                SizedBox(height: 24.h),
                AppTextField(
                  label: AppStrings.staffName,
                  controller: _nameController,
                  validator: AppValidator.validateRequired,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.email,
                        controller: _emailController,
                        validator: AppValidator.validateEmail,
                        readOnly: isEdit, // Email usually shouldn't be edited if it's the auth ID
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.staffPhone,
                        controller: _phoneController,
                        validator: AppValidator.validateRequired,
                      ),
                    ),
                  ],
                ),
                if (!isEdit) ...[
                  SizedBox(height: 16.h),
                  AppTextField(
                    label: AppStrings.tempPassword,
                    controller: _passwordController,
                    validator: (v) => (v?.length ?? 0) < 6 ? AppStrings.passwordTooShort : null,
                    isPassword: true,
                  ),
                ],
                SizedBox(height: 24.h),
                Text(
                  AppStrings.roleLabel,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12.h),
                _buildRoleSelection(),
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
                      text: isEdit ? AppStrings.saveChanges : AppStrings.addStaff,
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

  Widget _buildRoleSelection() {
    return Row(
      children: [
        _RoleChip(
          label: AppStrings.cashierLabel,
          isSelected: _selectedRole == 'cashier',
          onTap: () => setState(() => _selectedRole = 'cashier'),
        ),
        SizedBox(width: 12.w),
        _RoleChip(
          label: AppStrings.manager,
          isSelected: _selectedRole == 'lounge_owner',
          onTap: () => setState(() => _selectedRole = 'lounge_owner'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (isEdit) {
        widget.cubit.updateStaffMember(
          widget.staff!.id,
          {
            'name': _nameController.text,
            'phone': _phoneController.text,
            'role': _selectedRole,
          },
          widget.loungeId,
        );
      } else {
        widget.cubit.addStaffMember(
          AddStaffParams(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            password: _passwordController.text,
            role: _selectedRole,
            loungeId: widget.loungeId,
          ),
        );
      }
    }
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonBlue.withOpacity(0.1) : AppColors.mutedBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: isSelected ? AppColors.neonBlue : AppColors.borderDefault),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
