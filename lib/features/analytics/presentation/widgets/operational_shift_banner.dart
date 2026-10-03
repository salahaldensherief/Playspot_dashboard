import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/domain/entities/shift_entity.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/add_expense_dialog.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/close_shift_dialog.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/open_shift_dialog.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_handover_summary_dialog.dart';

class OperationalShiftBanner extends StatelessWidget {
  const OperationalShiftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => prev.user != curr.user,
      builder: (context, loginState) {
        final user = loginState.user;
        if (user == null) return const SizedBox.shrink();
        final loungeId = user.loungeId ?? '';

        return BlocBuilder<ShiftCubit, ShiftState>(
          buildWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.activeShift != curr.activeShift,
          builder: (context, shiftState) {
            if (shiftState.status == ShiftStatus.error) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'shift_overview_unavailable'.tr(),
                  style: const TextStyle(color: AppColors.warning),
                ),
              );
            }
            final isClosed =
                shiftState.status == ShiftStatus.initial &&
                shiftState.activeShift == null;

            if (isClosed) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildClosedBanner(
                  context,
                  loungeId,
                  isCashier: user.isCashier,
                ),
              );
            }

            final activeShift = shiftState.activeShift;
            if (activeShift != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildActiveBanner(
                  context,
                  activeShift,
                  loungeId,
                  userId: user.id,
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildClosedBanner(
    BuildContext context,
    String loungeId, {
    required bool isCashier,
  }) {
    final isMobile = context.isMobile;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsetsDirectional.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_clock_rounded,
                        color: AppColors.danger,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.operationalStateClosed,
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            AppStrings.operationalStateClosedDesc,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: AppStrings.openShiftNow,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _showOpenShiftDialog(
                      context,
                      loungeId,
                      isDismissible: !isCashier,
                    ),
                    variant: AppButtonVariant.primary,
                    height: 44.h,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: EdgeInsetsDirectional.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: AppColors.danger,
                    size: 22.r,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.operationalStateClosed,
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        AppStrings.operationalStateClosedDesc,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 150.w),
                  child: AppButton(
                    text: AppStrings.openShiftNow,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _showOpenShiftDialog(
                      context,
                      loungeId,
                      isDismissible: !isCashier,
                    ),
                    variant: AppButtonVariant.primary,
                    height: 42.h,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActiveBanner(
    BuildContext context,
    ShiftEntity shift,
    String loungeId, {
    required String? userId,
  }) {
    final startTimeStr = DateFormat('hh:mm a').format(shift.startTime);
    final isMyShift = userId != null && userId == shift.cashierId;
    final isMobile = context.isMobile;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 14.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActiveBadge(),
                    Text(
                      AppStrings.shiftStartedAt(startTimeStr),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  AppStrings.activeCashierLabel(shift.cashierName ?? 'N/A'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    if (isMyShift) ...[
                      Expanded(
                        child: AppButton(
                          text: AppStrings.recordExpense,
                          icon: Icons.receipt_long_outlined,
                          variant: AppButtonVariant.outlined,
                          height: 38.h,
                          onPressed: () =>
                              _showAddExpenseDialog(context, shift, loungeId),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Expanded(
                      child: AppButton(
                        text: AppStrings.closeShift,
                        icon: Icons.exit_to_app_rounded,
                        variant: AppButtonVariant.outlined,
                        height: 38.h,
                        onPressed: () =>
                            _showCloseShiftDialog(context, shift, loungeId),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                _buildActiveBadge(),
                SizedBox(width: 16.w),
                Text(
                  AppStrings.activeCashierLabel(shift.cashierName ?? 'N/A'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 16.w),
                Container(width: 1, height: 16.h, color: AppColors.divider),
                SizedBox(width: 16.w),
                Text(
                  AppStrings.shiftStartedAt(startTimeStr),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                  ),
                ),
                const Spacer(),
                if (isMyShift) ...[
                  AppButton(
                    text: AppStrings.recordExpense,
                    icon: Icons.receipt_long_outlined,
                    variant: AppButtonVariant.outlined,
                    height: 36.h,
                    onPressed: () =>
                        _showAddExpenseDialog(context, shift, loungeId),
                  ),
                  SizedBox(width: 10.w),
                ],
                AppButton(
                  text: AppStrings.closeShift,
                  icon: Icons.exit_to_app_rounded,
                  variant: AppButtonVariant.outlined,
                  height: 36.h,
                  onPressed: () =>
                      _showCloseShiftDialog(context, shift, loungeId),
                ),
              ],
            ),
    );
  }

  Widget _buildActiveBadge() {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            AppStrings.operationalStateOpen,
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showOpenShiftDialog(
    BuildContext context,
    String loungeId, {
    bool isDismissible = true,
  }) {
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
          onConfirm: (startingCash) async {
            await shiftCubit.openShift(loungeId, startingCash);
            if (diagContext.mounted &&
                shiftCubit.state.activeShift != null &&
                shiftCubit.state.status != ShiftStatus.error)
              Navigator.pop(diagContext);
          },
        ),
      ),
    );
  }

  void _showCloseShiftDialog(
    BuildContext context,
    ShiftEntity shift,
    String loungeId,
  ) {
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
              final closed = shiftCubit.state.lastClosedShift;
              if (closed != null) {
                showDialog(
                  context: context,
                  builder: (_) => ShiftHandoverSummaryDialog(shift: closed),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showAddExpenseDialog(
    BuildContext context,
    ShiftEntity shift,
    String loungeId,
  ) {
    final shiftCubit = context.read<ShiftCubit>();
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => BlocProvider.value(
        value: shiftCubit,
        child: AddExpenseDialog(shiftId: shift.id, loungeId: loungeId),
      ),
    );
  }
}
