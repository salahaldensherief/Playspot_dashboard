import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';
import '../../domain/entities/extra_entity.dart';
import '../cubit/extras_cubit.dart';
import 'extra_dialog.dart';
import 'extra_stock_badge.dart';

class ExtraCardMobile extends StatelessWidget {
  final ExtraEntity extra;
  final bool canEdit;
  final String loungeId;

  const ExtraCardMobile({
    super.key,
    required this.extra,
    required this.canEdit,
    required this.loungeId,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = extra.isOutOfStock ||
        (extra.trackStock && extra.stockQuantity <= 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isOut
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.borderDefault,
        ),
      ),
      padding: EdgeInsets.all(12.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              color: AppColors.mutedBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: extra.imageUrl != null && extra.imageUrl!.trim().isNotEmpty
                  ? AppCachedImage(
                      imageUrl: extra.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        Icons.restaurant_menu_outlined,
                        size: 32.r,
                        color: AppColors.neonBlue,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  extra.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${extra.price.toStringAsFixed(0)} ${AppStrings.egp}',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                ExtraStockBadge(extra: extra),
              ],
            ),
          ),
          if (canEdit) ...[
            SizedBox(width: 8.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: !extra.isOutOfStock,
                    activeThumbColor: AppColors.neonBlue,
                    onChanged: (val) {
                      context
                          .read<ExtrasCubit>()
                          .toggleStock(extra.id, !val, loungeId);
                    },
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AppColors.neonBlue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => ExtraDialog(
                            loungeId: loungeId,
                            extra: extra,
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 12.w),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.danger,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "${extra.name}"?'),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          AppButton(
            text: AppStrings.delete,
            variant: AppButtonVariant.danger,
            onPressed: () {
              context.read<ExtrasCubit>().deleteExtra(extra.id, loungeId);
              Navigator.pop(dialogCtx);
            },
          ),
        ],
      ),
    );
  }
}
