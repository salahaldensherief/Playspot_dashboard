import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../cubit/moderation_cubit.dart';
import '../cubit/moderation_state.dart';
import 'moderation_reason_label.dart';

class ReportUserBanDialog extends StatefulWidget {
  final String loungeId;
  final String userId;
  final String? bookingId;
  final String? userName;

  const ReportUserBanDialog({
    super.key,
    required this.loungeId,
    required this.userId,
    this.bookingId,
    this.userName,
  });

  @override
  State<ReportUserBanDialog> createState() => _ReportUserBanDialogState();
}

class _ReportUserBanDialogState extends State<ReportUserBanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _evidenceController = TextEditingController();
  String _selectedReason = 'سلوك غير لائق وتخريب';

  final List<String> _reasons = [
    'سلوك غير لائق وتخريب',
    'عدم الحضور وتخلف متكرر (No-Show)',
    'تزوير إيصال الدفع / احتيال',
    'إزعاج العملاء الآخرين والاعتداء اللفظي',
    'أخرى',
  ];

  @override
  void dispose() {
    _evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return BlocConsumer<ModerationCubit, ModerationState>(
      listenWhen: (previous, current) =>
          previous.successMessage != current.successMessage ||
          previous.errorMessage != current.errorMessage,
      buildWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting,
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage?.tr() ?? ''),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage?.tr() ?? ''),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        return AppDialog(
          title: AppStrings.reportUserBanTitle,
          width: 500.w,
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
                  : AppStrings.sendBanReport,
              backgroundColor: AppColors.danger,
              onPressed: state.isSubmitting
                  ? null
                  : () {
                      context.read<ModerationCubit>().createBanRequest(
                            loungeId: widget.loungeId,
                            userId: widget.userId,
                            bookingId: widget.bookingId,
                            reason: _selectedReason,
                            evidenceNotes:
                                _evidenceController.text.trim().isNotEmpty
                                    ? _evidenceController.text.trim()
                                    : null,
                          );
                    },
            ),
          ],
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.userName != null && widget.userName!.isNotEmpty) ...[
                  Text(
                    AppStrings.customerLabel(widget.userName ?? ''),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
                Text(
                  AppStrings.mainBanReason,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  dropdownColor: AppColors.cardBackground,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.mutedBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(
                        color: AppColors.borderDefault,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(
                        color: AppColors.borderDefault,
                      ),
                    ),
                  ),
                  items: _reasons
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(moderationReasonLabel(r)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  label: AppStrings.evidenceDetailsOptional,
                  controller: _evidenceController,
                  hintText: AppStrings.violationDetailsHint,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
