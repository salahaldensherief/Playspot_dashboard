import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/categories/presentation/categories/category_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/widgets/room_dialog.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../cubit/room_cubit.dart';

class RoomManagementHeader extends StatelessWidget {
  final String loungeId;

  const RoomManagementHeader({super.key, required this.loungeId});

  @override
  Widget build(BuildContext context) {
    context.locale;
    final user = context.watch<LoginCubit>().state.user;
    final permissions = context.watch<PermissionsCubit>();
    final bool canEdit =
        user != null &&
        permissions.hasPermission(
          'rooms_manage',
          userRole: user.role.name,
          userId: user.id,
        );

    return AppAdaptivePageHeader(
      title: AppStrings.rooms,
      subtitle: AppStrings.manageRoomsDesc,
      primaryAction: canEdit
          ? AppButton(
              text: AppStrings.addNewRoom,
              icon: Icons.add,
              onPressed: () => _showAddRoomDialog(context, loungeId),
            )
          : null,
    );
  }

  void _showAddRoomDialog(BuildContext context, String loungeId) {
    final roomCubit = context.read<RoomCubit>();
    final categoryCubit = context.read<CategoryCubit>();
    final loginCubit = context.read<LoginCubit>();
    final permissionsCubit = context.read<PermissionsCubit>();

    showDialog(
      context: context,
      builder: (diagContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: roomCubit),
          BlocProvider.value(value: categoryCubit),
          BlocProvider.value(value: loginCubit),
          BlocProvider.value(value: permissionsCubit),
        ],
        child: RoomDialog(
          loungeId: loungeId,
          categoryCubit: categoryCubit,
          onSave: (newRoom) => roomCubit.addNewRoom(newRoom),
        ),
      ),
    );
  }
}
