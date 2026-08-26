import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../../../domain/entities/shift_entity.dart';
import '../shift_cubit.dart';

class CloseShiftDialog extends StatefulWidget {
  final ShiftEntity shift;
  final ShiftCubit cubit;
  final String loungeId;

  const CloseShiftDialog({
    super.key,
    required this.shift,
    required this.cubit,
    required this.loungeId,
  });

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final _actualCashController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _actualCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        AppStrings.closeShift,
        style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Orbitron', fontSize: 20.sp),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppStrings.expectedCash}: ${widget.shift.expectedCash ?? 0.0} ${AppStrings.egp}",
              style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _actualCashController,
              label: AppStrings.actualCash,
              hintText: "0.00",
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return AppStrings.fieldRequired;
                if (double.tryParse(val) == null) return AppStrings.invalidNumber;
                return null;
              },
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _notesController,
              label: AppStrings.notes,
              hintText: "Any remarks...",
              maxLines: 2,
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
          text: AppStrings.closeShift,
          variant: AppButtonVariant.danger,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.cubit.closeShift(
                shiftId: widget.shift.id,
                actualCash: double.parse(_actualCashController.text),
                notes: _notesController.text,
                loungeId: widget.loungeId,
              );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
