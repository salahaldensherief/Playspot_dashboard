import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../cubit/room_cubit.dart';
import 'add_room_dialog.dart';

class RoomManagementHeader extends StatelessWidget {
  final String loungeId;

  const RoomManagementHeader({super.key, required this.loungeId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.rooms,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppStrings.manageRoomsDesc,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
          ],
        ),
        AppButton(
          text: AppStrings.addNewRoom,
          icon: Icons.add,
          onPressed: () => _showAddRoomDialog(context, loungeId),
        ),
      ],
    );
  }

  void _showAddRoomDialog(BuildContext context, String loungeId) {
    showDialog(
      context: context,
      builder: (diagContext) => BlocProvider.value(
        value: context.read<RoomCubit>(),
        child: RoomDialog(loungeId: loungeId),
      ),
    );
  }
}
