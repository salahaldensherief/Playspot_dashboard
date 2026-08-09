import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_sidebar.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_top_bar.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import '../cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.read<LoginCubit>().state.admin;
    
    return BlocProvider(
      create: (context) => sl<BookingCubit>()..startWatchingBookings(loungeId: admin?.loungeId),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Row(
          children: [
            const DashboardSidebar(activeRoute: AppStrings.bookings),
            Expanded(
              child: Column(
                children: [
                  const DashboardTopBar(title: 'Live Operations'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(32.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          SizedBox(height: 32.h),
                          _buildLiveFeedTable(),
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
        Row(
          children: [
            Container(
              width: 12.r,
              height: 12.r,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            ),
            SizedBox(width: 12.w),
            Text(
              'Live Operations Feed',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          'Real-time booking monitor with instant audio alerts',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildLiveFeedTable() {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }
        
        final bookings = state is BookingLoaded ? state.bookings : [];
        
        return DataTableWidget(
          columns: const ['ID', 'Customer', 'Room', 'Activity', 'Schedule', 'Status', 'Confirm Payment'],
          rows: bookings.map((b) => DataRow(
            cells: [
              DataCell(Text(b.id.substring(0, 8), style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(Text('User ${b.userId.substring(0, 5)}', style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(Text('Room ${b.roomId.substring(0, 3)}', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text('Gaming', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text('Today 14:00', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(_getStatusBadge(b.status.name)),
              DataCell(
                ElevatedButton(
                  onPressed: () => context.read<BookingCubit>().confirmCashPayment(b.id),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success.withOpacity(0.1), foregroundColor: AppColors.success),
                  child: const Text('Confirm Cash'),
                ),
              ),
            ],
          )).toList(),
        );
      },
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status) {
      case 'upcoming': return StatusBadge.info('Upcoming');
      case 'completed': return StatusBadge.success('Completed');
      case 'cancelled': return StatusBadge.danger('Cancelled');
      default: return StatusBadge.info(status);
    }
  }
}
