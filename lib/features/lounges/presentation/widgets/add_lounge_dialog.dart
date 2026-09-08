import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class AddLoungeDialog extends StatefulWidget {
  final bool isLoading;
  final Future<void> Function({
    required String loungeName,
    String? address,
    String? phone,
    required String ownerName,
    required String ownerEmail,
    String? ownerPhone,
    String? ownerPassword,
  })? onSave;

  const AddLoungeDialog({
    super.key, 
    this.isLoading = false,
    this.onSave,
  });

  @override
  State<AddLoungeDialog> createState() => _AddLoungeDialogState();
}

class _AddLoungeDialogState extends State<AddLoungeDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Lounge Details Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Owner Details Controllers
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLocalUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _ownerPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLocalUploading = true);
      
      try {
        if (widget.onSave != null) {
          await widget.onSave!(
            loungeName: _nameController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            ownerEmail: _emailController.text.trim(),
            ownerPhone: _ownerPhoneController.text.trim().isEmpty ? null : _ownerPhoneController.text.trim(),
            ownerPassword: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
          );
        }
        
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        if (mounted) setState(() => _isLocalUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: "Create Lounge & Owner",
      width: 650.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: "Create Lounge & Owner",
          isLoading: widget.isLoading || _isLocalUploading,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section 1: Lounge Details ---
              AppText.subHeading("1. Lounge Details", fontSize: 16.sp, color: AppColors.neonPurple),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.loungeName,
                      hintText: AppStrings.loungeNameHint,
                      controller: _nameController,
                      validator: AppValidator.validateRequired,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      label: "Contact Phone",
                      hintText: "Lounge phone number",
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 28.h),
              const Divider(color: AppColors.divider),
              SizedBox(height: 20.h),

              // --- Section 2: Owner Details ---
              AppText.subHeading("2. Owner Details", fontSize: 16.sp, color: AppColors.neonBlue),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.ownerName,
                      hintText: AppStrings.ownerNameHint,
                      controller: _ownerNameController,
                      validator: AppValidator.validateRequired,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.ownerEmail,
                      hintText: AppStrings.emailHint,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: AppValidator.validateEmail,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: "Owner Phone",
                      hintText: "Owner mobile number",
                      controller: _ownerPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.ownerPassword,
                      hintText: AppStrings.passwordHint,
                      controller: _passwordController,
                      isPassword: true,
                    ),
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
