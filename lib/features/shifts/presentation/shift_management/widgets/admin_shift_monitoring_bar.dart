import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';
import '../../../domain/entities/live_shift_overview_entity.dart';
import 'close_shift_dialog.dart';

class AdminShiftMonitoringBar extends StatefulWidget {
  const AdminShiftMonitoringBar({super.key});

  @override
  State<AdminShiftMonitoringBar> createState() => _AdminShiftMonitoringBarState();
}

class _AdminShiftMonitoringBarState extends State<AdminShiftMonitoringBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _refreshOverview();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _refreshOverview() {
    final user = context.read<LoginCubit>().state.user;
    if (user?.loungeId != null) {
      context.read<ShiftCubit>().getLiveShiftOverview(user!.loungeId!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getElapsedTime(DateTime? startTime) {
    if (startTime == null) return '--';
    final diff = DateTime.now().difference(startTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftCubit, ShiftState>(
      buildWhen: (previous, current) => previous.status != current.status || previous.liveOverview != current.liveOverview,
      builder: (context, state) {
        if (state.status == ShiftStatus.loading && state.liveOverview == null) {
          return const LinearProgressIndicator(color: AppColors.neonBlue, backgroundColor: Colors.transparent);
        }

        final overview = state.liveOverview;
        if (overview == null || !overview.hasActiveShift) {
          return _buildNoActiveShiftWarning();
        }

        return _buildMonitoringBanner(context, overview);
      },
    );
  }

  Widget _buildNoActiveShiftWarning() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: AppColors.danger.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20.r),
          SizedBox(width: 12.w),
          AppText.body(
            "⚠️ No Active Shift Running | لا توجد وردية مفتوحة",
            color: AppColors.danger,
            fontWeight: FontWeight.bold,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.danger, size: 20.r),
            onPressed: _refreshOverview,
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringBanner(BuildContext context, LiveShiftOverviewEntity overview) {
    final startTime = overview.startTime;
    final startTimeStr = startTime != null ? DateFormat.jm().format(startTime) : '--:--';
    final elapsed = _getElapsedTime(startTime);
    final bool isMobile = MediaQuery.sizeOf(context).width < 850;

    if (isMobile) {
      return _buildMobileMonitoringBanner(context, overview, startTimeStr, elapsed);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Cashier Profile
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.neonBlue.withOpacity(0.1),
            backgroundImage: overview.cashierAvatar != null ? NetworkImage(overview.cashierAvatar ?? '') : null,
            child: overview.cashierAvatar == null 
              ? Icon(Icons.person, color: AppColors.neonBlue, size: 24.r) 
              : null,
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(overview.cashierName ?? 'Cashier', fontWeight: FontWeight.bold),
              AppText.body(overview.cashierPhone ?? '', color: AppColors.textSecondary, fontSize: 12.sp),
            ],
          ),
          
          VerticalDivider(width: 40.w, color: AppColors.borderDefault),

          // Time Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body("Started at $startTimeStr", color: AppColors.textSecondary, fontSize: 12.sp),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: AppColors.neonBlue, size: 14.r),
                  SizedBox(width: 4.w),
                  AppText.body(elapsed, fontWeight: FontWeight.bold, color: AppColors.neonBlue),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Stats
          _buildStatItem("Cash", "${(overview.cashInDrawer ?? 0.0).toStringAsFixed(0)} ${AppStrings.egp}"),
          SizedBox(width: 24.w),
          _buildStatItem("Digital", "${(overview.digitalPayments ?? 0.0).toStringAsFixed(0)} ${AppStrings.egp}"),
          SizedBox(width: 24.w),
          _buildStatItem("Sessions", overview.activeSessions.toString(), icon: Icons.videogame_asset_outlined),
          
          SizedBox(width: 40.w),

          // Action
          AppButton(
            text: "Force Close",
            variant: AppButtonVariant.danger,
            height: 36.h,
            onPressed: () => _confirmForceClose(context, overview),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMonitoringBanner(BuildContext context, LiveShiftOverviewEntity overview, String startTime, String elapsed) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundImage: overview.cashierAvatar != null ? NetworkImage(overview.cashierAvatar ?? '') : null,
                child: overview.cashierAvatar == null ? Icon(Icons.person, size: 20.r) : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(overview.cashierName ?? 'Staff', fontWeight: FontWeight.bold, fontSize: 14.sp),
                    AppText.body("Since $startTime ($elapsed)", color: AppColors.textSecondary, fontSize: 11.sp),
                  ],
                ),
              ),
              AppButton(
                text: "Close",
                variant: AppButtonVariant.danger,
                height: 30.h,
                onPressed: () => _confirmForceClose(context, overview),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("Cash", (overview.cashInDrawer ?? 0.0).toStringAsFixed(0)),
              _buildStatItem("Digital", (overview.digitalPayments ?? 0.0).toStringAsFixed(0)),
              _buildStatItem("Active", overview.activeSessions.toString(), icon: Icons.videogame_asset_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, color: AppColors.textSecondary, fontSize: 10.sp),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14.r, color: AppColors.textPrimary),
              SizedBox(width: 4.w),
            ],
            AppText.body(value, fontWeight: FontWeight.bold),
          ],
        ),
      ],
    );
  }

  void _confirmForceClose(BuildContext context, LiveShiftOverviewEntity overview) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text("Force Close Shift", style: TextStyle(color: AppColors.textPrimary)),
        content: Text("Are you sure you want to force close the current shift for ${overview.cashierName ?? 'this cashier'}?"),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(diagContext),
          ),
          AppButton(
            text: "Yes, Close It",
            variant: AppButtonVariant.danger,
            onPressed: () {
              Navigator.pop(diagContext);
              _showCloseDialog(context, overview);
            },
          ),
        ],
      ),
    );
  }

  void _showCloseDialog(BuildContext context, LiveShiftOverviewEntity overview) {
    final shiftCubit = context.read<ShiftCubit>();
    final loginCubit = context.read<LoginCubit>();
    final user = loginCubit.state.user;
    
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) => CloseShiftDialog(
        onConfirm: (actualCash, notes) {
          final shiftId = overview.shiftId;
          if (shiftId != null) {
            shiftCubit.closeShift(shiftId, actualCash, notes, user?.loungeId ?? '');
            Navigator.pop(diagContext);
            _refreshOverview();
          }
        },
      ),
    );
  }
}
