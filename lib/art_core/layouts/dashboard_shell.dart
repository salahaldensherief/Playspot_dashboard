import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'dashboard_sidebar.dart';
import 'dashboard_top_bar.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/shifts/presentation/shift_management/shift_cubit.dart';
import '../../features/shifts/presentation/shift_management/widgets/shift_header_banner.dart';
import '../../core/di/di.dart';
import '../widgets/geolocation_handler.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  final String location;

  const DashboardShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final isSuperAdmin = user?.role == UserRole.superAdmin;
    // ... rest of the logic
    String activeRoute = '';
    String title = AppStrings.dashboard;

    if (location.contains('dashboard')) {
      activeRoute = AppStrings.dashboard;
      title = AppStrings.systemOverview;
    } else if (location.contains('lounges')) {
      activeRoute = AppStrings.lounges;
      title = AppStrings.lounges;
    } else if (location.contains('rooms')) {
      activeRoute = AppStrings.rooms;
      title = AppStrings.manageRoomsDesc;
    } else if (location.contains('live-operations')) {
      activeRoute = AppStrings.bookings;
      title = AppStrings.liveBookingsFeed;
    } else if (location.contains('users')) {
      activeRoute = AppStrings.users;
      title = AppStrings.loungeAdministrators;
    } else if (location.contains('marketing')) {
      activeRoute = AppStrings.marketing;
      title = AppStrings.marketing;
    } else if (location.contains('payouts')) {
      activeRoute = isSuperAdmin ? AppStrings.payouts : AppStrings.myPayouts;
      title = isSuperAdmin ? AppStrings.loungePayouts : AppStrings.payoutHistory;
    } else if (location.contains('kyc')) {
      activeRoute = AppStrings.kycReviews;
      title = AppStrings.kycReviews;
    } else if (location.contains('loyalty')) {
      activeRoute = AppStrings.loyaltyRewards;
      title = AppStrings.loyaltyRewards;
    } else if (location.contains('shifts')) {
      activeRoute = AppStrings.shiftHistory;
      title = AppStrings.shiftHistory;
    } else if (location.contains('staff')) {
      activeRoute = AppStrings.staffManagement;
      title = AppStrings.staffManagement;
    } else if (location.contains('reports')) {
      activeRoute = AppStrings.monthlyReports;
      title = AppStrings.monthlyReports;
    } else if (location.contains('profile')) {
      activeRoute = AppStrings.myProfile;
      title = AppStrings.myProfile;
    }

    return GeolocationHandler(
      child: BlocProvider(
        create: (context) => sl<ShiftCubit>()..checkActiveShift(user?.id ?? ''),
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Row(
            children: [
              DashboardSidebar(activeRoute: activeRoute),
              Expanded(
                child: Column(
                  children: [
                    DashboardTopBar(title: title),
                    if (!isSuperAdmin) const ShiftHeaderBanner(),
                    Expanded(
                      child: child,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
