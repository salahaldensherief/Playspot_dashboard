import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/categories/presentation/categories/category_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/widgets/room_dialog.dart';
import '../cubit/room_cubit.dart';

class RoomManagementHeader extends StatelessWidget {
  final String loungeId;

  const RoomManagementHeader({super.key, required this.loungeId});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final bool canEdit = user?.canEditSetup ?? false;

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
            const SizedBox(height: 8),
            Text(
              AppStrings.manageRoomsDesc,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
          ],
        ),
        if (canEdit)
          AppButton(
            text: AppStrings.addNewRoom,
            icon: Icons.add,
            onPressed: () => _showAddRoomDialog(context, loungeId),
          ),
      ],
    );
  }

  void _showAddRoomDialog(BuildContext context, String loungeId) {
    final roomCubit = context.read<RoomCubit>();
    final categoryCubit = context.read<CategoryCubit>();
    
    showDialog(
      context: context,
      builder: (diagContext) => RoomDialog(
        loungeId: loungeId,
        categoryCubit: categoryCubit,
        onSave: (newRoom) => roomCubit.addNewRoom(newRoom),
      ),
    );
  }
}
