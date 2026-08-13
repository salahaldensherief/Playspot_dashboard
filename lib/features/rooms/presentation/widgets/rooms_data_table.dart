import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/categories/presentation/cubit/category_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/widgets/room_dialog.dart';
import '../../domain/entities/room_entity.dart';
import '../cubit/room_cubit.dart';


class RoomsDataTable extends StatelessWidget {
  final List<RoomEntity> rooms;

  const RoomsDataTable({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final loungeId = context.read<LoginCubit>().state.user?.loungeId ?? '';
    final roomCubit = context.read<RoomCubit>();
    final categoryCubit = context.read<CategoryCubit>();

    return DataTableWidget(
      columns: [
        AppStrings.roomName,
        AppStrings.specs,
        AppStrings.capacity,
        AppStrings.pricePerHour,
        AppStrings.status,
        'Online Toggle',
        AppStrings.actions
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
          DataCell(
            Text('${room.screenSize} • ${room.controllersCount} ${AppStrings.controllers}', 
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp))
          ),
          DataCell(Text('${room.capacity} ${AppStrings.persons}', style: const TextStyle(color: AppColors.textSecondary))),
          DataCell(Text('\$${room.pricePerHour.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary))),
          DataCell(_getStatusBadge(room.status)),
          DataCell(
            Switch(
              value: room.status == RoomStatusEnum.available,
              activeColor: AppColors.neonBlue,
              onChanged: (val) => roomCubit.toggleRoomStatus(room.id, room.status),
            ),
          ),
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

  void _confirmDelete(BuildContext context, RoomCubit cubit, RoomEntity room) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "${room.nameEn}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              cubit.deleteRoom(room.id);
              Navigator.pop(diagContext);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
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
}
