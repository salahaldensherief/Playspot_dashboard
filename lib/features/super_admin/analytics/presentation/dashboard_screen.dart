import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_sidebar.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_top_bar.dart' as art_top_bar;
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/admin_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/presentation/widgets/room_status_card.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';
import 'widgets/chart_card.dart';
import 'widgets/top_lounges_card.dart';
import 'widgets/utilization_chart.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_activities.dart';

class DashboardScreen extends StatelessWidget {
  final AdminRole role;
  
  const DashboardScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final admin = context.read<LoginCubit>().state.admin;
    final loungeId = admin?.loungeId;

    return BlocProvider(
      create: (context) => sl<BookingCubit>()..startWatchingBookings(loungeId: loungeId),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Row(
          children: [
            DashboardSidebar(activeRoute: AppStrings.dashboard),
            Expanded(
              child: Column(
                children: [
                  const art_top_bar.DashboardTopBar(title: 'Command & Control'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(32.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          SizedBox(height: 32.h),
                          _buildStatsGrid(),
                          SizedBox(height: 32.h),
                          _buildChartsRow(),
                          SizedBox(height: 32.h),
                          _buildBottomSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          role == AdminRole.superAdmin 
            ? 'Global performance monitoring and system health'
            : 'Live lounge operations and resource management',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        const Expanded(
          child: StatCard(
            title: 'Daily Revenue',
            value: '\$1,240',
            trend: '+12%',
            icon: Icons.payments_outlined,
            iconColor: AppColors.neonGreen,
          ),
        ),
        SizedBox(width: 24.w),
        const Expanded(
          child: StatCard(
            title: 'Active Sessions',
            value: '42',
            trend: '+5',
            icon: Icons.sports_esports_outlined,
            iconColor: AppColors.neonBlue,
          ),
        ),
        SizedBox(width: 24.w),
        const Expanded(
          child: StatCard(
            title: 'Lounge Occupancy',
            value: '84%',
            trend: '+2.4%',
            icon: Icons.meeting_room_outlined,
            iconColor: AppColors.neonPurple,
          ),
        ),
        SizedBox(width: 24.w),
        const Expanded(
          child: StatCard(
            title: 'System Health',
            value: 'Optimal',
            trend: 'Stable',
            icon: Icons.dns_outlined,
            iconColor: AppColors.neonCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildChartsRow() {
    return SizedBox(
      height: 350.h,
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: ChartCard(
              title: 'Revenue Analytics',
              subtitle: 'Weekly financial performance',
              actionIcon: Icons.trending_up,
              actionIconColor: AppColors.success,
              chart: RevenueChart(),
            ),
          ),
          SizedBox(width: 24.w),
          const Expanded(
            flex: 1,
            child: ChartCard(
              title: 'Room Utilization',
              subtitle: 'Current capacity tracking',
              actionIcon: Icons.pie_chart_outline,
              actionIconColor: AppColors.neonPurple,
              chart: UtilizationChart(),
            ),
          ),
          SizedBox(width: 24.w),
          const Expanded(
            flex: 1,
            child: QuickActionsCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildLiveBookingsFeed(),
              SizedBox(height: 24.h),
              const TopLoungesCard(),
            ],
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const RecentActivityCard(),
              SizedBox(height: 24.h),
              const RoomStatusCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBookingsFeed() {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12.r,
                        height: 12.r,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Live Bookings Feed',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (state is BookingLoading) 
                    SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              SizedBox(height: 20.h),
              if (state is BookingLoaded)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.bookings.take(5).length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.divider, height: 32.h),
                  itemBuilder: (context, index) {
                    final booking = state.bookings[index];
                    return _LiveBookingItem(
                      customerName: 'User ${booking.userId.substring(0, 5)}',
                      roomName: 'Room ${booking.roomId.substring(0, 3)}',
                      startTime: '14:30', // Simplified
                      status: booking.status.name,
                      onConfirm: () => context.read<BookingCubit>().confirmCashPayment(booking.id),
                    );
                  },
                )
              else if (state is BookingError)
                Text('Error loading live feed: ${state.message}', style: const TextStyle(color: AppColors.danger))
              else
                const Text('Waiting for live updates...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

class _LiveBookingItem extends StatelessWidget {
  final String customerName;
  final String roomName;
  final String startTime;
  final String status;
  final VoidCallback onConfirm;

  const _LiveBookingItem({
    required this.customerName,
    required this.roomName,
    required this.startTime,
    required this.status,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.neonBlue.withOpacity(0.1),
          child: Icon(Icons.person_outline, color: AppColors.neonBlue, size: 20.r),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customerName, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              Text('$roomName • $startTime', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.neonBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(status.toUpperCase(), style: TextStyle(color: AppColors.neonBlue, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 16.w),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success.withOpacity(0.1),
            foregroundColor: AppColors.success,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          child: Text('Confirm Cash', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
