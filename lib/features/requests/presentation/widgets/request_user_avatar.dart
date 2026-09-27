import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';

class RequestUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String userName;

  const RequestUserAvatar({
    super.key,
    this.avatarUrl,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = avatarUrl != null && (avatarUrl?.trim().isNotEmpty ?? false);
    final String initial =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'U';

    final provider = AppCachedImage.provider(avatarUrl);

    return Container(
      width: 32.r,
      height: 32.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderDefault, width: 1),
        color: AppColors.cardBackground,
        image: (hasAvatar && provider != null)
            ? DecorationImage(
                image: provider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: (!hasAvatar || provider == null)
          ? Text(
              initial,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            )
          : null,
    );
  }
}
