import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';

class TopBarUserProfile extends StatelessWidget {
  const TopBarUserProfile({super.key});

  Widget _buildAvatar(String? url) {
    final bool hasAvatar = url != null && url.trim().isNotEmpty;
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
      backgroundImage: hasAvatar ? AppCachedImage.provider(url) : null,
      child: !hasAvatar
          ? const Icon(Icons.person, color: AppColors.neonPurple, size: 20)
          : null,
    );
  }

  Widget _buildDefaultAvatar() {
    return const CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.neonPurple,
      child: Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => prev.user != curr.user,
      builder: (context, state) {
        final user = state.user;
        if (user == null) return _buildDefaultAvatar();

        final bool isMobile = MediaQuery.sizeOf(context).width < 600;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isMobile) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.isSuperAdmin
                        ? AppStrings.superAdmin
                        : (user.isLoungeOwner
                            ? AppStrings.loungeOwnerLabel
                            : (user.isCashier
                                ? AppStrings.cashierLabel
                                : AppStrings.loungeManager)),
                    style: const TextStyle(
                      color: AppColors.neonPurple,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
            _buildAvatar(user.avatarUrl),
          ],
        );
      },
    );
  }
}
