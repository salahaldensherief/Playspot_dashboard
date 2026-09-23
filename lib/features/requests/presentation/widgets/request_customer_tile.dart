import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/request_user_avatar.dart';

class RequestCustomerTile extends StatelessWidget {
  final String userName;
  final String? userPhone;
  final String? userAvatarUrl;

  const RequestCustomerTile({
    super.key,
    required this.userName,
    this.userPhone,
    this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          RequestUserAvatar(avatarUrl: userAvatarUrl, userName: userName),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subHeading(
                  userName,
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                if (userPhone != null && (userPhone?.isNotEmpty ?? false)) ...[
                  SizedBox(height: 2.h),
                  AppText.body(
                    userPhone ?? '',
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
