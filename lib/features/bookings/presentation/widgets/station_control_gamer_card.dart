import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/customer_visit_badge.dart';

class StationControlGamerCard extends StatelessWidget {
  final Booking booking;

  const StationControlGamerCard({
    super.key,
    required this.booking,
  });

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final userName = (booking.userName != null && booking.userName!.isNotEmpty)
        ? booking.userName!
        : AppStrings.anonymous;
    final userPhone = booking.userPhone?.trim() ?? '';

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42.r,
            height: 42.r,
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
              _getInitials(userName),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    CustomerVisitBadge(visitNumber: booking.visitNumber),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    if (userPhone.isNotEmpty && userPhone != 'null' && userPhone != 'No Phone') ...[
                      Icon(Icons.phone_outlined, size: 12.sp, color: AppColors.neonBlue),
                      SizedBox(width: 4.w),
                      Text(
                        userPhone,
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.phoneCopied),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: Icon(Icons.copy_rounded, size: 12.sp, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
