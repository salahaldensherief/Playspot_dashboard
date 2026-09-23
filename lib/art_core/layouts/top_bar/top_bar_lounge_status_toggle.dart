import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_state.dart';

class TopBarLoungeStatusToggle extends StatelessWidget {
  const TopBarLoungeStatusToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) =>
          prev.user != curr.user || prev.userLounge != curr.userLounge,
      builder: (context, loginState) {
        final user = loginState.user;
        final loungeId = user?.loungeId;
        if (user == null ||
            user.isSuperAdmin ||
            !user.canToggleLoungeStatus ||
            loungeId == null ||
            loungeId.isEmpty) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<LoungeCubit, LoungeState>(
          buildWhen: (prev, curr) => prev.lounges != curr.lounges,
          builder: (context, loungeState) {
            Lounge? currentLounge;
            if (loungeState.lounges.isNotEmpty) {
              final found =
                  loungeState.lounges.where((l) => l.id == loungeId).toList();
              if (found.isNotEmpty) currentLounge = found.first;
            }

            final isOpen =
                currentLounge?.isOpen ?? (loginState.userLounge?.isOpen ?? true);
            final bool isMobile = MediaQuery.sizeOf(context).width < 600;
            final color = isOpen ? AppColors.success : AppColors.danger;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isMobile) const SizedBox(width: 8),
                  if (!isMobile)
                    Text(
                      isOpen ? AppStrings.loungeIsOpen : AppStrings.loungeIsClosed,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: isOpen,
                      activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.success,
                      inactiveThumbColor: AppColors.danger,
                      inactiveTrackColor: AppColors.danger.withValues(alpha: 0.3),
                      onChanged: (val) async {
                        await context.read<LoungeCubit>().toggleLoungeStatus(loungeId, val);
                        if (context.mounted) {
                          context.read<LoginCubit>().refreshUserLounge(loungeId);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
