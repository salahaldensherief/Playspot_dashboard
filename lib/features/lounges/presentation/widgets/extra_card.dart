import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
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
      case 'snacks':
        return AppStrings.snacks;
      case 'services':
        return AppStrings.services;
      default:
        return category.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final canEdit = user?.canManageMenuStructure ?? false;
    final loungeId = user?.loungeId ?? extra.loungeId;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: extra.isOutOfStock
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
                  Center(
                    child: Icon(
                      Icons.restaurant_menu_outlined,
                      size: 40.r,
                      color: AppColors.neonBlue,
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
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extra.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${extra.price.toStringAsFixed(2)} ${AppStrings.egp}',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (extra.isOutOfStock)
                      StatusBadge.danger(AppStrings.outOfStock)
                    else
                      StatusBadge.success(AppStrings.active),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (canEdit)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                            onPressed: () => _showEditDialog(context, extra, loungeId),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
                            onPressed: () => _confirmDelete(context, loungeId),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    if (canEdit)
                      Switch(
                        value: !extra.isOutOfStock,
                        activeThumbColor: AppColors.neonBlue,
                        onChanged: (val) {
                          context.read<ExtrasCubit>().toggleStock(extra.id, !val, loungeId);
                        },
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
