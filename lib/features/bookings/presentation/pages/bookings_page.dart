import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import '../cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../widgets/bookings_header.dart';
import '../widgets/bookings_data_table.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.read<LoginCubit>().state.admin;
    
    return BlocProvider(
      create: (context) => sl<BookingCubit>()..startWatchingBookings(loungeId: admin?.loungeId),
      child:  DashboardLayout(
        title: 'Live Operations',
        activeRoute: AppStrings.bookings,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookingsHeader(),
            SizedBox(height: 32.h),
            BookingsDataTable(),
          ],
        ),
      ),
    );
  }
}
