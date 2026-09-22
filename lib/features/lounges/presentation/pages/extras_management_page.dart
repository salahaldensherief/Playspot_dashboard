import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../cubit/extras_cubit.dart';
import '../widgets/extra_dialog.dart';
import '../widgets/extras_grid.dart';

class ExtrasManagementPage extends StatefulWidget {
  const ExtrasManagementPage({super.key});

  @override
  State<ExtrasManagementPage> createState() => _ExtrasManagementPageState();
}

class _ExtrasManagementPageState extends State<ExtrasManagementPage> {
  String? _loadedLoungeId;

  void _checkAndLoadExtras(BuildContext context, String loungeId) {
    if (loungeId.isNotEmpty && _loadedLoungeId != loungeId) {
      _loadedLoungeId = loungeId;
      context.read<ExtrasCubit>().loadExtras(loungeId);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginState = context.read<LoginCubit>().state;
      final loungeId = loginState.user?.loungeId ?? loginState.userLounge?.id ?? '';
      _checkAndLoadExtras(context, loungeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (prev, curr) =>
          prev.user?.loungeId != curr.user?.loungeId ||
          prev.userLounge?.id != curr.userLounge?.id,
      listener: (context, loginState) {
        final loungeId = loginState.user?.loungeId ?? loginState.userLounge?.id ?? '';
        _checkAndLoadExtras(context, loungeId);
      },
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, loginState) {
          final user = loginState.user;
          final loungeId = user?.loungeId ?? loginState.userLounge?.id ?? '';

          if (loungeId.isNotEmpty && _loadedLoungeId != loungeId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndLoadExtras(context, loungeId);
            });
          }

          return DashboardLayout(
            title: AppStrings.extras,
            activeRoute: 'Extras',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, loungeId),
                SizedBox(height: 24.h),
                const ExtrasGrid(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String loungeId) {
    final cubit = context.read<ExtrasCubit>();
    final bool canEdit = context.hasPermission('menu_manage_items');

    return AppAdaptivePageHeader(
      title: AppStrings.menuManagement,
      subtitle: AppStrings.menuManagementSubtitle,
      primaryAction: canEdit
          ? AppButton(
              text: AppStrings.addExtraItem,
              icon: Icons.add,
              onPressed: () => _openAddDialog(context, loungeId, cubit),
            )
          : null,
    );
  }

  void _openAddDialog(BuildContext context, String loungeId, ExtrasCubit cubit) {
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
  }
}
