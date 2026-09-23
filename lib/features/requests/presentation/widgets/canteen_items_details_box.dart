import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class CanteenItemsDetailsBox extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double? totalPrice;
  final String? note;

  const CanteenItemsDetailsBox({
    super.key,
    required this.items,
    this.totalPrice,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 14.r, color: AppColors.success),
              SizedBox(width: 6.w),
              AppText.subHeading(
                AppStrings.canteenOrderDetails,
                fontSize: 12.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          if (note != null && (note?.trim().isNotEmpty ?? false)) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.note_alt_rounded, size: 12.r, color: AppColors.warning),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: AppText.body(
                      'ملاحظة: ${note ?? ''}',
                      fontSize: 10.sp,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 8.h),
          ...items.map((item) {
            final name = item['name_ar'] ?? item['name'] ?? item['name_en'] ?? item['item_name'] ?? AppStrings.item;
            final qty = item['quantity'] ?? item['qty'] ?? 1;
            final price = (item['price'] ?? item['unit_price'] as num?)?.toDouble() ?? 0.0;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: AppText.body(
                          '${qty}x',
                          fontSize: 11.sp,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      AppText.body(
                        name,
                        fontSize: 12.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                  if (price > 0)
                    AppText.body(
                      '${(price * (qty as num)).toStringAsFixed(0)} ${AppStrings.egp}',
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                ],
              ),
            );
          }),
          if (totalPrice != null && (totalPrice ?? 0) > 0) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Divider(color: AppColors.borderDefault, height: 1.h),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.body(
                  AppStrings.extrasTotal,
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: AppText.subHeading(
                    '${(totalPrice ?? 0).toStringAsFixed(0)} ${AppStrings.egp}',
                    fontSize: 12.sp,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
