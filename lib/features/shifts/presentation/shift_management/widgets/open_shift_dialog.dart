import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../shift_cubit.dart';

class OpenShiftDialog extends StatefulWidget {
  final String loungeId;
  final ShiftCubit cubit;

  const OpenShiftDialog({
    super.key,
    required this.loungeId,
    required this.cubit,
  });

  @override
  State<OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<OpenShiftDialog> {
  final _cashController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        AppStrings.openNewShift,
        style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Orbitron', fontSize: 20.sp),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _cashController,
              label: AppStrings.startingCash,
              hintText: "0.00",
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return AppStrings.fieldRequired;
                if (double.tryParse(val) == null) return AppStrings.invalidNumber;
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        AppButton(
          text: AppStrings.openNewShift,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.cubit.openShift(
                loungeId: widget.loungeId,
                startingCash: double.parse(_cashController.text),
              );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
