import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import '../../domain/entities/promo_entity.dart';

class PromoCard extends StatelessWidget {
  final PromoEntity promo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PromoCard({
    super.key,
    required this.promo,
    this.onEdit,
    this.onDelete,
  });

  bool get isExpired {
    if (promo.expiresAt == null) return false;
    return promo.expiresAt!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final title = promo.titleAr.isNotEmpty ? promo.titleAr : promo.titleEn;
    final tag = promo.tagAr.isNotEmpty ? promo.tagAr : promo.tagEn;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isExpired ? AppColors.danger.withAlpha(128) : AppColors.neonBlue.withAlpha(77),
        ),
        image: (promo.imageUrl != null && promo.imageUrl!.trim().isNotEmpty)
            ? DecorationImage(
                image: CachedNetworkImageProvider(promo.imageUrl!.trim()),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(128),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? AppColors.danger.withAlpha(51)
                            : AppColors.success.withAlpha(51),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                          color: isExpired ? AppColors.danger : AppColors.success,
                        ),
                      ),
                      child: Text(
                        isExpired ? AppStrings.timeExpired : AppStrings.active,
                        style: TextStyle(
                          color: isExpired ? AppColors.danger : AppColors.success,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (tag.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue.withAlpha(51),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(color: AppColors.neonBlue.withAlpha(128)),
                        ),
                        child: Text(
                          tag.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.neonBlue,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  title.isNotEmpty ? title : AppStrings.promotionsMarketing,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                if (promo.expiresAt != null)
                  Text(
                    '${AppStrings.expirationDate}: ${DateFormat('yyyy-MM-dd').format(promo.expiresAt!.toLocal())}',
                    style: TextStyle(
                      color: isExpired ? Colors.redAccent : Colors.white70,
                      fontSize: 11.sp,
                    ),
                  )
                else
                  Text(
                    promo.deepLink ?? AppStrings.promotionsTab,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
          ),
          PositionedDirectional(
            top: 12.r,
            end: 12.r,
            child: Row(
              children: [
                if (onEdit != null)
                  _CircleActionButton(
                    icon: Icons.edit_outlined,
                    onPressed: onEdit,
                    color: Colors.white,
                    tooltip: AppStrings.edit,
                  ),
                if (onEdit != null && onDelete != null) SizedBox(width: 8.w),
                if (onDelete != null)
                  _CircleActionButton(
                    icon: Icons.delete_outline,
                    onPressed: onDelete,
                    color: AppColors.danger,
                    tooltip: AppStrings.delete,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String? tooltip;

  const _CircleActionButton({
    required this.icon,
    this.onPressed,
    required this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(153),
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(102)),
          ),
          child: Icon(icon, color: color, size: 18.r),
        ),
      ),
    );
  }
}
