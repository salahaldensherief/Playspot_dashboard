import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../widgets/bookings_header.dart';
import '../widgets/bookings_data_table.dart';
import '../../domain/entities/booking.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BookingsHeader(),
            SizedBox(height: 32.h),
            _buildTabs(),
            SizedBox(height: 24.h),
            Expanded(
              child: BlocBuilder<BookingCubit, BookingState>(
                builder: (context, state) {
                  if (state.status == BookingStatusState.loading && state.bookings.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
                  }
                  
                  final allBookings = state.bookings;
                  final pendingRequests = allBookings.where((b) => b.status == BookingStatus.pending).toList();
                  final activeBookings = allBookings.where((b) => b.status == BookingStatus.upcoming).toList();

                  return TabBarView(
                    children: [
                      SingleChildScrollView(child: BookingsDataTable(filteredBookings: pendingRequests)),
                      SingleChildScrollView(child: BookingsDataTable(filteredBookings: activeBookings)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: TabBar(
        isScrollable: true,
        indicatorColor: AppColors.neonBlue,
        labelColor: AppColors.neonBlue,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: [
          Tab(text: AppStrings.pendingRequests),
          Tab(text: AppStrings.activeBookings),
        ],
      ),
    );
  }
}
