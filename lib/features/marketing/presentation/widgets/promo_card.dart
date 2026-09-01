import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        image: promo.imageUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(promo.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: AppColors.neonBlue.withOpacity(0.5)),
                  ),
                  child: Text(
                    promo.tagEn.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.neonBlue,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  promo.titleEn,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  promo.deepLink ?? 'Global Promotion',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12.r,
            right: 12.r,
            child: Row(
              children: [
                _CircleActionButton(
                  icon: Icons.edit_outlined,
                  onPressed: onEdit,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                _CircleActionButton(
                  icon: Icons.delete_outline,
                  onPressed: onDelete,
                  color: AppColors.danger,
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

  const _CircleActionButton({
    required this.icon,
    this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18.r),
      ),
    );
  }
}
