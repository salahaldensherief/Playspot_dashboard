import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class BookingFinancialsExtrasList extends StatelessWidget {
  final List<dynamic> extras;

  const BookingFinancialsExtrasList({
    super.key,
    required this.extras,
  });

  @override
  Widget build(BuildContext context) {
    if (extras.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        AppText.subHeading(AppStrings.extras, fontSize: 14.sp),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: extras.map((item) {
              final qty = (item['quantity'] ?? item['qty'] ?? item['count'] as num?)?.toInt() ?? 1;
              final rawName =
                  item['name_ar'] ?? item['name_en'] ?? item['name'] ?? item['title'] ?? item['item_name'];
              final name = (rawName != null &&
                      rawName.toString().trim().isNotEmpty &&
                      rawName.toString().trim() != 'null')
                  ? rawName.toString().trim()
                  : 'صنف';
              final unitPrice = (item['unit_price'] ?? item['price'] as num?)?.toDouble() ?? 0.0;
              final itemTotal = (item['total_price'] as num?)?.toDouble() ?? (unitPrice * qty);

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_cafe_outlined, size: 14.r, color: AppColors.neonBlue),
                        SizedBox(width: 6.w),
                        AppText.body('${qty}x $name', fontSize: 12.sp, color: AppColors.textPrimary),
                      ],
                    ),
                    AppText.body(
                      '${itemTotal.toStringAsFixed(2)} ${AppStrings.egp}',
                      fontSize: 12.sp,
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
