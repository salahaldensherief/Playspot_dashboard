import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';

class BookingsCockpitTabs extends StatelessWidget {
  final TabController tabController;
  final dynamic userLounge;
  final bool isDesktop;
  final bool isTableView;
  final VoidCallback onToggleTableView;

  const BookingsCockpitTabs({
    super.key,
    required this.tabController,
    required this.userLounge,
    required this.isDesktop,
    required this.isTableView,
    required this.onToggleTableView,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      buildWhen: (prev, curr) =>
          prev.bookings != curr.bookings || prev.status != curr.status,
      builder: (context, bookingState) {
        return BlocBuilder<ShiftCubit, ShiftState>(
          buildWhen: (prev, curr) => prev.activeShift != curr.activeShift,
          builder: (context, shiftState) {
            final activeShift = shiftState.activeShift;
            final activeCount = bookingState.activeBookings.length;
            final pendingCount = bookingState.pendingBookings.length;
            final finishedCount = bookingState
                .currentShiftBookings(activeShift: activeShift, userLounge: userLounge)
                .length;
            final cancelledCount = bookingState
                .currentShiftCancelledBookings(activeShift: activeShift, userLounge: userLounge)
                .length;

            return Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48.h,
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: TabBar(
                      controller: tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonBlue.withValues(alpha: 0.3),
                            AppColors.neonPurple.withValues(alpha: 0.3),
                          ],
                        ),
                        border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.5)),
                      ),
                      labelColor: AppColors.neonBlue,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                      tabs: [
                        Tab(text: '${AppStrings.activeBookings} ($activeCount)'),
                        Tab(text: '${AppStrings.pendingRequests} ($pendingCount)'),
                        Tab(text: '${AppStrings.finishedToday} ($finishedCount)'),
                        Tab(text: '${AppStrings.cancelled} ($cancelledCount)'),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                if (!isDesktop) ...[
                  BlocSelector<ClientRequestsCubit, ClientRequestsState, int>(
                    selector: (state) => state.unreadCount,
                    builder: (drawerContext, unreadRequestsCount) {
                      return Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: IconButton(
                          tooltip: AppStrings.clientRequestsAndAlerts,
                          icon: Badge(
                            isLabelVisible: unreadRequestsCount > 0,
                            label: Text('$unreadRequestsCount'),
                            backgroundColor: AppColors.warning,
                            child: const Icon(Icons.bolt_rounded, color: AppColors.warning),
                          ),
                          onPressed: () => Scaffold.of(drawerContext).openEndDrawer(),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 8.w),
                ],
                Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: IconButton(
                    tooltip: isTableView ? 'عرض كبطاقات' : 'عرض كجدول',
                    icon: Icon(
                      isTableView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                      color: AppColors.neonBlue,
                    ),
                    onPressed: onToggleTableView,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
