import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../cubit/moderation_cubit.dart';
import '../cubit/moderation_state.dart';

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
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 480.w,
        padding: EdgeInsets.all(24.r),
        child: BlocConsumer<ModerationCubit, ModerationState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.successMessage!), backgroundColor: AppColors.success),
              );
              Navigator.of(context).pop(true);
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.danger),
              );
            }
          },
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gavel_rounded, color: AppColors.danger),
                      SizedBox(width: 10.w),
                      AppText.heading(AppStrings.reportUserBanTitle, fontSize: 18.sp),
                    ],
                  ),
                  if (widget.userName != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      AppStrings.customerLabel(widget.userName!),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  Text(
                    AppStrings.mainBanReason,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    dropdownColor: AppColors.cardBackground,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.mutedBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: AppColors.borderDefault)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: AppColors.borderDefault)),
                    ),
                    items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
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
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: AppStrings.cancel,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: 12.w),
                      AppButton(
                        text: state.isSubmitting ? AppStrings.sending : AppStrings.sendBanReport,
                        backgroundColor: AppColors.danger,
                        onPressed: state.isSubmitting
                            ? null
                            : () {
                                context.read<ModerationCubit>().createBanRequest(
                                      loungeId: widget.loungeId,
                                      userId: widget.userId,
                                      bookingId: widget.bookingId,
                                      reason: _selectedReason,
                                      evidenceNotes: _evidenceController.text.trim().isNotEmpty
                                          ? _evidenceController.text.trim()
                                          : null,
                                    );
                              },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
