import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'package:play_spot_dashboard/features/users/presentation/widgets/add_lounge_admin_dialog.dart';
import 'action_button.dart';

class QuickActionsCard extends StatelessWidget {
  final bool isSuperAdmin;

  const QuickActionsCard({
    super.key,
    this.isSuperAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.quickActions,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: isSuperAdmin ? _buildSuperAdminActions(context) : _buildLoungeOwnerActions(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSuperAdminActions(BuildContext context) {
    return [
      ActionButton(
        icon: Icons.add_business_outlined,
        label: AppStrings.addLounge,
        color: AppColors.neonPurple,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const AddLoungeAdminDialog(),
          );
        },
      ),
      ActionButton(
        icon: Icons.category_outlined,
        label: AppStrings.categories,
        color: AppColors.neonBlue,
        onTap: () => context.push(RouterKeys.superAdminCategories),
      ),
      ActionButton(
        icon: Icons.people_outline,
        label: AppStrings.roleLabel,
        color: AppColors.neonCyan,
        onTap: () => context.push(RouterKeys.superAdminUsers),
      ),
      ActionButton(
        icon: Icons.payments_outlined,
        label: AppStrings.payouts,
        color: AppColors.neonGreen,
        onTap: () => context.push(RouterKeys.superAdminPayouts),
      ),
    ];
  }

  List<Widget> _buildLoungeOwnerActions(BuildContext context) {
    return [
      ActionButton(
        icon: Icons.add_circle_outline,
        label: AppStrings.newBooking,
        color: AppColors.neonBlue,
        onTap: () {
          final loungeId = context.read<LoginCubit>().state.user?.loungeId;
          if (loungeId != null) {
            showDialog(
              context: context,
              builder: (context) => AddBookingDialog(loungeId: loungeId),
            );
          }
        },
      ),
      ActionButton(
        icon: Icons.fastfood_outlined,
        label: AppStrings.extras,
        color: AppColors.neonPurple,
        onTap: () => context.push(RouterKeys.loungeAdminExtras),
      ),
      ActionButton(
        icon: Icons.meeting_room_outlined,
        label: AppStrings.rooms,
        color: AppColors.neonGreen,
        onTap: () => context.push(RouterKeys.loungeAdminRooms),
      ),
      ActionButton(
        icon: Icons.live_tv_outlined,
        label: AppStrings.bookings,
        color: AppColors.neonCyan,
        onTap: () => context.push(RouterKeys.loungeAdminLiveOps),
      ),
    ];
  }
}
