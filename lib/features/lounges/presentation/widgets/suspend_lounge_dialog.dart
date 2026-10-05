import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../../../users/presentation/cubit/moderation_cubit.dart';
import '../../../users/presentation/cubit/moderation_state.dart';

class SuspendLoungeDialog extends StatefulWidget {
  final String loungeId;
  final String loungeName;

  const SuspendLoungeDialog({
    super.key,
    required this.loungeId,
    required this.loungeName,
  });

  @override
  State<SuspendLoungeDialog> createState() => _SuspendLoungeDialogState();
}

class _SuspendLoungeDialogState extends State<SuspendLoungeDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return BlocConsumer<ModerationCubit, ModerationState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage ?? ''),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? ''),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        return AppDialog(
          title: AppStrings.suspendLoungeTitle(widget.loungeName),
          width: 480.w,
          actions: [
            AppButton(
              text: AppStrings.cancel,
              variant: AppButtonVariant.outlined,
              onPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(width: 12.w),
            AppButton(
              text: state.isSubmitting
                  ? AppStrings.sending
                  : AppStrings.confirmSuspension,
              backgroundColor: AppColors.danger,
              onPressed: state.isSubmitting
                  ? null
                  : () {
                      if (_reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.pleaseEnterSuspensionReason,
                            ),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }
                      context.read<ModerationCubit>().suspendLounge(
                            widget.loungeId,
                            reason: _reasonController.text.trim(),
                          );
                    },
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: AppStrings.suspensionReason,
                controller: _reasonController,
                hintText: AppStrings.suspensionReasonHint,
                maxLines: 3,
              ),
            ],
          ),
        );
      },
    );
  }
}
