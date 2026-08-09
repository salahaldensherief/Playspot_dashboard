import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../cubit/admin_management_cubit.dart';
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
              'Lounge Administrators',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Create and manage accounts for lounge managers',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
          ],
        ),
        AppButton(
          text: 'Add Lounge Admin',
          icon: Icons.person_add_alt_1,
          onPressed: () => _showAddAdminDialog(context),
        ),
      ],
    );
  }

  void _showAddAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (diagContext) => BlocProvider.value(
        value: context.read<AdminManagementCubit>(),
        child: const AddLoungeAdminDialog(),
      ),
    );
  }
}
