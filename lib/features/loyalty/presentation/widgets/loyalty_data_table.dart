import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';
import '../cubit/loyalty_cubit.dart';

class LoyaltyDataTable extends StatelessWidget {
  final List<RedemptionOptionEntity> options;
  final LoyaltyCubit cubit;
  final Function(RedemptionOptionEntity) onEdit;

  const LoyaltyDataTable({
    super.key,
    required this.options,
    required this.cubit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return DataTableWidget(
      columns: [
        AppStrings.nameEn,
        AppStrings.pointsCost,
        AppStrings.revenue, // Or a better string for reward
        AppStrings.status,
        AppStrings.actions,
      ],
      rows: options.map((opt) => DataRow(
        cells: [
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText.body(opt.titleEn, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                AppText.body(opt.titleAr, color: AppColors.textSecondary, fontSize: 11.sp),
              ],
            ),
          ),
          DataCell(AppText.body(opt.pointsCost.toString())),
          DataCell(
            AppText.body(
              opt.rewardType == 'discount_fixed' 
                ? "${opt.rewardValue.toStringAsFixed(0)} ${AppStrings.egp} Off" 
                : "Free Hour",
              color: AppColors.neonBlue,
            )
          ),
          DataCell(
            opt.isActive ? StatusBadge.success(AppStrings.active.toUpperCase()) : StatusBadge.danger(AppStrings.inactive.toUpperCase())
          ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                  onPressed: () => onEdit(opt),
                ),
                IconButton(
                  icon: Icon(
                    opt.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                    color: opt.isActive ? AppColors.warning : AppColors.success, 
                    size: 20
                  ),
                  onPressed: () => cubit.toggleOptionStatus(opt.id, !opt.isActive),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                  onPressed: () => _confirmDelete(context, opt),
                ),
              ],
            ),
          ),
        ],
      )).toList(),
    );
  }

  void _confirmDelete(BuildContext context, RedemptionOptionEntity option) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "${option.titleEn}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              cubit.deleteOption(option.id);
              Navigator.pop(diagContext);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
