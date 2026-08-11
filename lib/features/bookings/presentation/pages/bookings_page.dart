import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../widgets/bookings_header.dart';
import '../widgets/bookings_data_table.dart';
import '../../domain/entities/booking.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BookingCubit _bookingCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = context.read<LoginCubit>().state.user;
    _bookingCubit = sl<BookingCubit>()..startWatchingBookings(loungeId: user?.loungeId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bookingCubit,
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
                  if (state is BookingLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
                  }
                  
                  final allBookings = state is BookingLoaded ? state.bookings : <Booking>[];
                  
                  // طلبات الحجز الجديدة فقط
                  final pendingRequests = allBookings.where((b) => b.status == BookingStatus.pending).toList();
                  
                  // الحجوزات المقبولة (Active)
                  final activeBookings = allBookings.where((b) => b.status == BookingStatus.upcoming).toList();

                  return TabBarView(
                    controller: _tabController,
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
        controller: _tabController,
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
