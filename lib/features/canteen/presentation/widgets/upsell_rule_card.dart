import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../domain/entities/upsell_conversion_entity.dart';
import '../../domain/entities/upsell_rule_entity.dart';

class UpsellRuleCard extends StatelessWidget {
  final UpsellRuleEntity rule;
  final UpsellConversionEntity? conversion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const UpsellRuleCard({
    super.key,
    required this.rule,
    this.conversion,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  String _formatTriggerDescription() {
    switch (rule.triggerType) {
      case 'session_minutes_elapsed':
        final minutes = rule.triggerParams['minutes'] ?? 45;
        return 'بعد انقضاء $minutes دقيقة من الجلسة';
      case 'cart_contains_category':
        final cat = rule.triggerParams['category'] ?? 'سناكس';
        return 'عند وجود صنف من تصنيف "$cat" في السلة';
      case 'session_start':
        return 'عند بدء الجلسة مباشرة';
      case 'time_of_day':
        final start = rule.triggerParams['start_time'] ?? '18:00';
        final end = rule.triggerParams['end_time'] ?? '23:00';
        return 'خلال الفترة من $start إلى $end';
      default:
        return rule.triggerType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final impressions = conversion?.impressions ?? 0;
    final conversionsCount = conversion?.conversions ?? 0;
    final conversionRate = conversion?.conversionRatePercent ?? 0.0;
    final revenue = conversion?.revenueGenerated ?? 0.0;

    final targetName = rule.suggestedNameAr ?? rule.suggestedNameEn ?? AppStrings.item;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: rule.isActive
              ? AppColors.borderDefault
              : AppColors.borderDefault.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Trigger Type & Active Toggle
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14.r, color: AppColors.secondary),
                    SizedBox(width: 4.w),
                    AppText.body(
                      _formatTriggerDescription(),
                      fontSize: 12.sp,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Switch(
                value: rule.isActive,
                activeThumbColor: AppColors.primary,
                onChanged: onToggleActive,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Suggested Target (Extra or Combo)
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: rule.isCombo
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: AppText.body(
                  rule.isCombo ? AppStrings.combosTab : AppStrings.singleItemsTab,
                  fontSize: 11.sp,
                  color: rule.isCombo ? AppColors.primary : AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: AppText.subHeading(
                  'يقترح: $targetName',
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (rule.discountPercent != null && (rule.discountPercent ?? 0) > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: AppText.body(
                    'خصم ${(rule.discountPercent ?? 0).toStringAsFixed(0)}%',
                    fontSize: 11.sp,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),

          // Conversion Analytics Metrics Card
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn(
                  AppStrings.impressionsCount,
                  '$impressions',
                  AppColors.textSecondary,
                ),
                Container(width: 1.w, height: 28.h, color: AppColors.borderDefault),
                _buildMetricColumn(
                  AppStrings.conversionsCount,
                  '$conversionsCount',
                  AppColors.success,
                ),
                Container(width: 1.w, height: 28.h, color: AppColors.borderDefault),
                _buildMetricColumn(
                  AppStrings.conversionRate,
                  '${conversionRate.toStringAsFixed(1)}%',
                  AppColors.primary,
                ),
                Container(width: 1.w, height: 28.h, color: AppColors.borderDefault),
                _buildMetricColumn(
                  AppStrings.revenueGenerated,
                  '${revenue.toStringAsFixed(0)} ${AppStrings.egp}',
                  AppColors.warning,
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          Divider(color: AppColors.borderDefault, height: 1.h),
          SizedBox(height: 6.h),

          // Card Footer Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.body(
                '${AppStrings.priority}: ${rule.priority} | أقصى ظهور: ${rule.maxImpressionsPerBooking}',
                fontSize: 11.sp,
                color: AppColors.textMuted,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                    tooltip: AppStrings.edit,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: AppStrings.delete,
                    onPressed: () async {
                      final confirmed = await AppDialog.confirm(
                        context: context,
                        title: AppStrings.delete,
                        message: 'هل أنت متأكد من رغبتك في حذف قاعدة الاقتراح هذه؟',
                        confirmColor: AppColors.error,
                      );
                      if (confirmed == true) {
                        onDelete();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        AppText.body(
          label,
          fontSize: 10.sp,
          color: AppColors.textMuted,
        ),
        SizedBox(height: 2.h),
        AppText.body(
          value,
          fontSize: 12.sp,
          color: valueColor,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }
}
