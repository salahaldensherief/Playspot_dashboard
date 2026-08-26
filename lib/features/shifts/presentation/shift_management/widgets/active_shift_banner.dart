import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';
import 'open_shift_dialog.dart';
import 'close_shift_dialog.dart';

class ActiveShiftBanner extends StatelessWidget {
  const ActiveShiftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';

    return BlocBuilder<ShiftCubit, ShiftState>(
      buildWhen: (prev, curr) => prev.status != curr.status || prev.activeShift != curr.activeShift,
      builder: (context, state) {
        if (state.status.isLoading) {
          return _buildContainer(child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }

        if (state.status.isActive && state.activeShift != null) {
          final shift = state.activeShift!;
          return _buildContainer(
            color: AppColors.neonBlue.withOpacity(0.1),
            borderColor: AppColors.neonBlue,
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: AppColors.neonBlue, size: 24.r),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${AppStrings.shiftActive}: ${shift.cashierName ?? 'Staff'}",
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                    Text(
                      "${AppStrings.cashRevenue}: ${shift.cashRevenue ?? 0.0} ${AppStrings.egp}",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                    ),
                  ],
                ),
                const Spacer(),
                AppButton(
                  text: AppStrings.closeShift,
                  variant: AppButtonVariant.danger,
                  width: 140.w,
                  height: 40.h,
                  onPressed: () => showDialog(
                    context: context,
                    builder: (diagContext) => CloseShiftDialog(
                      shift: shift,
                      cubit: context.read<ShiftCubit>(),
                      loungeId: loungeId,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return _buildContainer(
          child: Row(
            children: [
              Icon(Icons.no_accounts_outlined, color: AppColors.textSecondary, size: 24.r),
              SizedBox(width: 12.w),
              Text(
                AppStrings.noActiveShift,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
              ),
              const Spacer(),
              AppButton(
                text: AppStrings.openNewShift,
                width: 140.w,
                height: 40.h,
                onPressed: () => showDialog(
                  context: context,
                  builder: (diagContext) => OpenShiftDialog(
                    loungeId: loungeId,
                    cubit: context.read<ShiftCubit>(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContainer({required Widget child, Color? color, Color? borderColor}) {
    return Container(
      width: double.infinity,
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: color ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor ?? AppColors.borderDefault),
      ),
      child: child,
    );
  }
}
