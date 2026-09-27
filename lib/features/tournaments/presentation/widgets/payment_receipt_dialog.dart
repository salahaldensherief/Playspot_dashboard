import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_cached_image.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../domain/entities/tournament_participant_entity.dart';

class PaymentReceiptDialog extends StatefulWidget {
  final TournamentParticipantEntity participant;
  final VoidCallback onApprove;
  final Function(String reason) onReject;

  const PaymentReceiptDialog({
    super.key,
    required this.participant,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<PaymentReceiptDialog> createState() => _PaymentReceiptDialogState();
}

class _PaymentReceiptDialogState extends State<PaymentReceiptDialog> {
  final _reasonController = TextEditingController();
  bool _showRejectInput = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleConfirmReject() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.reasonRequired),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    widget.onReject(reason);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;

    return AppDialog(
      title: '${AppStrings.reviewReceipt} - ${p.userName}',
      width: 550.w,
      actions: [
        AppButton(
          text: AppStrings.close,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        if (!_showRejectInput) ...[
          SizedBox(width: 12.w),
          AppButton(
            text: AppStrings.rejectPayment,
            variant: AppButtonVariant.danger,
            onPressed: () => setState(() => _showRejectInput = true),
          ),
          SizedBox(width: 12.w),
          AppButton(
            text: AppStrings.approvePayment,
            backgroundColor: AppColors.success,
            onPressed: () {
              widget.onApprove();
              Navigator.pop(context);
            },
          ),
        ] else ...[
          SizedBox(width: 12.w),
          AppButton(
            text: AppStrings.rejectPayment,
            variant: AppButtonVariant.danger,
            onPressed: _handleConfirmReject,
          ),
        ],
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${AppStrings.customerName}: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
              Text(p.userName, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (p.userPhone != null) Text(p.userPhone!, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          Text(AppStrings.reviewReceipt, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Container(
            height: 320.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            clipBehavior: Clip.antiAlias,
            child: (p.signedReceiptUrl != null && p.signedReceiptUrl!.isNotEmpty)
                ? AppCachedImage(
                    imageUrl: p.signedReceiptUrl!,
                    fit: BoxFit.contain,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 48.r, color: AppColors.textSecondary),
                        SizedBox(height: 8.h),
                        Text(
                          AppStrings.noPromotions,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_showRejectInput) ...[
            SizedBox(height: 20.h),
            AppTextField(
              controller: _reasonController,
              label: AppStrings.reasonOrNote,
              hintText: AppStrings.reasonHint,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }
}
