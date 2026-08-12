import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../cubit/admin_management_cubit.dart';
import '../cubit/admin_management_state.dart';
import 'users_data_table.dart';

class UsersTableSection extends StatelessWidget {
  const UsersTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminManagementCubit, AdminManagementState>(
      builder: (context, state) {
        if (state.status == AdminManagementStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }
        if (state.status == AdminManagementStatus.failure) {
          return Center(child: AppText.body(state.errorMessage ?? 'Error', color: AppColors.danger));
        }
        if (state.status == AdminManagementStatus.success || state.admins.isNotEmpty) {
          return UsersDataTable(admins: state.admins);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
