import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/payment_method_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_status_badge.dart';

class BookingCardHeader extends StatelessWidget {
  final Booking booking;
  final Color accent;
  final String shortId;

  const BookingCardHeader({
    super.key,
    required this.booking,
    required this.accent,
    required this.shortId,
  });

  Widget _getPaymentTypeBadge(Booking booking) {
    if (booking.isCashPayment) {
      return const PaymentMethodBadge(isCash: true, compact: true);
    }
    return PaymentMethodBadge.fromBookingPaymentMethod(
      booking.paymentMethod,
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BookingStatusBadge.fromBooking(booking),
                _getPaymentTypeBadge(booking),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          AppText.body(
            '#$shortId',
            fontSize: 10.5.sp,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
