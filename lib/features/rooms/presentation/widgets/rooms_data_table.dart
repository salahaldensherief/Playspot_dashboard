import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/categories/presentation/categories/category_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/widgets/room_dialog.dart';
import '../../domain/entities/room_entity.dart';
import '../cubit/room_cubit.dart';


class RoomsDataTable extends StatelessWidget {
  final List<RoomEntity> rooms;

  const RoomsDataTable({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';
    final bool canEdit = user?.canEditSetup ?? false;
    final roomCubit = context.read<RoomCubit>();
    final categoryCubit = context.read<CategoryCubit>();

    return DataTableWidget(
      columns: [
        AppStrings.roomName,
        AppStrings.spaceType,
        'Pricing',
        'Extra Ctr.',
        AppStrings.status,
        if (canEdit) 'Online Toggle',
        if (canEdit) AppStrings.actions
      ],
      rows: rooms.map((room) => DataRow(
        cells: [
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(room.nameEn, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                Text(room.nameAr, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
              ],
            ),
          ),
          DataCell(_getSpaceTypeBadge(room.spaceType ?? room.spaceTypeId)),
          DataCell(Text('${room.pricePerHour.toStringAsFixed(0)} ${AppStrings.egp} / Hr', style: const TextStyle(color: AppColors.textPrimary))),
          DataCell(Text('+${room.extraControllerPrice.toStringAsFixed(0)} EGP/hr', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp))),
          DataCell(_getStatusBadge(room.status)),
          if (canEdit)
            DataCell(
              Switch(
                value: room.status == RoomStatusEnum.available,
                activeColor: AppColors.neonBlue,
                onChanged: (val) => roomCubit.toggleRoomStatus(room.id, room.status),
              ),
            ),
          if (canEdit)
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                    onPressed: () => _showEditDialog(context, roomCubit, categoryCubit, loungeId, room),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
                    onPressed: () => _confirmDelete(context, roomCubit, room),
                  ),
                ],
              ),
            ),
        ],
      )).toList(),
    );
  }

  void _showEditDialog(BuildContext context, RoomCubit cubit, CategoryCubit categoryCubit, String loungeId, RoomEntity room) {
    showDialog(
      context: context,
      builder: (_) => RoomDialog(
        loungeId: loungeId, 
        room: room,
        categoryCubit: categoryCubit,
        onSave: (updatedRoom) => cubit.updateRoom(updatedRoom),
      ),
    );
  }

  void _confirmDelete(BuildContext context, RoomCubit cubit, RoomEntity room) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.deleteConfirmation,
      message: '${AppStrings.deleteWarning} "${room.nameEn}"?',
      confirmText: AppStrings.delete,
      confirmColor: AppColors.danger,
    );

    if (confirmed == true) {
      cubit.deleteRoom(room.id);
    }
  }

  Widget _getStatusBadge(RoomStatusEnum status) {
    switch (status) {
      case RoomStatusEnum.available:
        return StatusBadge.success('Available');
      case RoomStatusEnum.maintenance:
        return StatusBadge.warning('Maintenance');
      case RoomStatusEnum.occupied:
        return StatusBadge.danger('Occupied');
    }
  }

  Widget _getSpaceTypeBadge(String? type) {
    final typeLower = type?.toLowerCase() ?? '';
    if (typeLower.contains('open') || typeLower.contains('صالة') || typeLower == 'open_area') {
      return StatusBadge.info(AppStrings.openArea);
    } else if (typeLower.contains('vip') || typeLower.contains('فيب') || typeLower == 'vip_room') {
      return StatusBadge.warning(AppStrings.vipRoom);
    } else if (typeLower.contains('standard') || typeLower.contains('عادية') || typeLower == 'standard_room') {
      return StatusBadge.secondary(AppStrings.standardRoom);
    } else {
      return StatusBadge.neutral(type ?? 'N/A');
    }
  }
}
