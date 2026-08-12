import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../cubit/admin_management_cubit.dart';
import '../cubit/admin_management_state.dart';
import 'add_lounge_admin_dialog.dart';

class UsersHeader extends StatelessWidget {
  const UsersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.loungeAdministrators,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.manageAdminsDesc,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
          ],
        ),
        AppButton(
          text: AppStrings.addLoungeAdminBtn,
          icon: Icons.person_add_alt_1,
          onPressed: () => _showAddAdminDialog(context),
        ),
      ],
    );
  }

  void _showAddAdminDialog(BuildContext context) {
    final cubit = context.read<AdminManagementCubit>();
    showDialog(
      context: context,
      builder: (diagContext) => BlocConsumer<AdminManagementCubit, AdminManagementState>(
        bloc: cubit,
        listener: (context, state) {
          if (state.status == AdminManagementStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.adminCreatedSuccess), backgroundColor: AppColors.success),
            );
            Navigator.pop(diagContext);
          } else if (state.status == AdminManagementStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error'), backgroundColor: AppColors.danger),
            );
          }
        },
        builder: (context, state) {
          return AddLoungeAdminDialog(
            isLoading: state.status == AdminManagementStatus.loading,
            onSave: (email, password, name, loungeName, city) {
              cubit.createLoungeAdmin(
                email: email,
                password: password,
                name: name,
                loungeName: loungeName,
                city: city,
              );
            },
          );
        },
      ),
    );
  }
}
