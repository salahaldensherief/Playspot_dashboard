import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
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
      scrollDirection: Axis.vertical,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
            dataRowMaxHeight: 64.h,
            columns: [
              DataColumn(label: AppText.body(AppStrings.inviter, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              DataColumn(label: AppText.body(AppStrings.invitee, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              DataColumn(label: AppText.body(AppStrings.referralDate, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              DataColumn(label: AppText.body(AppStrings.referralStatus, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              DataColumn(label: AppText.body(AppStrings.rewardIssued, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              DataColumn(label: AppText.body(AppStrings.inviterPoints, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              DataColumn(label: AppText.body(AppStrings.inviteePoints, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ],
            rows: referrals.map((ref) {
              final formattedDate = ref.createdAt != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(ref.createdAt!)
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
                        AppText.body(ref.inviterEmail, fontSize: 12.sp, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.body(ref.inviteeName, fontWeight: FontWeight.bold),
                        AppText.body(ref.inviteeEmail, fontSize: 12.sp, color: AppColors.textSecondary),
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
                      text: ref.rewardIssued ? AppStrings.rewardIssuedYes : AppStrings.rewardIssuedNo,
                      color: ref.rewardIssued ? AppColors.neonBlue : AppColors.textSecondary,
                    ),
                  ),
                  DataCell(AppText.body('+${ref.inviterPoints} ${AppStrings.pointsUnit}', color: AppColors.success, fontWeight: FontWeight.bold)),
                  DataCell(AppText.body('+${ref.inviteePoints} ${AppStrings.pointsUnit}', color: AppColors.neonBlue, fontWeight: FontWeight.bold)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: AppColors.textSecondary, size: 64.r),
          SizedBox(height: 16.h),
          AppText.body(AppStrings.noResultsMatching, fontSize: 18.sp),
        ],
      ),
    );
  }
}
