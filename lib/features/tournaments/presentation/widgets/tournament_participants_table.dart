import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/status_badge.dart';
import '../../domain/entities/tournament_participant_entity.dart';
import 'payment_receipt_dialog.dart';

class TournamentParticipantsTable extends StatelessWidget {
  final List<TournamentParticipantEntity> participants;
  final Function(TournamentParticipantEntity) onApprovePayment;
  final Function(TournamentParticipantEntity, String reason) onRejectPayment;
  final Function(TournamentParticipantEntity) onRecordCash;
  final Function(TournamentParticipantEntity) onCheckIn;

  const TournamentParticipantsTable({
    super.key,
    required this.participants,
    required this.onApprovePayment,
    required this.onRejectPayment,
    required this.onRecordCash,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40.r),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48.r, color: AppColors.textSecondary),
              SizedBox(height: 12.h),
              Text(
                AppStrings.noPromotions,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
          dataRowHeight: 64.h,
          columns: [
            DataColumn(label: Text(AppStrings.customerName, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp))),
            DataColumn(label: Text(AppStrings.phoneNumber, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp))),
            DataColumn(label: Text(AppStrings.payment, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp))),
            DataColumn(label: Text(AppStrings.checkIn, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp))),
            DataColumn(label: Text(AppStrings.date, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp))),
            DataColumn(label: Text(AppStrings.actions, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp))),
          ],
          rows: participants.map((p) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.neonBlue.withAlpha(40),
                        child: Text(
                          p.userName.isNotEmpty ? p.userName[0].toUpperCase() : 'P',
                          style: const TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(p.userName, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                DataCell(Text(p.userPhone ?? '--', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp))),
                DataCell(_buildPaymentBadge(p.paymentStatus)),
                DataCell(
                  p.isCheckedIn
                      ? Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                            SizedBox(width: 6.w),
                            Text(AppStrings.attended, style: TextStyle(color: AppColors.success, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Text(AppStrings.unread, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
                ),
                DataCell(Text(dateFormat.format(p.registeredAt), style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp))),
                DataCell(
                  Row(
                    children: [
                      if (p.receiptPath != null && p.receiptPath!.isNotEmpty) ...[
                        AppButton(
                          text: AppStrings.reviewReceipt,
                          variant: AppButtonVariant.outlined,
                          fontSize: 12.sp,
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => PaymentReceiptDialog(
                                participant: p,
                                onApprove: () => onApprovePayment(p),
                                onReject: (reason) => onRejectPayment(p, reason),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8.w),
                      ],
                      if (!p.isPaymentApproved) ...[
                        AppButton(
                          text: AppStrings.cashPayment,
                          variant: AppButtonVariant.primary,
                          fontSize: 12.sp,
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          onPressed: () => onRecordCash(p),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      if (p.isPaymentApproved && !p.isCheckedIn) ...[
                        AppButton(
                          text: AppStrings.checkIn,
                          backgroundColor: AppColors.success,
                          fontSize: 12.sp,
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          onPressed: () => onCheckIn(p),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(ParticipantPaymentStatus status) {
    switch (status) {
      case ParticipantPaymentStatus.approved:
        return StatusBadge(text: AppStrings.approved, color: AppColors.success);
      case ParticipantPaymentStatus.rejected:
        return StatusBadge(text: AppStrings.reject, color: AppColors.danger);
      case ParticipantPaymentStatus.cashPending:
        return StatusBadge(text: AppStrings.pending, color: AppColors.warning);
      case ParticipantPaymentStatus.pending:
      default:
        return StatusBadge(text: AppStrings.pending, color: AppColors.warning);
    }
  }
}
