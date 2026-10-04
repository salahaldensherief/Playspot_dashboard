import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/data_table_widget.dart';
import '../../../../art_core/widgets/status_badge.dart';
import '../../domain/entities/tournament_participant_entity.dart';
import 'payment_receipt_dialog.dart';

class TournamentParticipantsTable extends StatelessWidget {
  final List<TournamentParticipantEntity> participants;
  final Function(TournamentParticipantEntity) onApprovePayment;
  final Function(TournamentParticipantEntity, String reason) onRejectPayment;
  final Function(TournamentParticipantEntity) onRecordCash;
  final Function(TournamentParticipantEntity) onCheckIn;
  final Function(TournamentParticipantEntity)? onWithdraw;
  final VoidCallback? onPromoteWaitlist;

  const TournamentParticipantsTable({
    super.key,
    required this.participants,
    required this.onApprovePayment,
    required this.onRejectPayment,
    required this.onRecordCash,
    required this.onCheckIn,
    this.onWithdraw,
    this.onPromoteWaitlist,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
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
              Icon(
                Icons.people_outline,
                size: 48.r,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 12.h),
              Text(
                AppStrings.users,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd hh:mm a');
    final waitlistCount = participants.where((p) => p.isWaitlist).length;
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onPromoteWaitlist != null || waitlistCount > 0) ...[
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Wrap(
              spacing: 12.w,
              runSpacing: 8.h,
              children: [
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    Text(
                      'tournament_participants_count'.tr(
                        args: [(participants.length).toString()],
                      ),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (waitlistCount > 0) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(30),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Text(
                          'tournament_waitlist_count'.tr(
                            args: [(waitlistCount).toString()],
                          ),
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (onPromoteWaitlist != null && waitlistCount > 0)
                  AppButton(
                    text: 'promote_from_waitlist'.tr(),
                    icon: Icons.arrow_upward_rounded,
                    backgroundColor: AppColors.warning,
                    fontSize: 12.sp,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    onPressed: onPromoteWaitlist!,
                  ),
              ],
            ),
          ),
        ],
        if (isCompact)
          Expanded(
            child: ListView.separated(
              itemCount: participants.length,
              separatorBuilder: (context, index) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final p = participants[index];
                return Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.userName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildPaymentBadge(p.paymentStatus),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        p.userPhone ?? '--',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        dateFormat.format(p.registeredAt),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (p.isWaitlist)
                        Text(
                          AppStrings.waitlistLabel,
                          style: const TextStyle(color: AppColors.warning),
                        ),
                      if (p.isCheckedIn)
                        Text(
                          AppStrings.attended,
                          style: const TextStyle(color: AppColors.success),
                        ),
                      Divider(height: 20.h, color: AppColors.borderDefault),
                      _buildActions(context, p),
                    ],
                  ),
                );
              },
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: DataTableWidget(
                columns: [
                  AppStrings.customerName,
                  AppStrings.phoneNumber,
                  AppStrings.payment,
                  AppStrings.checkIn,
                  AppStrings.date,
                  AppStrings.actions,
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
                                p.userName.isNotEmpty
                                    ? p.userName[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  color: AppColors.neonBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.userName,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (p.isWaitlist)
                                  Text(
                                    AppStrings.waitlistLabel,
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          p.userPhone ?? '--',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      DataCell(_buildPaymentBadge(p.paymentStatus)),
                      DataCell(
                        p.isCheckedIn
                            ? Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    AppStrings.attended,
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                AppStrings.unread,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.sp,
                                ),
                              ),
                      ),
                      DataCell(
                        Text(
                          dateFormat.format(p.registeredAt),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      DataCell(_buildActions(context, p)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, TournamentParticipantEntity p) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        if (p.receiptPath != null && p.receiptPath!.isNotEmpty)
          AppButton(
            text: AppStrings.reviewReceipt,
            variant: AppButtonVariant.outlined,
            fontSize: 12.sp,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => PaymentReceiptDialog(
                participant: p,
                onApprove: () => onApprovePayment(p),
                onReject: (reason) => onRejectPayment(p, reason),
              ),
            ),
          ),
        if (!p.isPaymentApproved)
          AppButton(
            text: AppStrings.cashPayment,
            fontSize: 12.sp,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            onPressed: () => onRecordCash(p),
          ),
        if (p.isPaymentApproved && !p.isCheckedIn)
          AppButton(
            text: AppStrings.checkIn,
            backgroundColor: AppColors.success,
            fontSize: 12.sp,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            onPressed: () => onCheckIn(p),
          ),
        if (onWithdraw != null && !p.isWithdrawn)
          AppButton(
            text: AppStrings.withdraw,
            variant: AppButtonVariant.danger,
            fontSize: 12.sp,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            onPressed: () => onWithdraw!(p),
          ),
      ],
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
        return StatusBadge(text: AppStrings.pending, color: AppColors.warning);
    }
  }
}
