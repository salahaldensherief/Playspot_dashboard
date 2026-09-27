import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';

class TopBarShiftIndicator extends StatelessWidget {
  const TopBarShiftIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    if (user == null || user.isSuperAdmin) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ShiftCubit, ShiftState>(
      buildWhen: (prev, curr) =>
          prev.activeShift != curr.activeShift || prev.status != curr.status,
      builder: (context, shiftState) {
        final isActive = shiftState.activeShift != null;
        final bool isMobile = MediaQuery.sizeOf(context).width < 600;
        final color = isActive ? AppColors.success : AppColors.warning;

        return Tooltip(
          message: isActive ? AppStrings.shiftActive : AppStrings.noActiveShift,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
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
                    isActive ? AppStrings.shiftActive : AppStrings.noActiveShift,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
