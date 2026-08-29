import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import '../../domain/entities/extra_entity.dart';
import '../cubit/extras_cubit.dart';
import 'extra_dialog.dart';

class ExtraCard extends StatelessWidget {
  final ExtraEntity extra;
  const ExtraCard({super.key, required this.extra});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';
    final bool canEdit = context.hasPermission('menu_manage_items');
    final bool canToggleStock = context.hasPermission('menu_toggle_stock');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.divider.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                image: extra.imageUrl != null 
                  ? DecorationImage(image: NetworkImage(extra.imageUrl!), fit: BoxFit.cover)
                  : null,
              ),
              child: extra.imageUrl == null 
                ? const Center(child: Icon(Icons.fastfood, color: AppColors.textSecondary, size: 48))
                : null,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge.info(extra.category),
                    AppText.subHeading(
                      '${extra.price} ${AppStrings.priceEgp}',
                      color: AppColors.neonBlue,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                AppText.heading(extra.name, fontSize: 16.sp, isOrbitron: false),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (canEdit)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                            onPressed: () => _showEditDialog(context, loungeId),
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
                        activeColor: AppColors.neonBlue,
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

  void _showEditDialog(BuildContext context, String loungeId) {
    showDialog(
      context: context,
      builder: (_) => ExtraDialog(
        loungeId: loungeId, 
        extra: extra,
        onSave: (updatedExtra) => context.read<ExtrasCubit>().updateExtra(updatedExtra),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String loungeId) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "${extra.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              context.read<ExtrasCubit>().deleteExtra(extra.id, loungeId);
              Navigator.pop(diagContext);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger))
          ),
        ],
      ),
    );
  }
}
