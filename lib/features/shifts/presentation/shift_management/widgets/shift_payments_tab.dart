import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';

class ShiftPaymentsTab extends StatelessWidget {
  const ShiftPaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftCubit, ShiftState>(
      buildWhen: (prev, curr) => prev.payments != curr.payments,
      builder: (context, state) {
        if (state.payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payments_outlined, size: 48.r, color: AppColors.textSecondary),
                SizedBox(height: 12.h),
                AppText.body(AppStrings.noPaymentsRecorded, color: AppColors.textSecondary),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: state.payments.length,
          separatorBuilder: (context, index) => Divider(color: AppColors.borderDefault, height: 1.h),
          itemBuilder: (context, index) {
            final item = state.payments[index];
            final isCash = item.isCash;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: (isCash ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                child: Icon(
                  isCash ? Icons.money : Icons.credit_card,
                  color: isCash ? AppColors.success : AppColors.warning,
                  size: 20.r,
                ),
              ),
              title: Text(AppStrings.paymentItem(item.category), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${AppStrings.paymentMethodLabel(item.paymentMethod.toUpperCase())} | ${DateFormat('hh:mm a').format(item.createdAt)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: Text(
                '${item.amount.toStringAsFixed(2)} ${AppStrings.egp}',
                style: TextStyle(
                  color: isCash ? AppColors.success : AppColors.warning,
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
