import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import '../../domain/entities/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onConfirmPayment;

  const BookingCard({
    super.key,
    required this.booking,
    this.onApprove,
    this.onReject,
    this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == BookingStatus.pending;
    final isPaid = booking.paymentStatus == PaymentStatus.paid;
    final bool canAddItems = context.hasPermission('pos_view_menu') && 
                            (booking.status == BookingStatus.upcoming || booking.status == BookingStatus.inProgress);

    final String formattedDuration = (booking.durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');
    final String timeRange = '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)} ($formattedDuration hrs)';

    return Container(
      width: 280.w, // Slightly narrower for better grid fitting
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Shrink to fit content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _getStatusBadge(booking.status),
              AppText.body(
                _formatTime(booking.startTime),
                fontSize: 10.sp,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          
          AppText.subHeading(booking.userName ?? AppStrings.anonymous, fontSize: 14.sp, maxLines: 1),
          
          if (booking.userPhone != null && booking.userPhone!.isNotEmpty)
            AppText.body(booking.userPhone!, fontSize: 11.sp, color: AppColors.neonBlue),

          SizedBox(height: 6.h),
          
          // Room Info
          _buildInfoRow(Icons.meeting_room_outlined, '${booking.roomName} ($formattedDuration hrs)', AppColors.neonPurple),

          // Extras Info - Dynamic Height
          if (booking.extras.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(6.r),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
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
                  )).toList(),
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
          
          if (isPending || (!isPaid && onConfirmPayment != null) || canAddItems) ...[
            SizedBox(height: 10.h),
            if (isPending)
              Row(
                children: [
                  Expanded(child: AppButton(text: AppStrings.approve, onPressed: onApprove ?? () {}, height: 30.h)),
                  SizedBox(width: 8.w),
                  Expanded(child: AppButton(text: AppStrings.reject, variant: AppButtonVariant.outlined, onPressed: onReject ?? () {}, height: 30.h)),
                ],
              )
            else ...[
              if (canAddItems)
                Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: AppButton(
                    text: "Add Items", 
                    onPressed: () => _showAddExtrasDialog(context), 
                    width: double.infinity, 
                    height: 32.h, 
                    variant: AppButtonVariant.outlined,
                    icon: Icons.add_shopping_cart,
                  ),
                ),
              if (!isPaid && onConfirmPayment != null)
                AppButton(text: AppStrings.confirmCash, onPressed: onConfirmPayment!, width: double.infinity, height: 32.h, icon: Icons.payments_outlined),
            ],
          ],
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
      const SnackBar(content: Text("Add Items Dialog - Coming Soon")),
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
      case BookingStatus.pending: return StatusBadge.warning('NEW');
      case BookingStatus.upcoming: return StatusBadge.info('ACCEPTED');
      case BookingStatus.completed: return StatusBadge.success('FINISHED');
      case BookingStatus.cancelled: return StatusBadge.danger('CANCELLED');
      default: return StatusBadge.info(status.name.toUpperCase());
    }
  }
}
