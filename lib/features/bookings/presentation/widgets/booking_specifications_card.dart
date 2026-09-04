import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../domain/entities/booking.dart';

/// Reusable UI Card displaying Booking Specifications & Schedule.
class BookingSpecificationsCard extends StatelessWidget {
  final Booking booking;

  const BookingSpecificationsCard({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final loungeName = booking.loungeName.isNotEmpty ? booking.loungeName : AppStrings.lounges;
    final roomName = booking.roomName.isNotEmpty ? booking.roomName : AppStrings.roomLabel;
    final formattedDate = DateFormat('EEE, MMM dd, yyyy').format(booking.date);
    final scheduleText = '${booking.startTime} - ${booking.endTime}';
    final durationText = '${booking.durationMinutes} ${AppStrings.minutesUnit}';
    final guestsText = booking.controllersCount > 0
        ? '${booking.controllersCount} ${AppStrings.controllers}'
        : '1-4 ${AppStrings.persons}';

    final roomSpecsText = [
      if (booking.screenSize.isNotEmpty) booking.screenSize,
      if (booking.controllersCount > 0) '${booking.controllersCount} ${AppStrings.controllers}',
    ].join(' • ');

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined, color: AppColors.neonPurple, size: 20),
              SizedBox(width: 8.w),
              AppText.subHeading(
                AppStrings.bookingSpecifications,
                fontSize: 16.sp,
                color: AppColors.textPrimary,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return Wrap(
                spacing: 16.w,
                runSpacing: 16.h,
                children: [
                  _buildSpecTile(
                    width: isWide ? (constraints.maxWidth - 16.w) / 2 : constraints.maxWidth,
                    icon: Icons.storefront_outlined,
                    label: AppStrings.lounges,
                    value: loungeName,
                    subtitle: booking.loungeLocation.isNotEmpty ? booking.loungeLocation : null,
                  ),
                  _buildSpecTile(
                    width: isWide ? (constraints.maxWidth - 16.w) / 2 : constraints.maxWidth,
                    icon: Icons.sports_esports_outlined,
                    label: AppStrings.roomLabel,
                    value: roomName,
                    subtitle: roomSpecsText.isNotEmpty ? roomSpecsText : null,
                  ),
                  _buildSpecTile(
                    width: isWide ? (constraints.maxWidth - 16.w) / 2 : constraints.maxWidth,
                    icon: Icons.calendar_today_outlined,
                    label: AppStrings.date,
                    value: formattedDate,
                  ),
                  _buildSpecTile(
                    width: isWide ? (constraints.maxWidth - 16.w) / 2 : constraints.maxWidth,
                    icon: Icons.access_time_outlined,
                    label: AppStrings.schedule,
                    value: scheduleText,
                    subtitle: durationText,
                  ),
                  _buildSpecTile(
                    width: isWide ? (constraints.maxWidth - 16.w) / 2 : constraints.maxWidth,
                    icon: Icons.groups_outlined,
                    label: AppStrings.numberOfGuests,
                    value: guestsText,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTile({
    required double width,
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Icon(icon, color: AppColors.neonBlue, size: 18.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(label, fontSize: 11.sp, color: AppColors.textSecondary),
                SizedBox(height: 2.h),
                AppText.subHeading(
                  value,
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  maxLines: 1,
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  AppText.body(
                    subtitle,
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
