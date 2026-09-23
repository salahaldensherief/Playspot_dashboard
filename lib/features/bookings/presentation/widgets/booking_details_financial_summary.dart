import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'booking_products_preview.dart';

class BookingDetailsFinancialSummary extends StatelessWidget {
  final Booking booking;

  const BookingDetailsFinancialSummary({super.key, required this.booking});

  Widget _buildBillRow(String label, String value,
      {bool isTotal = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 13.sp : 12.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 15.sp : 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double extrasTotal = 0.0;
    for (final item in booking.extras) {
      final q = (item['quantity'] ?? item['qty'] ?? 1) as num;
      final p = (item['price'] ?? item['unit_price'] ?? 0.0) as num;
      extrasTotal += (q * p).toDouble();
    }
    if (extrasTotal == 0.0 &&
        booking.addonsPrice != null &&
        booking.addonsPrice! > 0) {
      extrasTotal = booking.addonsPrice!;
    }
    final roomBasePrice =
        (booking.totalPrice - extrasTotal).clamp(0.0, double.infinity);
    final hasExtras = extrasTotal > 0 || booking.extras.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.subHeading('ملخص الحساب والفاتورة', fontSize: 13.sp),
              StatusBadge(
                text: booking.paymentStatus == PaymentStatus.paid
                    ? AppStrings.paid
                    : AppStrings.unpaid,
                color: booking.paymentStatus == PaymentStatus.paid
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildBillRow(
              'سعر الغرفة الأساسي',
              '${roomBasePrice.toStringAsFixed(0)} ${AppStrings.egp}'),
          _buildBillRow(
              AppStrings.extrasTotal,
              '${extrasTotal.toStringAsFixed(0)} ${AppStrings.egp}',
              color: hasExtras ? AppColors.warning : null),
          if (booking.discountAmount != null && booking.discountAmount! > 0)
            _buildBillRow(
                AppStrings.discount,
                '-${booking.discountAmount!.toStringAsFixed(0)} ${AppStrings.egp}',
                color: AppColors.danger),
          const Divider(color: AppColors.borderDefault),
          _buildBillRow(
            'الإجمالي النهائي المطلوب',
            '${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
            isTotal: true,
            color: AppColors.neonGreen,
          ),
          if (hasExtras) ...[
            SizedBox(height: 12.h),
            const Divider(color: AppColors.borderDefault, height: 1),
            SizedBox(height: 10.h),
            BookingProductsPreview(booking: booking, maxVisibleItems: 10),
          ],
        ],
      ),
    );
  }
}
