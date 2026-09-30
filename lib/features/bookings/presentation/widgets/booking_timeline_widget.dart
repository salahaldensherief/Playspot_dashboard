import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_section_header.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

/// Compact and clear visual timeline representing the lifecycle of a booking.
class BookingTimelineWidget extends StatelessWidget {
  final Booking booking;

  const BookingTimelineWidget({super.key, required this.booking});

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd/MM HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled =
        booking.status == BookingStatus.cancelled ||
        booking.status == BookingStatus.rejected;
    final isCompleted = booking.status == BookingStatus.completed;
    final isInProgress = booking.status == BookingStatus.inProgress;
    final hasCheckedIn =
        booking.checkedInAt != null || isInProgress || isCompleted;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: AppStrings.bookingTimeline,
            icon: Icons.timeline_rounded,
            iconColor: AppColors.neonBlue,
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Booking Placed
              Expanded(
                child: _buildTimelineStep(
                  title: AppStrings.bookingCreated,
                  subtitle: booking.createdAt != null
                      ? _formatDateTime(booking.createdAt!)
                      : '--:--',
                  isDone: true,
                  isActive: false,
                  stepColor: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
              ),

              _buildConnector(isDone: hasCheckedIn || isCancelled),

              // Step 2: Check-in / In-progress or Cancelled
              if (isCancelled) ...[
                Expanded(
                  child: _buildTimelineStep(
                    title: AppStrings.bookingCancelledTimeline,
                    subtitle: booking.cancelledAt != null
                        ? _formatDateTime(booking.cancelledAt!)
                        : (booking.cancellationReason ?? AppStrings.cancelled),
                    isDone: true,
                    isActive: false,
                    stepColor: AppColors.danger,
                    icon: Icons.cancel_rounded,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: _buildTimelineStep(
                    title: AppStrings.sessionStarted,
                    subtitle: booking.checkedInAt != null
                        ? _formatDateTime(booking.checkedInAt!)
                        : (isInProgress ? AppStrings.inProgress : '--:--'),
                    isDone: hasCheckedIn,
                    isActive: isInProgress,
                    stepColor: isInProgress
                        ? AppColors.neonBlue
                        : (hasCheckedIn
                              ? AppColors.success
                              : AppColors.textSecondary),
                    icon: isInProgress
                        ? Icons.play_circle_filled_rounded
                        : Icons.check_circle_rounded,
                  ),
                ),

                _buildConnector(isDone: isCompleted),

                // Step 3: Completed
                Expanded(
                  child: _buildTimelineStep(
                    title: AppStrings.bookingCompletedTimeline,
                    subtitle: '--:--',
                    isDone: isCompleted,
                    isActive: false,
                    stepColor: isCompleted
                        ? AppColors.success
                        : AppColors.textSecondary,
                    icon: isCompleted
                        ? Icons.task_alt_rounded
                        : Icons.radio_button_unchecked_rounded,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({required bool isDone}) {
    return Container(
      width: 24.w,
      height: 2.h,
      margin: EdgeInsets.only(top: 14.h),
      color: isDone
          ? AppColors.success.withValues(alpha: 0.6)
          : AppColors.borderDefault,
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    required Color stepColor,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20.r,
          color: isActive
              ? AppColors.neonBlue
              : (isDone ? stepColor : AppColors.textSecondary),
        ),
        SizedBox(height: 6.h),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDone || isActive
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontSize: 11.sp,
            fontWeight: isDone || isActive
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDone ? stepColor : AppColors.textSecondary,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}
