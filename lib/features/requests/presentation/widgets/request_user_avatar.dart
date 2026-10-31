import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_avatar.dart';

class RequestUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String userName;

  const RequestUserAvatar({super.key, this.avatarUrl, required this.userName});

  @override
  Widget build(BuildContext context) {
    final initial = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : 'U';
    return AppAvatar(
      radius: 16.r,
      imageUrl: avatarUrl,
      fallback: Text(
        initial,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}
