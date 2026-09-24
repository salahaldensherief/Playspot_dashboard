import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class AddBranchDialog extends StatefulWidget {
  final String? brandId;
  final Future<void> Function(Map<String, dynamic> branchData)? onSave;

  const AddBranchDialog({super.key, this.brandId, this.onSave});

  @override
  State<AddBranchDialog> createState() => _AddBranchDialogState();
}

class _AddBranchDialogState extends State<AddBranchDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _locationController = TextEditingController();
  final _opensAtController = TextEditingController(text: '10:00');
  final _closesAtController = TextEditingController(text: '02:00');

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _branchNameController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    _opensAtController.dispose();
    _closesAtController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isLoading = true);

    try {
      final branchData = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (_branchNameController.text.trim().isNotEmpty)
          'branch_name': _branchNameController.text.trim(),
        if (widget.brandId != null && (widget.brandId ?? '').isNotEmpty)
          'brand_id': widget.brandId,
        if (_cityController.text.trim().isNotEmpty)
          'city': _cityController.text.trim(),
        if (_locationController.text.trim().isNotEmpty)
          'location': _locationController.text.trim(),
        if (_opensAtController.text.trim().isNotEmpty)
          'opening_time': _opensAtController.text.trim(),
        if (_closesAtController.text.trim().isNotEmpty)
          'closing_time': _closesAtController.text.trim(),
      };

      if (widget.onSave != null) {
        await widget.onSave!(branchData);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.operationError(e.toString())),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppStrings.addNewBranch,
      width: 540.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: AppStrings.saveChanges,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: AppStrings.branchName,
              hintText: AppStrings.branchNameHint,
              controller: _nameController,
              validator: AppValidator.validateRequired,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: AppStrings.branchName,
              hintText: AppStrings.branchNameHint,
              controller: _branchNameController,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: AppStrings.city,
                    controller: _cityController,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    label: AppStrings.address,
                    controller: _locationController,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: AppStrings.opensAt,
                    hintText: AppStrings.timeHint,
                    controller: _opensAtController,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    label: AppStrings.closesAt,
                    hintText: AppStrings.timeHint,
                    controller: _closesAtController,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
