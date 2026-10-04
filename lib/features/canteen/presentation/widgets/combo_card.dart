import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../domain/entities/canteen_combo_entity.dart';

class ComboCard extends StatelessWidget {
  final CanteenComboEntity combo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const ComboCard({
    super.key,
    required this.combo,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: combo.isActive
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
          // Header: Image + Title + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child:
                    combo.imageUrl != null &&
                        (combo.imageUrl?.isNotEmpty ?? false)
                    ? AppCachedImage(
                        imageUrl: combo.imageUrl ?? '',
                        width: 60.w,
                        height: 60.w,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60.w,
                        height: 60.w,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: AppColors.primary,
                          size: 28.r,
                        ),
                      ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText.subHeading(
                            combo.nameAr,
                            fontSize: 15.sp,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Active Switch
                        Switch(
                          value: combo.isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: onToggleActive,
                        ),
                      ],
                    ),
                    if (combo.nameEn != null &&
                        (combo.nameEn?.isNotEmpty ?? false)) ...[
                      SizedBox(height: 2.h),
                      AppText.body(
                        combo.nameEn ?? '',
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ],
                    if (combo.descriptionAr != null &&
                        (combo.descriptionAr?.isNotEmpty ?? false)) ...[
                      SizedBox(height: 4.h),
                      AppText.body(
                        combo.descriptionAr ?? '',
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Price & Savings Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: AppText.subHeading(
                  '${combo.price.toStringAsFixed(0)} ${AppStrings.egp}',
                  fontSize: 14.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              if (combo.separateItemsTotal > combo.price) ...[
                Text(
                  '${combo.separateItemsTotal.toStringAsFixed(0)} ${AppStrings.egp}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: AppText.body(
                    'combo_savings_label'.tr(
                      args: [
                        (combo.savings.toStringAsFixed(0)).toString(),
                        (AppStrings.egp).toString(),
                      ],
                    ),
                    fontSize: 11.sp,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const Spacer(),
              if (combo.profitMargin != null)
                AppText.body(
                  'combo_margin_label'.tr(
                    args: [
                      ((combo.profitMargin ?? 0).toStringAsFixed(0)).toString(),
                      (AppStrings.egp).toString(),
                    ],
                  ),
                  fontSize: 11.sp,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Components Preview List
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: combo.items.map((item) {
              final itemName =
                  item.extraNameAr ?? item.extraNameEn ?? AppStrings.item;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: AppText.body(
                  '${item.quantity}x $itemName',
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 12.h),

          Divider(color: AppColors.borderDefault, height: 1.h),
          SizedBox(height: 8.h),

          // Action Buttons Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                ),
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
                    message: 'delete_combo_confirmation'.tr(),
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
    );
  }
}
