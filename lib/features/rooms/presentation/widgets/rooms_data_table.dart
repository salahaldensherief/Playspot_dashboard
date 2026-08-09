import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../domain/entities/room_entity.dart';
import '../cubit/room_cubit.dart';

class RoomsDataTable extends StatelessWidget {
  final List<RoomEntity> rooms;

  const RoomsDataTable({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
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
              value: room.status == RoomStatus.available,
              activeColor: AppColors.neonBlue,
              onChanged: (val) => context.read<RoomCubit>().toggleRoomStatus(room.id, room.status),
            ),
          ),
          DataCell(
            IconButton(
              icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
              onPressed: () {},
            ),
          ),
        ],
      )).toList(),
    );
  }

  Widget _getStatusBadge(RoomStatus status) {
    return status == RoomStatus.available
        ? StatusBadge.success('Available')
        : StatusBadge.warning('Maintenance');
  }
}
