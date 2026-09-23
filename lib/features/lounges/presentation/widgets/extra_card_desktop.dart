import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';
import '../../domain/entities/extra_entity.dart';
import '../cubit/extras_cubit.dart';
import 'extra_dialog.dart';
import 'extra_stock_badge.dart';

class ExtraCardDesktop extends StatelessWidget {
  final ExtraEntity extra;
  final bool canEdit;
  final String loungeId;

  const ExtraCardDesktop({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.mutedBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: extra.imageUrl != null &&
                            extra.imageUrl!.trim().isNotEmpty
                        ? AppCachedImage(
                            imageUrl: extra.imageUrl,
                            borderRadius: 16.r,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(
                              Icons.restaurant_menu_outlined,
                              size: 40.r,
                              color: AppColors.neonBlue,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12.r,
                    right: 12.r,
                    child: ExtraStockBadge(extra: extra),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${extra.price.toStringAsFixed(2)} ${AppStrings.egp}',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canEdit)
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
                  ],
                ),
                if (canEdit) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.edit_outlined,
                            color: AppColors.textSecondary, size: 20.r),
                        onPressed: () {
                          showDialog(
                            context: context,
                            useRootNavigator: false,
                            builder: (ctx) => ExtraDialog(
                              loungeId: loungeId,
                              extra: extra,
                              onSave: (updatedExtra) {
                                context
                                    .read<ExtrasCubit>()
                                    .updateExtra(updatedExtra);
                              },
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 12.w),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.delete_outline,
                            color: AppColors.danger, size: 20.r),
                        onPressed: () => _confirmDelete(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<ExtrasCubit>().deleteExtra(extra.id, loungeId);
              Navigator.pop(dialogCtx);
            },
            child: Text(AppStrings.delete,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
