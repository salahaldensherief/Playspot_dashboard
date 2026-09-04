import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../domain/entities/booking.dart';

/// Reusable UI Card displaying User & Contact Info for a booking.
class BookingUserInfoCard extends StatelessWidget {
  final Booking booking;

  const BookingUserInfoCard({
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
    final name = booking.userName ?? AppStrings.anonymous;
    final email = booking.userEmail ?? '-';
    final phone = booking.userPhone ?? '-';
    final initials = _getInitials(name);

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
              const Icon(Icons.person_outline, color: AppColors.neonBlue, size: 20),
              SizedBox(width: 8.w),
              AppText.subHeading(
                AppStrings.userAndContactInfo,
                fontSize: 16.sp,
                color: AppColors.textPrimary,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.neonBlue.withValues(alpha: 0.8),
                      AppColors.neonPurple.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.subHeading(
                      name,
                      fontSize: 16.sp,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 14),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: AppText.body(
                            email,
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 14),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: AppText.body(
                            phone,
                            fontSize: 12.sp,
                            color: AppColors.neonBlue,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: AppText.body(
                  'ID: ${booking.userId.length > 8 ? booking.userId.substring(0, 8) : booking.userId}',
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
