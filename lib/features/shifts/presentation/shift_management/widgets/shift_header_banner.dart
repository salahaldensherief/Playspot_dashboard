import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import '../../../domain/entities/shift_entity.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';
import 'open_shift_dialog.dart';
import 'close_shift_dialog.dart';
import 'add_expense_dialog.dart';
import 'shift_handover_summary_dialog.dart';

class ShiftHeaderBanner extends StatelessWidget {
  const ShiftHeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, loginState) {
        final user = loginState.user;
        if (user == null) return const SizedBox.shrink();
        final loungeId = user.loungeId ?? '';

        return BlocBuilder<ShiftCubit, ShiftState>(
          builder: (context, state) {
            // If no active shift
            if (state.status == ShiftStatus.initial && state.activeShift == null) {
              return _buildNoActiveShiftBanner(context, loungeId, isMandatory: user.isCashier);
            }

            // If there is an active shift
            if (state.activeShift != null) {
              return _buildActiveShiftBanner(context, state.activeShift!, loungeId);
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildNoActiveShiftBanner(BuildContext context, String loungeId, {bool isMandatory = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: (isMandatory ? AppColors.danger : AppColors.neonBlue).withValues(alpha: 0.1),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12.w,
        runSpacing: 8.h,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMandatory ? Icons.warning_amber_rounded : Icons.info_outline,
                color: isMandatory ? AppColors.danger : AppColors.neonBlue,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                AppStrings.noActiveShift,
                style: TextStyle(
                  color: isMandatory ? AppColors.danger : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          AppButton(
            text: AppStrings.openNewShift,
            onPressed: () => _showOpenShiftDialog(context, loungeId, isDismissible: !isMandatory),
            variant: AppButtonVariant.primary,
            height: 32.h,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShiftBanner(BuildContext context, ShiftEntity shift, String loungeId) {
    final startTime = DateFormat('hh:mm a').format(shift.startTime);
    final user = context.read<LoginCubit>().state.user;
    final bool isMyShift = user?.id == shift.cashierId;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    AppStrings.shiftActive,
                    style: TextStyle(color: AppColors.success, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            _buildInfoItem(AppStrings.cashier, shift.cashierName ?? 'N/A'),
            SizedBox(width: 16.w),
            _buildInfoItem(AppStrings.startTimeLabel, startTime),
            SizedBox(width: 24.w),
            if (isMyShift) ...[
              AppButton(
                text: 'تسجيل مصروف / سحب',
                icon: Icons.receipt_long_outlined,
                variant: AppButtonVariant.outlined,
                height: 32.h,
                onPressed: () => _showAddExpenseDialog(context, shift, loungeId),
              ),
              SizedBox(width: 8.w),
              AppButton(
                text: AppStrings.closeShift,
                onPressed: () => _showCloseShiftDialog(context, shift, loungeId),
                variant: AppButtonVariant.outlined,
                height: 32.h,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      children: [
        Text('$label:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        SizedBox(width: 4.w),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showOpenShiftDialog(BuildContext context, String loungeId, {bool isDismissible = true}) {
    final shiftCubit = context.read<ShiftCubit>();
    final loginCubit = context.read<LoginCubit>();
    final permissionsCubit = context.read<PermissionsCubit>();

    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (diagContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: shiftCubit),
          BlocProvider.value(value: loginCubit),
          BlocProvider.value(value: permissionsCubit),
        ],
        child: OpenShiftDialog(
          isDismissible: isDismissible,
          onConfirm: (startingCash) {
            shiftCubit.openShift(loungeId, startingCash);
            Navigator.pop(diagContext);
          },
        ),
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context, ShiftEntity shift, String loungeId) {
    final shiftCubit = context.read<ShiftCubit>();
    final loginCubit = context.read<LoginCubit>();
    final permissionsCubit = context.read<PermissionsCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (diagContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: shiftCubit),
          BlocProvider.value(value: loginCubit),
          BlocProvider.value(value: permissionsCubit),
        ],
        child: CloseShiftDialog(
          expectedCash: shift.expectedCash,
          onConfirm: (actualCash, notes) async {
            Navigator.pop(diagContext);
            await shiftCubit.closeShift(shift.id, actualCash, notes, loungeId);
            if (context.mounted && shiftCubit.state.lastClosedShift != null) {
              showDialog(
                context: context,
                builder: (_) => ShiftHandoverSummaryDialog(shift: shiftCubit.state.lastClosedShift!),
              );
            }
          },
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, ShiftEntity shift, String loungeId) {
    final shiftCubit = context.read<ShiftCubit>();
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => BlocProvider.value(
        value: shiftCubit,
        child: AddExpenseDialog(
          shiftId: shift.id,
          loungeId: loungeId,
        ),
      ),
    );
  }
}
