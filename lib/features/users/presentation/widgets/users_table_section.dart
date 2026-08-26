import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import '../cubit/admin_management_cubit.dart';
import '../cubit/admin_management_state.dart';
import 'users_data_table.dart';

class UsersTableSection extends StatelessWidget {
  const UsersTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminManagementCubit, AdminManagementState>(
      builder: (context, state) {
        if (state.status == AdminManagementStatus.loading && state.admins.isEmpty) {
          return const TableShimmer(columns: 4);
        }
        if (state.status == AdminManagementStatus.failure && state.admins.isEmpty) {
          return Center(child: AppText.body(state.errorMessage ?? AppStrings.error, color: AppColors.danger));
        }
        
        return UsersDataTable(admins: state.admins);
      },
    );
  }
}
