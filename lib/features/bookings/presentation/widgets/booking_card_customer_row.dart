import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/customer_visit_badge.dart';

class BookingCardCustomerRow extends StatelessWidget {
  final Booking booking;

  const BookingCardCustomerRow({
    super.key,
    required this.booking,
  });

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.neonBlue.withValues(alpha: 0.75),
                AppColors.neonPurple.withValues(alpha: 0.75),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _getInitials(booking.userName),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: AppText.subHeading(
                      booking.userName ?? AppStrings.anonymous,
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  CustomerVisitBadge(visitNumber: booking.visitNumber),
                ],
              ),
              SizedBox(height: 2.h),
              AppText.body(
                booking.userPhone ?? booking.userEmail ?? AppStrings.anonymous,
                fontSize: 11.sp,
                color: AppColors.neonBlue,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
