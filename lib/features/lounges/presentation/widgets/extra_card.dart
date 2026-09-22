import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../../domain/entities/extra_entity.dart';
import '../cubit/extras_cubit.dart';
import 'extra_dialog.dart';

class ExtraCard extends StatelessWidget {
  final ExtraEntity extra;
  const ExtraCard({super.key, required this.extra});

  String _formatCategoryLabel(String category) {
    switch (category.toLowerCase().trim()) {
      case 'drinks':
        return AppStrings.drinks;
      case 'hot_drinks':
        return 'مشروبات ساخنة | Hot Drinks';
      case 'cold_drinks':
        return 'مشروبات باردة | Cold Drinks';
      case 'food':
        return 'مأكولات | Food';
      case 'snacks':
        return AppStrings.snacks;
      case 'services':
        return AppStrings.services;
      default:
        return category.toUpperCase();
    }
  }

  Widget _buildStockBadge() {
    if (extra.isOutOfStock || (extra.trackStock && extra.stockQuantity <= 0)) {
      return StatusBadge.danger(AppStrings.outOfStock);
    } else if (extra.trackStock && extra.stockQuantity <= extra.minStockAlert) {
      return StatusBadge.warning('كمية منخفضة (${extra.stockQuantity})');
    } else if (extra.trackStock) {
      return StatusBadge.info('المخزون: ${extra.stockQuantity}');
    } else {
      return StatusBadge.success(AppStrings.active);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final canEdit = user?.canManageMenuStructure ?? false;
    final loungeId = user?.loungeId ?? extra.loungeId;
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return _buildMobileCard(context, canEdit, loungeId);
    }
    return _buildDesktopCard(context, canEdit, loungeId);
  }

  /// 📱 Mobile Layout: Clean Horizontal Card (Touch-Friendly List Tile)
  Widget _buildMobileCard(BuildContext context, bool canEdit, String loungeId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: (extra.isOutOfStock || (extra.trackStock && extra.stockQuantity <= 0))
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.borderDefault,
        ),
      ),
      padding: EdgeInsets.all(12.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item Image Preview (80x80)
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

          // Item Details Center Column
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
                  '${extra.price.toStringAsFixed(2)} ${AppStrings.egp} • ${_formatCategoryLabel(extra.category)}',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                _buildStockBadge(),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // Actions Right Column (Edit/Delete & Switch)
          if (canEdit)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                      onPressed: () => _showEditDialog(context, extra, loungeId),
                    ),
                    SizedBox(width: 12.w),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
                      onPressed: () => _confirmDelete(context, loungeId),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: !extra.isOutOfStock,
                    activeThumbColor: AppColors.neonBlue,
                    onChanged: (val) {
                      context.read<ExtrasCubit>().toggleStock(extra.id, !val, loungeId);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 🖥️ Desktop / Tablet Layout: Structured Grid Card
  Widget _buildDesktopCard(BuildContext context, bool canEdit, String loungeId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: (extra.isOutOfStock || (extra.trackStock && extra.stockQuantity <= 0))
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
                    child: extra.imageUrl != null && extra.imageUrl!.trim().isNotEmpty
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
                    child: StatusBadge.secondary(_formatCategoryLabel(extra.category)),
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
                    SizedBox(width: 6.w),
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildStockBadge(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (canEdit)
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                              onPressed: () => _showEditDialog(context, extra, loungeId),
                            ),
                            SizedBox(width: 12.w),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
                              onPressed: () => _confirmDelete(context, loungeId),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (canEdit)
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: !extra.isOutOfStock,
                          activeThumbColor: AppColors.neonBlue,
                          onChanged: (val) {
                            context.read<ExtrasCubit>().toggleStock(extra.id, !val, loungeId);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ExtraEntity extra, String loungeId) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => ExtraDialog(
        loungeId: loungeId,
        extra: extra,
        onSave: (updatedExtra) {
          context.read<ExtrasCubit>().updateExtra(updatedExtra);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String loungeId) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "${extra.name}"?'),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.pop(diagContext),
          ),
          AppButton(
            text: AppStrings.delete,
            variant: AppButtonVariant.danger,
            onPressed: () {
              context.read<ExtrasCubit>().deleteExtra(extra.id, loungeId);
              Navigator.pop(diagContext);
            },
          ),
        ],
      ),
    );
  }
}
