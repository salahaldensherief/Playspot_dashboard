import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';

/// Neon Lounge Promo Discount Banner
/// Prominently displays active lounge-wide direct discounts at the top of the dashboard.
class LoungeDiscountBanner extends StatelessWidget {
  final dynamic lounge;
  final VoidCallback? onManageDiscount;

  const LoungeDiscountBanner({
    super.key,
    required this.lounge,
    this.onManageDiscount,
  });

  @override
  Widget build(BuildContext context) {
    if (lounge == null) return const SizedBox.shrink();

    bool hasDiscount = false;
    num discountPercentage = 0;
    String titleAr = '';
    String titleEn = '';
    String expiration = '';

    if (lounge is Lounge) {
      final Lounge l = lounge as Lounge;
      hasDiscount = l.hasDiscount;
      discountPercentage = l.discountPercentage;
      titleAr = l.discountTitleAr ?? '';
      titleEn = l.discountTitleEn ?? '';
      expiration = l.discountExpiresAt != null ? l.discountExpiresAt.toString().split(' ').first : '';
    } else if (lounge is Map) {
      final Map m = lounge as Map;
      hasDiscount = (m['has_discount'] ?? m['hasDiscount'] ?? false) as bool;
      discountPercentage = (m['discount_percentage'] ?? m['discountPercentage'] ?? 0) as num;
      titleAr = (m['discount_title_ar'] ?? m['discountTitleAr'] ?? '').toString();
      titleEn = (m['discount_title_en'] ?? m['discountTitleEn'] ?? '').toString();
      expiration = (m['discount_expiration'] ?? m['discountExpiration'] ?? '').toString();
    } else {
      try {
        hasDiscount = (lounge.hasDiscount ?? false) as bool;
        discountPercentage = (lounge.discountPercentage ?? 0) as num;
        titleAr = (lounge.discountTitleAr ?? '').toString();
        titleEn = (lounge.discountTitleEn ?? '').toString();
      } catch (_) {}
    }

    if (!hasDiscount || discountPercentage <= 0) {
      return const SizedBox.shrink();
    }

    final String promoTitle = titleAr.isNotEmpty ? titleAr : (titleEn.isNotEmpty ? titleEn : AppStrings.directDiscount);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.2),
            AppColors.neonPurple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.celebration_rounded, color: Colors.black, size: 16.r),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppText.subHeading(
                            '🎉 $promoTitle',
                            fontSize: 13.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'خصم ${discountPercentage.toStringAsFixed(0)}% شامل',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (expiration.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        AppText.body(
                          'ينتهي العرض في: $expiration',
                          fontSize: 10.sp,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onManageDiscount != null)
            TextButton.icon(
              onPressed: onManageDiscount,
              icon: Icon(Icons.tune_rounded, size: 14.r, color: AppColors.warning),
              label: Text(
                'إدارة الخصم',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
