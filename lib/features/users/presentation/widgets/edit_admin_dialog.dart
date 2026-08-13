import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';

class EditAdminDialog extends StatefulWidget {
  final UserEntity admin;
  final bool isLoading;
  final Function(String name, String email)? onSave;

  const EditAdminDialog({
    super.key,
    required this.admin,
    this.isLoading = false,
    this.onSave,
  });

  @override
  State<EditAdminDialog> createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends State<EditAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.admin.name);
    _emailController = TextEditingController(text: widget.admin.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.onSave != null) {
        widget.onSave!(
          _nameController.text,
          _emailController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Edit Administrator',
      width: 500.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: 'Save Changes',
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
              controller: _nameController,
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: AppStrings.email,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
            ),
          ],
        ),
      ),
    );
  }
}
