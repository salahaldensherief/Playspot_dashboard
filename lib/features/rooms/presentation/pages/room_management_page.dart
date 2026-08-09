import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../cubit/room_cubit.dart';
import '../widgets/room_management_header.dart';
import '../widgets/rooms_data_table.dart';

class RoomManagementPage extends StatelessWidget {
  const RoomManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.read<LoginCubit>().state.admin;
    final loungeId = admin?.loungeId ?? '';

    return BlocProvider(
      create: (context) => sl<RoomCubit>()..watchRooms(loungeId),
      child: Builder(
        builder: (context) {
          return DashboardLayout(
            title: AppStrings.rooms,
            activeRoute: 'Rooms',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoomManagementHeader(loungeId: loungeId),
                SizedBox(height: 32.h),
                const _RoomTableSection(),
              ],
            ),
          );
        }
      ),
    );
  }
}

class _RoomTableSection extends StatelessWidget {
  const _RoomTableSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomCubit, RoomState>(
      builder: (context, state) {
        if (state is RoomLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }

        if (state is RoomLoaded) {
          return RoomsDataTable(rooms: state.rooms);
        }

        if (state is RoomError) {
          return Center(child: Text(state.message, style: const TextStyle(color: AppColors.danger)));
        }

        return const SizedBox.shrink();
      },
    );
  }
}
