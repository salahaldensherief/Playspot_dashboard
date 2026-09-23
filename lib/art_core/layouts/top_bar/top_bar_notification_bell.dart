import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';

class TopBarNotificationBell extends StatelessWidget {
  const TopBarNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    if (user == null || user.isSuperAdmin) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      buildWhen: (prev, curr) =>
          prev.requests != curr.requests || prev.status != curr.status,
      builder: (context, state) {
        final pendingCount = state.requests.where((r) => !r.isAttended).length;

        return Tooltip(
          message: pendingCount > 0
              ? '$pendingCount ${AppStrings.pendingRequests}'
              : AppStrings.noNotifications,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.go(RouterKeys.loungeAdminLiveOps),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$pendingCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
