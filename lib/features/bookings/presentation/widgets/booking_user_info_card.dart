import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final rawEmail = booking.userEmail?.trim();
    final email = (rawEmail != null && rawEmail.isNotEmpty && rawEmail != 'null') ? rawEmail : '-';
    final rawPhone = booking.userPhone?.trim();
    final phone = (rawPhone != null && rawPhone.isNotEmpty && rawPhone != 'No Phone' && rawPhone != 'null') ? rawPhone : '-';
    final initials = _getInitials(name);
    final userIdDisplay = booking.userId.isNotEmpty
        ? (booking.userId.length > 8 ? booking.userId.substring(0, 8) : booking.userId)
        : 'زائر';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_pin_rounded, color: AppColors.neonBlue, size: 20),
                  SizedBox(width: 8.w),
                  AppText.subHeading(
                    AppStrings.userAndContactInfo,
                    fontSize: 15.sp,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: AppText.body(
                  'ID: #$userIdDisplay',
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52.r,
                height: 52.r,
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
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonBlue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                    Row(
                      children: [
                        AppText.subHeading(
                          name,
                          fontSize: 16.sp,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.neonBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'عميل محجوز',
                            style: TextStyle(
                              color: AppColors.neonBlue,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, color: AppColors.neonBlue, size: 14),
                        SizedBox(width: 6.w),
                        AppText.body(
                          phone,
                          fontSize: 13.sp,
                          color: AppColors.neonBlue,
                          fontWeight: FontWeight.bold,
                        ),
                        if (phone != '-') ...[
                          SizedBox(width: 8.w),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: phone));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ رقم الهاتف'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(color: AppColors.borderDefault),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy_rounded, size: 11.r, color: AppColors.textMuted),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'نسخ',
                                    style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
