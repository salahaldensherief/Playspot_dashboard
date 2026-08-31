import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'action_button.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: SingleChildScrollView(
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
              children: [
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
                  icon: Icons.add_business_outlined,
                  label: AppStrings.addLounge,
                  color: AppColors.neonPurple,
                  onTap: () => context.push(RouterKeys.superAdminLounges),
                ),
                ActionButton(
                  icon: Icons.campaign_outlined,
                  label: AppStrings.createPromo,
                  color: AppColors.neonGreen,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.underConstruction)),
                    );
                  },
                ),
                ActionButton(
                  icon: Icons.file_download_outlined,
                  label: AppStrings.exportReport,
                  color: AppColors.neonCyan,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.underConstruction)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
