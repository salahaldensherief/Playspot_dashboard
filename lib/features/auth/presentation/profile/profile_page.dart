import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../login/login_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;

    return DashboardLayout(
      title: AppStrings.myProfile,
      activeRoute: AppStrings.myProfile,
      child: Center(
        child: Container(
          width: 600.w,
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(context, user?.avatarUrl, user?.name ?? ''),
              SizedBox(height: 32.h),
              AppTextField(
                label: AppStrings.fullNameLabel,
                controller: TextEditingController(text: user?.name),
                readOnly: true,
              ),
              SizedBox(height: 20.h),
              AppTextField(
                label: AppStrings.emailAddressLabel,
                controller: TextEditingController(text: user?.email),
                readOnly: true,
              ),
              SizedBox(height: 20.h),
              AppTextField(
                label: AppStrings.roleLabel,
                controller: TextEditingController(text: user?.role.toString().split('.').last.toUpperCase()),
                readOnly: true,
              ),
              SizedBox(height: 40.h),
              AppButton(
                text: AppStrings.changePassword,
                variant: AppButtonVariant.outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.underConstruction)),
                  );
                },
              ),
              SizedBox(height: 16.h),
              AppButton(
                text: AppStrings.logout,
                variant: AppButtonVariant.primary,
                onPressed: () => context.read<LoginCubit>().logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String? url, String name) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60.r,
          backgroundColor: AppColors.neonPurple.withOpacity(0.1),
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null 
            ? AppText.heading(
                name.isNotEmpty ? name[0].toUpperCase() : '?', 
                fontSize: 40.sp, 
                color: AppColors.neonPurple
              )
            : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: () {
              // Image picking logic would go here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.underConstruction)),
              );
            },
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: const BoxDecoration(
                color: AppColors.neonBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20.r),
            ),
          ),
        ),
      ],
    );
  }
}
