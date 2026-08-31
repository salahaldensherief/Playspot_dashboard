import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../cubit/lounge_stats_cubit.dart';
import '../cubit/lounge_stats_state.dart';

class LoungeOwnerAnalyticsGrid extends StatelessWidget {
  const LoungeOwnerAnalyticsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId;

    return BlocBuilder<LoungeStatsCubit, LoungeStatsState>(
      buildWhen: (prev, curr) => prev.status != curr.status || prev.stats != curr.stats,
      builder: (context, state) {
        if (state.status == LoungeStatsStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }

        if (state.status == LoungeStatsStatus.failure) {
          return Center(child: Text(state.errorMessage ?? 'Error', style: const TextStyle(color: AppColors.danger)));
        }

        final stats = state.stats;
        if (stats == null) return const SizedBox.shrink();

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsive.isMobile(context)
                ? 1
                : Responsive.isTablet(context)
                    ? 2
                    : 4,
            crossAxisSpacing: 24.w,
            mainAxisSpacing: 24.h,
            mainAxisExtent: 180.h,
          ),
          children: [
            // Today's Revenue
            StatCard(
              title: AppStrings.dailyTotal,
              value: '${stats.todayRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
              trendValue: 0.0,
              subtitle: 'Today\'s Earnings',
              icon: Icons.today_outlined,
              iconColor: AppColors.neonGreen,
            ),

            // Monthly Revenue
            StatCard(
              title: AppStrings.totalRevenue,
              value: '${stats.monthlyRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
              trendValue: 0.0,
              subtitle: 'Current Month',
              icon: Icons.calendar_month_outlined,
              iconColor: AppColors.neonCyan,
            ),

            // Room Occupancy Gauge
            _OccupancyGaugeCard(
              occupied: stats.occupiedRooms,
              total: stats.totalRooms,
              rate: stats.occupancyRate,
            ),

            // Status Alerts (Shifts & Stock)
            _StatusAlertsCard(
              openShifts: stats.openShifts,
              lowStock: stats.lowStockItems,
            ),
          ],
        );
      },
    );
  }
}

class _OccupancyGaugeCard extends StatelessWidget {
  final int occupied;
  final int total;
  final double rate;

  const _OccupancyGaugeCard({
    required this.occupied,
    required this.total,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.loungeOccupancy,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
              Icon(Icons.meeting_room_outlined, color: AppColors.neonPurple, size: 20.r),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$occupied / $total',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 24.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(rate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: AppColors.neonPurple, fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60.r,
                height: 60.r,
                child: CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8,
                  backgroundColor: AppColors.neonPurple.withOpacity(0.1),
                  color: AppColors.neonPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusAlertsCard extends StatelessWidget {
  final int openShifts;
  final int lowStock;

  const _StatusAlertsCard({
    required this.openShifts,
    required this.lowStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Operational Status',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16.h),
          _AlertItem(
            icon: Icons.access_time_filled_outlined,
            label: 'Active Shifts',
            value: openShifts.toString(),
            color: openShifts > 0 ? AppColors.success : AppColors.warning,
          ),
          SizedBox(height: 12.h),
          _AlertItem(
            icon: Icons.inventory_2_outlined,
            label: 'Low Stock Items',
            value: lowStock.toString(),
            color: lowStock > 0 ? AppColors.danger : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AlertItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 16.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
