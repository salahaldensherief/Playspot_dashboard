import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../domain/entities/pricing_rule_entity.dart';
import '../pricing_state.dart';

class PricingGroupedRulesList extends StatelessWidget {
  final List<PricingRuleEntity> rules;
  final PricingGroupBy groupBy;
  final Function(PricingRuleEntity rule) onEdit;
  final Function(PricingRuleEntity rule) onDelete;

  const PricingGroupedRulesList({
    super.key,
    required this.rules,
    required this.groupBy,
    required this.onEdit,
    required this.onDelete,
  });

  String _getGroupTitle(PricingRuleEntity rule) {
    switch (groupBy) {
      case PricingGroupBy.lounge:
        return 'pricing_entire_lounge'.tr();
      case PricingGroupBy.spaceType:
        return rule.spaceTypeId != null && rule.spaceTypeId!.isNotEmpty
            ? 'pricing_space_type_scope'.tr(
                args: [(rule.spaceTypeId).toString()],
              )
            : 'pricing_all_spaces'.tr();
      case PricingGroupBy.room:
        return rule.roomId != null && rule.roomId!.isNotEmpty
            ? 'pricing_room_scope'.tr(args: [(rule.roomId).toString()])
            : 'pricing_all_rooms'.tr();
    }
  }

  Widget _buildStatusChip(PricingRuleStatus status) {
    Color color;
    String label;

    switch (status) {
      case PricingRuleStatus.active:
        color = AppColors.success;
        label = AppStrings.activeStatus;
        break;
      case PricingRuleStatus.scheduled:
        color = AppColors.warning;
        label = AppStrings.scheduledStatus;
        break;
      case PricingRuleStatus.expired:
        color = AppColors.textSecondary;
        label = AppStrings.expiredStatus;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.style_outlined,
                size: 48.r,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 12.h),
              Text(
                'pricing_rules_empty'.tr(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group rules
    final Map<String, List<PricingRuleEntity>> groupedMap = {};
    for (final rule in rules) {
      final groupKey = _getGroupTitle(rule);
      groupedMap.putIfAbsent(groupKey, () => []).add(rule);
    }

    return ListView.builder(
      itemCount: groupedMap.keys.length,
      itemBuilder: (context, index) {
        final groupKey = groupedMap.keys.elementAt(index);
        final groupRules = groupedMap[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 18.r,
                    color: AppColors.neonBlue,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    groupKey,
                    style: TextStyle(
                      color: AppColors.neonBlue,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupRules.length,
              separatorBuilder: (ctx, i) => SizedBox(height: 8.h),
              itemBuilder: (ctx, i) {
                final rule = groupRules[i];
                return Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  rule.nameAr,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                _buildStatusChip(rule.status),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'pricing_rule_summary'.tr(
                                args: [
                                  (rule.startTime).toString(),
                                  (rule.endTime).toString(),
                                  (rule.adjustmentValue).toString(),
                                  (rule.adjustmentType).toString(),
                                ],
                              ),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18.r,
                          color: AppColors.neonBlue,
                        ),
                        onPressed: () => onEdit(rule),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18.r,
                          color: AppColors.danger,
                        ),
                        onPressed: () => onDelete(rule),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
          ],
        );
      },
    );
  }
}
