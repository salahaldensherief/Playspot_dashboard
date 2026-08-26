import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../../../domain/entities/shift_entity.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';
import 'open_shift_dialog.dart';
import 'close_shift_dialog.dart';
import 'z_report_modal.dart';

class ShiftHeaderBanner extends StatelessWidget {
  const ShiftHeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShiftCubit, ShiftState>(
      listener: (context, state) {
        if (state.status.isClosed && state.closedShiftReport != null) {
          _showZReport(context, state.closedShiftReport!);
        }
      },
      builder: (context, state) {
        final user = context.read<LoginCubit>().state.user;
        if (user == null) return const SizedBox.shrink();
        final loungeId = user.loungeId ?? '';

        // If no active shift, show the warning banner
        if (state.status.isNoActive) {
          return _buildNoActiveShiftBanner(context, loungeId);
        }

        // If there is an active shift
        if (state.activeShift != null) {
          return _buildActiveShiftBanner(context, state.activeShift!, loungeId);
        }

        // Loading or initial state
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildNoActiveShiftBanner(BuildContext context, String loungeId) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      color: AppColors.danger.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20.r),
          SizedBox(width: 12.w),
          Text(
            AppStrings.noActiveShift,
            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
          const Spacer(),
          AppButton(
            text: AppStrings.openNewShift,
            onPressed: () => _showOpenShiftDialog(context, loungeId),
            variant: AppButtonVariant.primary,
            height: 32.h,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShiftBanner(BuildContext context, ShiftEntity shift, String loungeId) {
    final startTime = DateFormat('hh:mm a').format(shift.startTime);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
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
          SizedBox(width: 24.w),
          _buildInfoItem(AppStrings.cashier, shift.cashierName ?? 'N/A'),
          SizedBox(width: 24.w),
          _buildInfoItem(AppStrings.startTimeLabel, startTime),
          const Spacer(),
          AppButton(
            text: AppStrings.closeShift,
            onPressed: () => _showCloseShiftDialog(context, shift, loungeId),
            variant: AppButtonVariant.outlined,
            height: 32.h,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showOpenShiftDialog(BuildContext context, String loungeId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (diagContext) => OpenShiftDialog(
        loungeId: loungeId,
        cubit: context.read<ShiftCubit>(),
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context, ShiftEntity shift, String loungeId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (diagContext) => CloseShiftDialog(
        shift: shift,
        cubit: context.read<ShiftCubit>(),
        loungeId: loungeId,
      ),
    );
  }

  void _showZReport(BuildContext context, dynamic report) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (diagContext) => ZReportModal(report: report),
    ).then((_) {
      context.read<ShiftCubit>().resetReport();
    });
  }
}
