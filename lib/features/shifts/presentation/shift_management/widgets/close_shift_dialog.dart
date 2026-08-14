import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:play_spot_dashboard/features/shifts/data/models/shift_params.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';

class CloseShiftDialog extends StatefulWidget {
  const CloseShiftDialog({super.key});

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShiftCubit, ShiftState>(
      listener: (context, state) {
        if (state.status.isClosed) {
          Navigator.pop(context);
        }
      },
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 400.w,
          padding: EdgeInsets.all(32.r),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.closeShift,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24.h),
                AppTextField(
                  label: AppStrings.actualCash,
                  hintText: '0.00',
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  validator: AppValidator.validateRequired,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  label: AppStrings.notes,
                  hintText: 'Notes...',
                  controller: _notesController,
                  maxLines: 2,
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
                      text: AppStrings.closeShift,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final activeShift = context.read<ShiftCubit>().state.activeShift;
                          if (activeShift != null) {
                            context.read<ShiftCubit>().closeShift(
                              CloseShiftParams(
                                shiftId: activeShift.id,
                                actualCash: double.parse(_cashController.text),
                                notes: _notesController.text,
                              ),
                            );
                          }
                        }
                      },
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
