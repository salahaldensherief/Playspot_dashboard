import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/room_cubit.dart';
import '../widgets/room_management_header.dart';
import '../widgets/room_table_section.dart';

class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({super.key});

  @override
  State<RoomManagementPage> createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  String? _loadedLoungeId;

  void _checkAndLoadRooms(BuildContext context, String loungeId) {
    if (loungeId.isNotEmpty && _loadedLoungeId != loungeId) {
      _loadedLoungeId = loungeId;
      context.read<RoomCubit>().watchRooms(loungeId);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginState = context.read<LoginCubit>().state;
      final loungeId = loginState.user?.loungeId ?? loginState.userLounge?.id ?? '';
      _checkAndLoadRooms(context, loungeId);
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
        _checkAndLoadRooms(context, loungeId);
      },
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, loginState) {
          final user = loginState.user;
          final loungeId = user?.loungeId ?? loginState.userLounge?.id ?? '';

          if (loungeId.isNotEmpty && _loadedLoungeId != loungeId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndLoadRooms(context, loungeId);
            });
          }

          return DashboardLayout(
            title: AppStrings.rooms,
            activeRoute: 'Rooms',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoomManagementHeader(loungeId: loungeId),
                SizedBox(height: 32.h),
                const RoomTableSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}
