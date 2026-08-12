import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';
import 'rooms_data_table.dart';

class RoomTableSection extends StatelessWidget {
  const RoomTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomCubit, RoomState>(
      builder: (context, state) {
        if (state.status == RoomStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }

        if (state.status == RoomStatus.success) {
          return RoomsDataTable(rooms: state.rooms);
        }

        if (state.status == RoomStatus.failure) {
          return Center(child: Text(state.errorMessage ?? 'Error', style: const TextStyle(color: AppColors.danger)));
        }

        return const SizedBox.shrink();
      },
    );
  }
}
