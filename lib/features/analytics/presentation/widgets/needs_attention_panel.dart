import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_section_header.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/open_shift_dialog.dart';
import '../lounge_stats_cubit.dart';
import '../lounge_stats_state.dart';

class NeedsAttentionPanel extends StatelessWidget {
  final bool isSuperAdmin;

  const NeedsAttentionPanel({super.key, this.isSuperAdmin = false});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final isCashier = user?.role == UserRole.cashier;

    return BlocBuilder<BookingCubit, BookingState>(
      buildWhen: (prev, curr) => prev.bookings != curr.bookings,
      builder: (context, bookingState) {
        return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
          buildWhen: (prev, curr) => prev.requests != curr.requests,
          builder: (context, reqState) {
            return BlocBuilder<LoungeStatsCubit, LoungeStatsState>(
              buildWhen: (prev, curr) =>
                  prev.stats?.lowStockItems != curr.stats?.lowStockItems,
              builder: (context, statsState) {
                return BlocBuilder<ShiftCubit, ShiftState>(
                  buildWhen: (prev, curr) => prev.status != curr.status,
                  builder: (context, shiftState) {
                    final bookings = bookingState.bookings;

                    // 1. Pending payment proofs
                    final pendingProofs = bookings.where((b) {
                      final hasReceipt =
                          b.receiptUrl != null &&
                          b.receiptUrl!.trim().isNotEmpty;
                      final isUnpaid = b.paymentStatus != PaymentStatus.paid;
                      final isPendingVerification =
                          b.status == BookingStatus.pendingVerification;
                      return (hasReceipt && isUnpaid) || isPendingVerification;
                    }).toList();

                    // 2. Unattended client requests
                    final unattendedRequests = reqState.requests
                        .where((r) => !r.isAttended)
                        .toList();

                    // 3. Low stock items
                    final lowStockCount = statsState.stats?.lowStockItems ?? 0;

                    // 4. No active shift for cashier
                    final hasNoActiveShift =
                        isCashier && shiftState.status == ShiftStatus.initial;

                    final totalAlerts =
                        pendingProofs.length +
                        unattendedRequests.length +
                        (lowStockCount > 0 ? 1 : 0) +
                        (hasNoActiveShift ? 1 : 0);

                    return Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: totalAlerts > 0
                              ? AppColors.warning.withValues(alpha: 0.4)
                              : AppColors.borderDefault,
                        ),
                        boxShadow: [
                          if (totalAlerts > 0)
                            BoxShadow(
                              color: AppColors.warning.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(totalAlerts),
                          SizedBox(height: 16.h),
                          if (totalAlerts == 0)
                            const _AllClearState()
                          else ...[
                            if (hasNoActiveShift)
                              _AttentionTile(
                                icon: Icons.access_time_filled_outlined,
                                title: AppStrings.noActiveShiftAlert,
                                color: AppColors.warning,
                                actionText: AppStrings.openShiftNow,
                                onAction: () => _handleOpenShift(
                                  context,
                                  user?.loungeId ?? '',
                                ),
                              ),
                            if (pendingProofs.isNotEmpty) ...[
                              if (hasNoActiveShift) SizedBox(height: 10.h),
                              _AttentionTile(
                                icon: Icons.receipt_long_outlined,
                                title: AppStrings.paymentProofsAlert(
                                  pendingProofs.length,
                                ),
                                color: AppColors.neonCyan,
                                actionText: AppStrings.verifyNow,
                                onAction: () =>
                                    context.push(RouterKeys.loungeAdminLiveOps),
                              ),
                            ],
                            if (unattendedRequests.isNotEmpty) ...[
                              if (hasNoActiveShift || pendingProofs.isNotEmpty)
                                SizedBox(height: 10.h),
                              _AttentionTile(
                                icon: Icons.notifications_active_outlined,
                                title: AppStrings.unattendedRequestsAlert(
                                  unattendedRequests.length,
                                ),
                                color: AppColors.warning,
                                actionText: AppStrings.attendNow,
                                onAction: () =>
                                    context.push(RouterKeys.loungeAdminLiveOps),
                              ),
                            ],
                            if (lowStockCount > 0) ...[
                              if (hasNoActiveShift ||
                                  pendingProofs.isNotEmpty ||
                                  unattendedRequests.isNotEmpty)
                                SizedBox(height: 10.h),
                              _AttentionTile(
                                icon: Icons.inventory_2_outlined,
                                title: AppStrings.lowStockAlert(lowStockCount),
                                color: AppColors.danger,
                                actionText: AppStrings.manageStock,
                                onAction: () =>
                                    context.push(RouterKeys.loungeAdminExtras),
                              ),
                            ],
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(int totalAlerts) {
    return AppSectionHeader(
      title: AppStrings.needsAttention,
      icon: totalAlerts > 0
          ? Icons.warning_amber_rounded
          : Icons.check_circle_outline,
      iconColor: totalAlerts > 0 ? AppColors.warning : AppColors.success,
      badgeCount: totalAlerts > 0 ? totalAlerts : null,
      badgeColor: AppColors.warning,
    );
  }

  void _handleOpenShift(BuildContext context, String loungeId) {
    final shiftCubit = context.read<ShiftCubit>();
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => OpenShiftDialog(
        isDismissible: true,
        onConfirm: (startingCash) {
          shiftCubit.openShift(loungeId, startingCash);
          Navigator.pop(diagContext);
        },
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String actionText;
  final VoidCallback onAction;

  const _AttentionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          AppButton(
            text: actionText,
            variant: AppButtonVariant.outlined,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class _AllClearState extends StatelessWidget {
  const _AllClearState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt_rounded,
              color: AppColors.success,
              size: 26.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.noPendingActions,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppStrings.noPendingActionsSubtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
