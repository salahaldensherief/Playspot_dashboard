import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/shifts/domain/entities/shift_entity.dart';

class ShiftKpiCards extends StatelessWidget {
  final List<ShiftEntity> shifts;
  final ShiftEntity? activeShift;

  const ShiftKpiCards({
    super.key,
    required this.shifts,
    this.activeShift,
  });

  @override
  Widget build(BuildContext context) {
    double totalRev = 0.0;
    double totalCash = 0.0;
    double totalDigital = 0.0;
    double totalExp = 0.0;
    double totalExpectedCash = 0.0;
    double totalDiscrepancy = 0.0;

    for (var shift in shifts) {
      totalRev += shift.totalRevenue;
      totalCash += (shift.cashRevenue ?? 0.0);
      totalDigital += (shift.digitalRevenue ?? 0.0);
      totalExp += (shift.expensesTotal ?? 0.0);
      totalExpectedCash += shift.calculatedExpectedCash;
      if (shift.status == 'closed') {
        totalDiscrepancy += shift.calculatedDiscrepancy;
      }
    }

    final bool isHealthy = totalDiscrepancy >= 0;
    final bool isMobile = MediaQuery.sizeOf(context).width < 850;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildCardsList(
                  context,
                  totalRev,
                  totalCash,
                  totalDigital,
                  totalExp,
                  totalExpectedCash,
                  totalDiscrepancy,
                  isHealthy,
                ).map((card) => Container(width: 260.w, margin: EdgeInsets.only(right: 12.w), child: card)).toList(),
              ),
            )
          : Row(
              children: _buildCardsList(
                context,
                totalRev,
                totalCash,
                totalDigital,
                totalExp,
                totalExpectedCash,
                totalDiscrepancy,
                isHealthy,
              ).map((card) => Expanded(child: Container(margin: EdgeInsets.symmetric(horizontal: 6.w), child: card))).toList(),
            ),
    );
  }

  List<Widget> _buildCardsList(
    BuildContext context,
    double totalRev,
    double totalCash,
    double totalDigital,
    double totalExp,
    double totalExpectedCash,
    double totalDiscrepancy,
    bool isHealthy,
  ) {
    return [
      // 1. Current Active Shift Card
      _buildCard(
        title: AppStrings.currentShift,
        value: activeShift != null ? (activeShift!.cashierName ?? AppStrings.active) : AppStrings.noActiveShiftTitle,
        subtitle: activeShift != null 
            ? AppStrings.startingCashLabel('${activeShift!.startingCash.toStringAsFixed(0)} ${AppStrings.egp}') 
            : AppStrings.clickToOpen,
        icon: Icons.account_circle_outlined,
        color: activeShift != null ? AppColors.success : AppColors.textSecondary,
      ),

      // 2. Total Revenue Card
      _buildCard(
        title: AppStrings.totalRevenue,
        value: '${totalRev.toStringAsFixed(0)} ${AppStrings.egp}',
        subtitle: '${shifts.length} ${AppStrings.registeredShifts}',
        icon: Icons.payments_outlined,
        color: AppColors.neonBlue,
      ),

      // 3. Cash Revenue Card
      _buildCard(
        title: AppStrings.cashRevenueTitle,
        value: '${totalCash.toStringAsFixed(0)} ${AppStrings.egp}',
        subtitle: AppStrings.actualCashDrawer,
        icon: Icons.point_of_sale_rounded,
        color: AppColors.success,
      ),

      // 4. Digital Revenue Card
      _buildCard(
        title: AppStrings.digitalRevenueTitle,
        value: '${totalDigital.toStringAsFixed(0)} ${AppStrings.egp}',
        subtitle: AppStrings.cardInstapayWallet,
        icon: Icons.credit_card_rounded,
        color: AppColors.warning,
      ),

      // 5. Total Expenses Card
      _buildCard(
        title: AppStrings.expensesAndDrops,
        value: '${totalExp.toStringAsFixed(0)} ${AppStrings.egp}',
        subtitle: AppStrings.expensesAndDropsSub,
        icon: Icons.receipt_long_outlined,
        color: AppColors.danger,
      ),

      // 6. Expected Cash & Discrepancy Health Status
      _buildCard(
        title: AppStrings.financialDiscrepancies,
        value: '${totalDiscrepancy.toStringAsFixed(0)} ${AppStrings.egp}',
        subtitle: isHealthy ? AppStrings.matchedOrSurplus : AppStrings.deficitReviewNeeded,
        icon: isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
        color: isHealthy ? AppColors.success : AppColors.danger,
      ),
    ];
  }

  Widget _buildCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20.r),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppText.body(
                  title,
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AppText.heading(
            value,
            fontSize: 18.sp,
            color: AppColors.textPrimary,
          ),
          SizedBox(height: 4.h),
          AppText.body(
            subtitle,
            color: AppColors.textSecondary,
            fontSize: 11.sp,
          ),
        ],
      ),
    );
  }
}
