import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_active_section.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_available_section.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_walk_in_section.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class RoomOccupancyCard extends StatelessWidget {
  final RoomEntity room;
  final Booking? activeBooking;
  final String loungeId;

  const RoomOccupancyCard({
    super.key,
    required this.room,
    this.activeBooking,
    required this.loungeId,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final activeBooking = this.activeBooking;
    final isOccupiedByApp =
        activeBooking != null && activeBooking.isBookingActive();
    final isOccupiedByWalkIn =
        room.status == RoomStatusEnum.occupied && !isOccupiedByApp;
    final isOccupied = isOccupiedByApp || isOccupiedByWalkIn;
    final isMaintenance = room.status == RoomStatusEnum.maintenance;

    Color borderColor = AppColors.borderDefault;
    Color statusColor = AppColors.success;
    String statusText = 'room_available'.tr();

    if (isMaintenance) {
      borderColor = AppColors.warning.withValues(alpha: 0.5);
      statusColor = AppColors.warning;
      statusText = 'room_maintenance'.tr();
    } else if (isOccupied) {
      borderColor = AppColors.danger.withValues(alpha: 0.6);
      statusColor = AppColors.danger;
      statusText = 'room_occupied'.tr();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = screenWidth < 360 ? double.infinity : 320.w;

    return Container(
      width: cardWidth,
      constraints: BoxConstraints(maxWidth: 320.w),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: isOccupied ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: isOccupied
                ? AppColors.danger.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Room Name & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      room.isOpenArea
                          ? Icons.grid_view_rounded
                          : Icons.sports_esports_rounded,
                      size: 18.r,
                      color: isOccupied ? AppColors.danger : AppColors.neonBlue,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppText.subHeading(
                        room.nameAr.isNotEmpty ? room.nameAr : room.nameEn,
                        fontSize: 15.sp,
                        color: AppColors.textPrimary,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Specs Subtitle Bar
          Row(
            children: [
              AppText.body(
                '${room.capacity} ${AppStrings.persons}',
                fontSize: 10.sp,
                color: AppColors.textMuted,
              ),
              SizedBox(width: 8.w),
              AppText.body('•', fontSize: 10.sp, color: AppColors.textMuted),
              SizedBox(width: 8.w),
              AppText.body(
                '${room.controllersCount} ${AppStrings.controllers}',
                fontSize: 10.sp,
                color: AppColors.textMuted,
              ),
              if (room.screenSize.isNotEmpty) ...[
                SizedBox(width: 8.w),
                AppText.body('•', fontSize: 10.sp, color: AppColors.textMuted),
                SizedBox(width: 8.w),
                AppText.body(
                  room.screenSize,
                  fontSize: 10.sp,
                  color: AppColors.neonBlue,
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),

          // Body Content: App Booking vs Walk-In vs Maintenance vs Available
          if (isOccupiedByApp) ...[
            RoomOccupancyActiveSection(
              activeBooking: activeBooking,
              room: room,
            ),
          ] else if (isOccupiedByWalkIn) ...[
            RoomOccupancyWalkInSection(room: room),
          ] else if (isMaintenance) ...[
            _buildMaintenanceContent(),
          ] else ...[
            RoomOccupancyAvailableSection(room: room, loungeId: loungeId),
          ],
        ],
      ),
    );
  }

  Widget _buildMaintenanceContent() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.build_outlined, color: AppColors.warning, size: 16.r),
          SizedBox(width: 8.w),
          Expanded(
            child: AppText.body(
              'station_under_maintenance'.tr(),
              fontSize: 11.sp,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
