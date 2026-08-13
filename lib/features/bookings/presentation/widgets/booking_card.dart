import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
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
    final isPaid = booking.paymentStatus == 'paid';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _getStatusBadge(booking.status),
              AppText.body(
                DateFormat('MMM dd, hh:mm a').format(booking.date),
                fontSize: 11.sp,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          AppText.subHeading(booking.userName ?? AppStrings.anonymous, fontSize: 16.sp, maxLines: 1),
          
          if (booking.userPhone != null && booking.userPhone!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: AppText.body(booking.userPhone!, fontSize: 12.sp, color: AppColors.neonBlue),
            ),

          SizedBox(height: 8.h),
          
          // Room Info
          _buildInfoRow(Icons.meeting_room_outlined, '${booking.roomName} (${booking.startTime} - ${booking.endTime})', AppColors.neonPurple),

          // Extras Info (New Section)
          if (booking.extras.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.neonBlue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fastfood_outlined, size: 12, color: AppColors.neonBlue),
                      SizedBox(width: 4.w),
                      AppText.body("Order Details:", fontSize: 10.sp, fontWeight: FontWeight.bold, color: AppColors.neonBlue),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  ...booking.extras.map((item) => Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: AppText.body(
                      "• ${item['quantity']}x ${item['name_en'] ?? item['name']}",
                      fontSize: 11.sp,
                      color: AppColors.textPrimary,
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],

          const Spacer(),
          Divider(color: AppColors.borderDefault, height: 16.h),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(AppStrings.totalPrice, fontSize: 10.sp),
                  Row(
                    children: [
                      AppText.subHeading('${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}', color: AppColors.neonBlue, fontSize: 15.sp, fontWeight: FontWeight.bold),
                      if (booking.voucherDiscount != null && booking.voucherDiscount! > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_offer_outlined, size: 10.sp, color: AppColors.success),
                              SizedBox(width: 4.w),
                              AppText.body(
                                "${AppStrings.discount} ${booking.voucherDiscount!.toStringAsFixed(0)}", 
                                color: AppColors.success, 
                                fontSize: 9.sp, 
                                fontWeight: FontWeight.bold
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              isPaid ? StatusBadge.success(AppStrings.paid) : StatusBadge.warning(AppStrings.unpaid),
            ],
          ),
          
          if (isPending || (!isPaid && onConfirmPayment != null)) ...[
            SizedBox(height: 12.h),
            if (isPending)
              Row(
                children: [
                  Expanded(child: AppButton(text: AppStrings.approve, onPressed: onApprove ?? () {}, height: 32.h)),
                  SizedBox(width: 8.w),
                  Expanded(child: AppButton(text: AppStrings.reject, variant: AppButtonVariant.outlined, onPressed: onReject ?? () {}, height: 32.h)),
                ],
              )
            else
              AppButton(text: AppStrings.confirmCash, onPressed: onConfirmPayment!, width: double.infinity, height: 34.h, icon: Icons.payments_outlined),
          ],
        ],
      ),
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
