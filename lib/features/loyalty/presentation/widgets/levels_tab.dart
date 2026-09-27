import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';

import '../../domain/entities/loyalty_level_entity.dart';
import '../cubit/loyalty_cubit.dart';
import 'edit_level_dialog.dart';

class LevelsTab extends StatelessWidget {
  final List<LoyaltyLevelEntity> levels;
  final LoyaltyCubit cubit;

  const LevelsTab({
    super.key,
    required this.levels,
    required this.cubit,
  });

  void _showEditLevelDialog(BuildContext context, LoyaltyLevelEntity level) {
    showDialog(
      context: context,
      builder: (diagCtx) => EditLevelDialog(
        level: level,
        onSave: (updatedLevel) {
          cubit.updateLevel(
            updatedLevel.id,
            minPoints: updatedLevel.minPoints,
            multiplier: updatedLevel.multiplier,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return _buildEmptyState();
    }

    final isArabic = context.locale.languageCode == 'ar';

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final int crossAxisCount = width > 1100 ? 4 : (width > 700 ? 2 : 1);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: levels.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20.w,
              mainAxisSpacing: 20.h,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final level = levels[index];
              final levelName = isArabic ? level.nameAr : level.nameEn;
              final levelColor = _parseColor(level.colorHex);

              return Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: levelColor.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: levelColor, size: 28.r),
                            SizedBox(width: 8.w),
                            AppText.heading(levelName, fontSize: 20.sp, color: levelColor),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: levelColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: AppText.body(
                            '${level.multiplier}x ${AppStrings.levelMultiplier}',
                            fontSize: 12.sp,
                            color: levelColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.borderDefault, height: 24),
                    const Spacer(),

                    // Min Points
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.body(AppStrings.minPoints, fontSize: 12.sp, color: AppColors.textSecondary),
                        AppText.body('${level.minPoints} ${AppStrings.pointsUnit}', fontWeight: FontWeight.bold),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // User Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.body(AppStrings.usersInLevel, fontSize: 12.sp, color: AppColors.textSecondary),
                        AppText.body('${level.userCount}', fontWeight: FontWeight.bold, color: AppColors.neonBlue),
                      ],
                    ),
                    const Spacer(),

                    // Edit Action
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: AppStrings.editLevel,
                        icon: Icons.edit_outlined,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => _showEditLevelDialog(context, level),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('0FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return AppColors.neonBlue;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_outlined, color: AppColors.textSecondary, size: 64.r),
          SizedBox(height: 16.h),
          AppText.body(AppStrings.noResultsMatching, fontSize: 18.sp),
        ],
      ),
    );
  }
}
