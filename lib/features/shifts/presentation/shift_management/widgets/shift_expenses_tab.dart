import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';

class ShiftExpensesTab extends StatelessWidget {
  const ShiftExpensesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftCubit, ShiftState>(
      buildWhen: (prev, curr) => prev.expenses != curr.expenses,
      builder: (context, state) {
        if (state.expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 48.r, color: AppColors.textSecondary),
                SizedBox(height: 12.h),
                AppText.body(AppStrings.noExpensesRecorded, color: AppColors.textSecondary),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: state.expenses.length,
          separatorBuilder: (context, index) => Divider(color: AppColors.borderDefault, height: 1.h),
          itemBuilder: (context, index) {
            final item = state.expenses[index];
            final isDrop = item.isCashDrop;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: (isDrop ? AppColors.warning : AppColors.danger).withValues(alpha: 0.15),
                child: Icon(
                  isDrop ? Icons.move_to_inbox : Icons.receipt_long,
                  color: isDrop ? AppColors.warning : AppColors.danger,
                  size: 20.r,
                ),
              ),
              title: Text(item.reason, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${DateFormat('hh:mm a').format(item.createdAt)} | ${AppStrings.byUser(item.createdByName ?? AppStrings.system)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: Text(
                '${item.amount.toStringAsFixed(2)} ${AppStrings.egp}',
                style: TextStyle(
                  color: isDrop ? AppColors.warning : AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
