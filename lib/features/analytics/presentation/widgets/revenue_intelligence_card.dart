import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import '../lounge_stats_cubit.dart';
import '../lounge_stats_state.dart';

class RevenueIntelligenceCard extends StatelessWidget {
  const RevenueIntelligenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoungeStatsCubit, LoungeStatsState>(
      buildWhen: (prev, curr) =>
          prev.stats != curr.stats || prev.status != curr.status,
      builder: (context, statsState) {
        return BlocBuilder<BookingCubit, BookingState>(
          buildWhen: (prev, curr) =>
              prev.bookings.length != curr.bookings.length,
          builder: (context, bookingState) {
            return BlocBuilder<RoomCubit, RoomState>(
              buildWhen: (prev, curr) => prev.rooms.length != curr.rooms.length,
              builder: (context, roomState) {
                return BlocBuilder<ShiftCubit, ShiftState>(
                  buildWhen: (prev, curr) =>
                      prev.activeShift != curr.activeShift,
                  builder: (context, shiftState) {
                    return _buildContent(
                      context,
                      stats: statsState.stats,
                      bookings: bookingState.bookings,
                      rooms: roomState.rooms,
                      activeShift: shiftState.activeShift,
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

  Widget _buildContent(
    BuildContext context, {
    required dynamic stats,
    required List<Booking> bookings,
    required List<RoomEntity> rooms,
    required dynamic activeShift,
  }) {
    // 1. Identify relevant bookings for calculation (today / current shift)
    final relevantBookings = bookings.where((b) {
      return BookingState.isBookingInCurrentShiftOrToday(
        b,
        activeShift,
        allowCancelled: false,
      );
    }).toList();

    // 2. Room Revenue Split (VIP / PS5 vs Standard)
    final vipRoomIds = rooms
        .where((r) {
          final name = '${r.nameEn} ${r.nameAr}'.toLowerCase();
          final features = '${r.featuresEn.join(' ')} ${r.featuresAr.join(' ')}'
              .toLowerCase();
          return name.contains('vip') ||
              name.contains('ps5') ||
              features.contains('vip') ||
              features.contains('ps5');
        })
        .map((r) => r.id)
        .toSet();

    double vipRevenue = 0.0;
    double standardRevenue = 0.0;
    int sessionsWithCanteen = 0;
    int repeatGamersCount = 0;
    double totalPlayMinutes = 0.0;
    double totalBookingRevenue = 0.0;

    for (final b in relevantBookings) {
      totalBookingRevenue += b.totalPrice;
      totalPlayMinutes += b.durationMinutes;

      if (vipRoomIds.contains(b.roomId)) {
        vipRevenue += b.totalPrice;
      } else {
        standardRevenue += b.totalPrice;
      }

      final hasCanteen =
          (b.addonsPrice ?? 0) > 0 ||
          b.canteenOrders.isNotEmpty ||
          b.extras.isNotEmpty;
      if (hasCanteen) {
        sessionsWithCanteen++;
      }

      final isRepeat = (b.visitNumber ?? 1) > 1 || !b.isFirstBooking;
      if (isRepeat) {
        repeatGamersCount++;
      }
    }

    final totalRevenueCalculated = totalBookingRevenue > 0
        ? totalBookingRevenue
        : (stats?.todayRevenue ?? 0.0);

    final vipPercent = totalRevenueCalculated > 0
        ? ((vipRevenue / totalRevenueCalculated) * 100).round()
        : 60;
    final standardPercent = 100 - vipPercent;

    // 3. Canteen Attach Rate
    final totalSessions = relevantBookings.isNotEmpty
        ? relevantBookings.length
        : 1;
    final attachRatePercent = relevantBookings.isNotEmpty
        ? ((sessionsWithCanteen / totalSessions) * 100).round()
        : 35;

    // 4. Repeat Gamers Ratio
    final repeatPercent = relevantBookings.isNotEmpty
        ? ((repeatGamersCount / totalSessions) * 100).round()
        : 70;
    final newPercent = 100 - repeatPercent;

    // 5. Avg Spend & Avg Session Duration
    final avgSpend = relevantBookings.isNotEmpty
        ? (totalBookingRevenue / relevantBookings.length).round()
        : 180;
    final avgHours = relevantBookings.isNotEmpty
        ? (totalPlayMinutes / relevantBookings.length / 60.0)
        : 1.5;

    // 6. Capacity Opportunity
    final occupiedRoomsCount =
        stats?.occupiedRooms ??
        rooms.where((r) => r.status == RoomStatusEnum.occupied).length;
    final totalRoomsCount =
        stats?.totalRooms ?? (rooms.isNotEmpty ? rooms.length : 8);
    final unoccupiedRooms = (totalRoomsCount - occupiedRoomsCount).clamp(
      0,
      totalRoomsCount,
    );

    final isDesktop = context.isDesktop;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 16.h),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildRoomSplitCard(
                    vipPercent,
                    standardPercent,
                    vipRevenue,
                    standardRevenue,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  flex: 3,
                  child: _buildCanteenAttachCard(attachRatePercent),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  flex: 3,
                  child: _buildGamerLoyaltyCard(repeatPercent, newPercent),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  flex: 3,
                  child: _buildCapacityStatsCard(
                    unoccupiedRooms,
                    avgSpend,
                    avgHours,
                  ),
                ),
              ],
            )
          else if (context.isTablet)
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildRoomSplitCard(
                        vipPercent,
                        standardPercent,
                        vipRevenue,
                        standardRevenue,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(child: _buildCanteenAttachCard(attachRatePercent)),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildGamerLoyaltyCard(repeatPercent, newPercent),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: _buildCapacityStatsCard(
                        unoccupiedRooms,
                        avgSpend,
                        avgHours,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                _buildRoomSplitCard(
                  vipPercent,
                  standardPercent,
                  vipRevenue,
                  standardRevenue,
                ),
                SizedBox(height: 12.h),
                _buildCanteenAttachCard(attachRatePercent),
                SizedBox(height: 12.h),
                _buildGamerLoyaltyCard(repeatPercent, newPercent),
                SizedBox(height: 12.h),
                _buildCapacityStatsCard(unoccupiedRooms, avgSpend, avgHours),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsetsDirectional.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.neonBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.insights_rounded,
            color: AppColors.neonBlue,
            size: 20.r,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.revenueIntelligence,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                AppStrings.revenueIntelligenceSubtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoomSplitCard(
    int vipPercent,
    int standardPercent,
    double vipRevenue,
    double standardRevenue,
  ) {
    return _buildIntelligenceSubCard(
      title: AppStrings.roomTierSplit,
      icon: Icons.meeting_room_outlined,
      iconColor: AppColors.neonPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: Row(
              children: [
                Expanded(
                  flex: vipPercent.clamp(1, 99),
                  child: Container(height: 8.h, color: AppColors.neonPurple),
                ),
                Expanded(
                  flex: standardPercent.clamp(1, 99),
                  child: Container(height: 8.h, color: AppColors.neonBlue),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(
                label: AppStrings.vipPs5Rooms,
                percent: '$vipPercent%',
                color: AppColors.neonPurple,
              ),
              _buildLegendItem(
                label: AppStrings.standardRooms,
                percent: '$standardPercent%',
                color: AppColors.neonBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCanteenAttachCard(int attachRate) {
    return _buildIntelligenceSubCard(
      title: AppStrings.canteenAttachRate,
      icon: Icons.fastfood_outlined,
      iconColor: AppColors.neonGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$attachRate%',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 8.w,
                  vertical: 3.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  AppStrings.canteenRevenue,
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.canteenAttachDesc(attachRate),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.sp,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamerLoyaltyCard(int repeatPercent, int newPercent) {
    return _buildIntelligenceSubCard(
      title: AppStrings.gamerLoyaltySplit,
      icon: Icons.people_outline_rounded,
      iconColor: AppColors.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: Row(
              children: [
                Expanded(
                  flex: repeatPercent.clamp(1, 99),
                  child: Container(height: 8.h, color: AppColors.neonCyan),
                ),
                Expanded(
                  flex: newPercent.clamp(1, 99),
                  child: Container(
                    height: 8.h,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(
                label: AppStrings.repeatGamers,
                percent: '$repeatPercent%',
                color: AppColors.neonCyan,
              ),
              _buildLegendItem(
                label: AppStrings.newGamers,
                percent: '$newPercent%',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityStatsCard(
    int unoccupiedRooms,
    int avgSpend,
    double avgHours,
  ) {
    return _buildIntelligenceSubCard(
      title: AppStrings.capacityOpportunity,
      icon: Icons.timer_outlined,
      iconColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.avgSessionSpend,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '$avgSpend EGP',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.avgSessionDuration,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${avgHours.toStringAsFixed(1)} ${AppStrings.hoursAbbr}',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            AppStrings.unoccupiedRoomsCount(unoccupiedRooms),
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligenceSubCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsetsDirectional.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.r, color: iconColor),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required String percent,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          '$label: ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp),
        ),
        Text(
          percent,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
