import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import 'start_session_button.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onConfirmPayment;
  final VoidCallback? onStartSession;
  final VoidCallback? onNoShow;

  const BookingCard({
    super.key,
    required this.booking,
    this.onApprove,
    this.onReject,
    this.onConfirmPayment,
    this.onStartSession,
    this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == BookingStatus.pending;
    final isPaid = booking.paymentStatus == PaymentStatus.paid;
    final isCanStartSession = booking.status == BookingStatus.pending || booking.status == BookingStatus.upcoming;
    final isOverdue = _isPastStartTime(booking);
    final bool canAddItems = context.hasPermission('pos_view_menu') &&
        (booking.status == BookingStatus.upcoming || booking.status == BookingStatus.inProgress);

    final String formattedDuration = (booking.durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');

    return Container(
      width: 280.w,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isOverdue ? AppColors.danger.withValues(alpha: 0.5) : AppColors.borderDefault,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdue ? AppColors.danger.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _getStatusBadge(booking.status),
              AppText.body(
                _formatTime(booking.startTime),
                fontSize: 10.sp,
                color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ],
          ),
          SizedBox(height: 10.h),

          AppText.subHeading(booking.userName ?? AppStrings.anonymous, fontSize: 14.sp, maxLines: 1),

          if (booking.userPhone != null && booking.userPhone?.isNotEmpty == true)
            AppText.body(booking.userPhone ?? '', fontSize: 11.sp, color: AppColors.neonBlue),

          SizedBox(height: 6.h),

          _buildInfoRow(Icons.meeting_room_outlined, '${booking.roomName} ($formattedDuration hrs)', AppColors.neonPurple),

          if (booking.extras.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(6.r),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...booking.extras.map((item) => Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: AppText.body(
                      "• ${item['quantity']}x ${item['name_en'] ?? item['name']}",
                      fontSize: 10.sp,
                      color: AppColors.textPrimary,
                    ),
                  )),
                ],
              ),
            ),
          ],

          SizedBox(height: 12.h),
          const Divider(color: AppColors.borderDefault, height: 1),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(AppStrings.totalPrice, fontSize: 9.sp),
                  AppText.subHeading('${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}', color: AppColors.neonBlue, fontSize: 14.sp, fontWeight: FontWeight.bold),
                ],
              ),
              isPaid ? StatusBadge.success(AppStrings.paid) : StatusBadge.warning(AppStrings.unpaid),
            ],
          ),

          if (isPending || isCanStartSession || (!isPaid && onConfirmPayment != null) || canAddItems) ...[
            SizedBox(height: 10.h),
            if (isCanStartSession)
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: StartSessionButton(
                        bookingId: booking.id,
                        bookingDate: booking.date,
                        startTime: booking.startTime,
                        onSuccess: onStartSession,
                        height: 32.h,
                      ),
                    ),
                    if (isCanStartSession) ...[
                      SizedBox(width: 8.w),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          text: AppStrings.noShow,
                          icon: Icons.person_off_outlined,
                          variant: AppButtonVariant.outlined,
                          height: 32.h,
                          onPressed: isOverdue ? () => _showNoShowConfirmDialog(context) : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: AppStrings.approve,
                      onPressed: () {
                        debugPrint('🟢 [UI] APPROVE CLICKED FOR BOOKING: ${booking.id}');
                        if (onApprove != null) {
                          onApprove!();
                        } else {
                          debugPrint('⚠️ onApprove callback was null - triggering context.read<BookingCubit>().approveBooking directly');
                          context.read<BookingCubit>().approveBooking(booking.id);
                        }
                      },
                      height: 30.h,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AppButton(
                      text: AppStrings.reject,
                      variant: AppButtonVariant.outlined,
                      onPressed: () {
                        debugPrint('🔴 [UI] REJECT CLICKED FOR BOOKING: ${booking.id}');
                        if (onReject != null) {
                          onReject!();
                        } else {
                          context.read<BookingCubit>().rejectBooking(booking.id);
                        }
                      },
                      height: 30.h,
                    ),
                  ),
                ],
              )
            else ...[
              if (canAddItems)
                Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: AppButton(
                    text: AppStrings.addNew,
                    onPressed: () => _showAddExtrasDialog(context),
                    width: double.infinity,
                    height: 32.h,
                    variant: AppButtonVariant.outlined,
                    icon: Icons.add_shopping_cart,
                  ),
                ),
              if (!isPaid && onConfirmPayment != null)
                AppButton(
                  text: AppStrings.confirmCash,
                  onPressed: onConfirmPayment ?? () {},
                  width: double.infinity,
                  height: 32.h,
                  icon: Icons.payments_outlined,
                ),
            ],
          ],
        ],
      ),
    );
  }

  bool _isPastStartTime(Booking booking) {
    if (booking.status != BookingStatus.pending && booking.status != BookingStatus.upcoming) {
      return false;
    }
    try {
      final date = booking.date;
      final parts = booking.startTime.trim().split(':');
      if (parts.length < 2) return false;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final scheduledStart = DateTime(date.year, date.month, date.day, hour, minute);
      final now = DateTime.now();
      return now.isAfter(scheduledStart) || now.isAtSameMomentAs(scheduledStart);
    } catch (e) {
      return false;
    }
  }

  void _showNoShowConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Row(
          children: [
            const Icon(Icons.person_off, color: AppColors.danger),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText.subHeading(
                AppStrings.confirmNoShow,
                color: AppColors.danger,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        content: AppText.body(
          AppStrings.confirmNoShowMessage,
          fontSize: 13.sp,
          color: AppColors.textPrimary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: AppText.body(AppStrings.cancel, color: AppColors.textSecondary),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final cubit = context.read<BookingCubit>();
              final success = await cubit.markNoShow(booking.id);
              if (onNoShow != null) {
                onNoShow!();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? AppStrings.noShowSuccess : AppStrings.noShowFailed),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: AppText.body(AppStrings.markNoShow, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return timeStr;
    }
  }

  void _showAddExtrasDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.underConstruction)),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        SizedBox(width: 6.w),
        Expanded(child: AppText.body(text, fontSize: 11.sp, color: AppColors.textPrimary, maxLines: 1)),
      ],
    );
  }

  Widget _getStatusBadge(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return StatusBadge.warning(AppStrings.pending.toUpperCase());
      case BookingStatus.upcoming: return StatusBadge.info(AppStrings.upcoming.toUpperCase());
      case BookingStatus.inProgress: return StatusBadge.success(AppStrings.inProgress.toUpperCase());
      case BookingStatus.completed: return StatusBadge.success(AppStrings.completed.toUpperCase());
      case BookingStatus.cancelled: return StatusBadge.danger(AppStrings.cancelled.toUpperCase());
    }
  }
}
