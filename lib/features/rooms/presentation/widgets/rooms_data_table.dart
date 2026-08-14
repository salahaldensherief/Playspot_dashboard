import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
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
    final loungeId = context.read<LoginCubit>().state.user?.loungeId ?? '';
    final roomCubit = context.read<RoomCubit>();
    final categoryCubit = context.read<CategoryCubit>();

    return DataTableWidget(
      columns: [
        AppStrings.roomName,
        AppStrings.spaceType,
        AppStrings.experienceType,
        'Pricing',
        'Extra Ctr.',
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
          DataCell(_getSpaceTypeBadge(room.spaceType ?? room.spaceTypeId)),
          DataCell(_getExperienceBadge(room.activityNames)),
          DataCell(
            room.isOpenArea 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('S: ${room.pricePerHourSingle.toStringAsFixed(0)} EGP', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp)),
                    Text('M: ${room.pricePerHourMulti.toStringAsFixed(0)} EGP', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                  ],
                )
              : Text('${room.pricePerHour.toStringAsFixed(0)} EGP / Hr', style: const TextStyle(color: AppColors.textPrimary)),
          ),
          DataCell(Text('+${room.extraControllerPrice.toStringAsFixed(0)} EGP/hr', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp))),
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

  Widget _getExperienceBadge(List<String> activities) {
    if (activities.isEmpty) return StatusBadge.neutral('N/A');
    
    final activity = activities.first.toLowerCase();
    String label = activities.first;
    IconData? icon;
    Color color = AppColors.neonBlue;

    if (activity.contains('playstation') || activity.contains('ps5') || activity.contains('ps4')) {
      icon = Icons.sports_esports;
      color = Colors.blueAccent;
    } else if (activity.contains('simulator') || activity.contains('racing') || activity.contains('سباق')) {
      icon = Icons.directions_car;
      color = Colors.redAccent;
    } else if (activity.contains('vr') || activity.contains('virtual') || activity.contains('واقع افتراضي')) {
      icon = Icons.visibility;
      color = Colors.purpleAccent;
    } else if (activity.contains('pc') || activity.contains('computer') || activity.contains('كمبيوتر')) {
      icon = Icons.computer;
      color = Colors.greenAccent;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14.r, color: color),
            SizedBox(width: 4.w),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
