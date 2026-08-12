import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../domain/entities/booking.dart';

class BookingDetailsDialog extends StatelessWidget {
  final Booking booking;
  final VoidCallback onConfirmPayment;
  final VoidCallback onCancel;

  const BookingDetailsDialog({
    super.key,
    required this.booking,
    required this.onConfirmPayment,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 700.w,
        padding: EdgeInsets.all(32.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 24.h),
              _buildInfoGrid(),
              if (booking.extras.isNotEmpty) ...[
                SizedBox(height: 24.h),
                _buildExtrasSection(),
              ],
              SizedBox(height: 32.h),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.heading(AppStrings.bookingDetails, fontSize: 24.sp),
            SizedBox(height: 4.h),
            AppText.body('ID: ${booking.id}', fontSize: 12.sp),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      children: [
        _buildInfoItem(AppStrings.customerName, booking.userName ?? AppStrings.anonymous),
        _buildInfoItem('Phone Number', booking.userPhone ?? '-'),
        _buildInfoItem(AppStrings.roomLabel, booking.roomName),
        _buildInfoItem(AppStrings.schedule, '${booking.startTime} - ${booking.endTime}'),
        _buildInfoItem(AppStrings.date, DateFormat('MMM dd, yyyy').format(booking.date)),
        _buildInfoItem(AppStrings.totalPrice, '${booking.totalPrice.toStringAsFixed(2)} ${AppStrings.egp}', valueColor: AppColors.neonBlue),
        _buildInfoItem(AppStrings.payment, booking.paymentStatus == 'paid' ? AppStrings.paid : AppStrings.unpaid),
        _buildInfoItem(AppStrings.status, '', customWidget: _getStatusBadge(booking.status)),
      ],
    );
  }

  Widget _buildExtrasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fastfood_outlined, color: AppColors.neonBlue, size: 20),
            SizedBox(width: 8.w),
            AppText.subHeading('Additional Items', fontSize: 18.sp),
          ],
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: booking.extras.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.body('${item['quantity']}x ${item['name_en'] ?? item['name']}', color: AppColors.textPrimary),
                  AppText.body('${item['price'] ?? 0} ${AppStrings.egp}', color: AppColors.textSecondary),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor, Widget? customWidget}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontSize: 12.sp),
        SizedBox(height: 4.h),
        customWidget ?? AppText.subHeading(
          value,
          fontSize: 16.sp,
          color: valueColor,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton(
          text: AppStrings.cancelBooking,
          variant: AppButtonVariant.outlined,
          onPressed: () {
            onCancel();
            Navigator.pop(context);
          },
        ),
        SizedBox(width: 16.w),
        if (booking.paymentStatus != 'paid')
          AppButton(
            text: AppStrings.confirmCash,
            onPressed: () {
              onConfirmPayment();
              Navigator.pop(context);
            },
          ),
      ],
    );
  }

  Widget _getStatusBadge(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return StatusBadge.warning('REQUESTED');
      case BookingStatus.upcoming: return StatusBadge.info('ACCEPTED');
      case BookingStatus.completed: return StatusBadge.success('FINISHED');
      case BookingStatus.cancelled: return StatusBadge.danger('CANCELLED');
      default: return StatusBadge.info(status.name.toUpperCase());
    }
  }
}
