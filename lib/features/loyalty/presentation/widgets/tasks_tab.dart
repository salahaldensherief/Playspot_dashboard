import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/status_badge.dart';

import '../../domain/entities/loyalty_task_entity.dart';
import '../cubit/loyalty_cubit.dart';
import 'edit_task_dialog.dart';

class TasksTab extends StatelessWidget {
  final List<LoyaltyTaskEntity> tasks;
  final LoyaltyCubit cubit;

  const TasksTab({
    super.key,
    required this.tasks,
    required this.cubit,
  });

  void _showEditTaskDialog(BuildContext context, LoyaltyTaskEntity task) {
    showDialog(
      context: context,
      builder: (diagCtx) => EditTaskDialog(
        task: task,
        onSave: (updatedTask) {
          cubit.updateTask(
            updatedTask.id,
            titleAr: updatedTask.titleAr,
            titleEn: updatedTask.titleEn,
            descriptionAr: updatedTask.descriptionAr,
            descriptionEn: updatedTask.descriptionEn,
            pointsReward: updatedTask.pointsReward,
            isActive: updatedTask.isActive,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    final isArabic = context.locale.languageCode == 'ar';

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
          dataRowMaxHeight: 72.h,
          columns: [
            DataColumn(label: AppText.body(AppStrings.taskName, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            DataColumn(label: AppText.body(AppStrings.taskDescription, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            DataColumn(label: AppText.body(AppStrings.rewardPoints, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            DataColumn(label: AppText.body(AppStrings.completedUsersCount, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            DataColumn(label: AppText.body(AppStrings.taskStatus, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            DataColumn(label: AppText.body(AppStrings.actions, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],
          rows: tasks.map((task) {
            final title = isArabic ? task.titleAr : task.titleEn;
            final description = isArabic ? task.descriptionAr : task.descriptionEn;

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.task_alt_outlined, color: AppColors.neonBlue, size: 20.r),
                      ),
                      SizedBox(width: 12.w),
                      AppText.body(title, fontWeight: FontWeight.bold),
                    ],
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 250.w,
                    child: AppText.body(
                      description,
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      maxLines: 2,
                    ),
                  ),
                ),
                DataCell(
                  AppText.body(
                    '+${task.pointsReward} ${AppStrings.pointsUnit}',
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DataCell(
                  AppText.body(
                    '${task.completedCount}',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DataCell(
                  StatusBadge(
                    text: task.isActive ? AppStrings.active : AppStrings.inactive,
                    color: task.isActive ? AppColors.success : AppColors.danger,
                  ),
                ),
                DataCell(
                  AppButton(
                    text: AppStrings.edit,
                    icon: Icons.edit_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _showEditTaskDialog(context, task),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, color: AppColors.textSecondary, size: 64.r),
          SizedBox(height: 16.h),
          AppText.body(AppStrings.noResultsMatching, fontSize: 18.sp),
        ],
      ),
    );
  }
}
