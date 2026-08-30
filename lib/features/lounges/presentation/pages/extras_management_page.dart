import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../cubit/extras_cubit.dart';
import '../widgets/extra_dialog.dart';
import '../widgets/extras_grid.dart';

class ExtrasManagementPage extends StatelessWidget {
  const ExtrasManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';

    return DashboardLayout(
      title: AppStrings.extras,
      activeRoute: 'Extras',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, loungeId),
          SizedBox(height: 32.h),
          const ExtrasGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String loungeId) {
    final cubit = context.read<ExtrasCubit>();
    final bool canEdit = context.hasPermission('menu_manage_items');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.heading(AppStrings.menuManagement, fontSize: 24.sp),
            AppText.body(AppStrings.menuManagementSubtitle),
          ],
        ),
        if (canEdit)
          AppButton(
            text: AppStrings.addExtraItem,
            icon: Icons.add,
            onPressed: () {
              final loginCubit = context.read<LoginCubit>();
              final permissionsCubit = context.read<PermissionsCubit>();

              showDialog(
                context: context,
                builder: (diagContext) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: loginCubit),
                    BlocProvider.value(value: permissionsCubit),
                  ],
                  child: ExtraDialog(
                    loungeId: loungeId,
                    onSave: (newExtra) => cubit.addExtra(newExtra),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
