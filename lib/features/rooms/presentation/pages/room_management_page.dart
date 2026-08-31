import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<LoginCubit>().state.user;
      if (user?.loungeId != null) {
        context.read<RoomCubit>().watchRooms(user!.loungeId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';

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
  }
}
