import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';

class ShiftAuditLogsTab extends StatelessWidget {
  const ShiftAuditLogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftCubit, ShiftState>(
      buildWhen: (prev, curr) => prev.auditLogs != curr.auditLogs,
      builder: (context, state) {
        if (state.auditLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu_rounded, size: 48.r, color: AppColors.textSecondary),
                SizedBox(height: 12.h),
                AppText.body(AppStrings.noDataFound, color: AppColors.textSecondary),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: state.auditLogs.length,
          separatorBuilder: (context, index) => Divider(color: AppColors.borderDefault, height: 1.h),
          itemBuilder: (context, index) {
            final log = state.auditLogs[index];
            final actionColor = log.action == 'insert'
                ? AppColors.success
                : log.action == 'update'
                    ? AppColors.warning
                    : AppColors.danger;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: actionColor.withValues(alpha: 0.15),
                child: Icon(
                  log.action == 'insert'
                      ? Icons.add_circle_outline
                      : log.action == 'update'
                          ? Icons.edit_note_rounded
                          : Icons.delete_outline,
                  color: actionColor,
                  size: 20.r,
                ),
              ),
              title: Text(
                '${log.entityType.toUpperCase()} - ${log.action.toUpperCase()}',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${DateFormat('yyyy-MM-dd hh:mm:ss a').format(log.createdAt)} | ${AppStrings.byUser(log.actorName ?? AppStrings.system)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }
}
