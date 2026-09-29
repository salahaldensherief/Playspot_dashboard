import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/data_table_widget.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/status_badge.dart';

import '../../domain/entities/referral_entity.dart';

class ReferralsTab extends StatelessWidget {
  final List<ReferralEntity> referrals;

  const ReferralsTab({super.key, required this.referrals});

  @override
  Widget build(BuildContext context) {
    if (referrals.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      child: DataTableWidget(
        columns: [
          AppStrings.inviter,
          AppStrings.invitee,
          AppStrings.referralDate,
          AppStrings.referralStatus,
          AppStrings.rewardIssued,
          AppStrings.inviterPoints,
          AppStrings.inviteePoints,
        ],
        rows: referrals.map((ref) {
          final formattedDate = ref.createdAt != null
              ? DateFormat('yyyy-MM-dd hh:mm a').format(ref.createdAt!)
              : '--';

          final isCompleted = ref.status == 'completed';

          return DataRow(
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(ref.inviterName, fontWeight: FontWeight.bold),
                    AppText.body(
                      ref.inviterEmail,
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(ref.inviteeName, fontWeight: FontWeight.bold),
                    AppText.body(
                      ref.inviteeEmail,
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              DataCell(AppText.body(formattedDate, fontSize: 13.sp)),
              DataCell(
                StatusBadge(
                  text: isCompleted ? AppStrings.completed : AppStrings.pending,
                  color: isCompleted ? AppColors.success : AppColors.warning,
                ),
              ),
              DataCell(
                StatusBadge(
                  text: ref.rewardIssued
                      ? AppStrings.rewardIssuedYes
                      : AppStrings.rewardIssuedNo,
                  color: ref.rewardIssued
                      ? AppColors.neonBlue
                      : AppColors.textSecondary,
                ),
              ),
              DataCell(
                AppText.body(
                  '+${ref.inviterPoints} ${AppStrings.pointsUnit}',
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DataCell(
                AppText.body(
                  '+${ref.inviteePoints} ${AppStrings.pointsUnit}',
                  color: AppColors.neonBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            color: AppColors.textSecondary,
            size: 64.r,
          ),
          SizedBox(height: 16.h),
          AppText.body(AppStrings.noResultsMatching, fontSize: 18.sp),
        ],
      ),
    );
  }
}
