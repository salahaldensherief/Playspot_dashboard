import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import 'booking_products_preview.dart';

class NewBookingAlertDialog extends StatelessWidget {
  final Booking booking;

  const NewBookingAlertDialog({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final double extrasTotal = booking.addonsPrice ?? 0.0;
    final double roomPrice = booking.roomPrice ?? (booking.totalPrice - extrasTotal).clamp(0.0, double.infinity);
    final bool hasExtras = extrasTotal > 0 || booking.extras.isNotEmpty || booking.canteenOrders.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 440.w,
        constraints: BoxConstraints(maxWidth: 440.w),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.neonBlue, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.neonBlue,
                    size: 28.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.newBookingArrived,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        AppStrings.realtimeBookingAlert,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Details Container
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: AppStrings.userLabel,
                    value: booking.userName ?? AppStrings.guestClient,
                  ),
                  SizedBox(height: 8.h),
                  _buildDetailRow(
                    icon: Icons.meeting_room_outlined,
                    label: AppStrings.roomLabel,
                    value: booking.roomName,
                  ),
                  SizedBox(height: 8.h),
                  _buildDetailRow(
                    icon: Icons.access_time_rounded,
                    label: AppStrings.schedule,
                    value: booking.startTime,
                  ),
                  if (hasExtras) ...[
                    SizedBox(height: 8.h),
                    _buildDetailRow(
                      icon: Icons.tv_rounded,
                      label: AppStrings.basePrice,
                      value: '${roomPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                      valueColor: AppColors.textSecondary,
                    ),
                    SizedBox(height: 8.h),
                    _buildDetailRow(
                      icon: Icons.extension_outlined,
                      label: AppStrings.additionalItems,
                      value: '+${extrasTotal.toStringAsFixed(0)} ${AppStrings.egp}',
                      valueColor: AppColors.warning,
                    ),
                  ],
                  SizedBox(height: 8.h),
                  _buildDetailRow(
                    icon: Icons.payments_outlined,
                    label: AppStrings.totalPriceLabel,
                    value: '${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                    valueColor: AppColors.success,
                  ),
                  if (hasExtras) ...[
                    SizedBox(height: 10.h),
                    const Divider(color: AppColors.borderDefault, height: 1),
                    SizedBox(height: 8.h),
                    BookingProductsPreview(booking: booking, maxVisibleItems: 6),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: AppStrings.close,
                    variant: AppButtonVariant.outlined,
                    height: 44.h,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppButton(
                    text: AppStrings.confirmBooking,
                    variant: AppButtonVariant.primary,
                    icon: Icons.check_circle_rounded,
                    height: 44.h,
                    onPressed: () {
                      context.read<BookingCubit>().approveBooking(booking.id);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.r, color: AppColors.textSecondary),
            SizedBox(width: 6.w),
            AppText.body(
              label,
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        AppText.subHeading(
          value,
          fontSize: 13.sp,
          color: valueColor ?? AppColors.textPrimary,
        ),
      ],
    );
  }
}
