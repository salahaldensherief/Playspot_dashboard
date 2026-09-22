import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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
      mobileCardBuilder: (ctx, index) {
        final room = rooms[index];
        return _buildMobileRoomCard(ctx, room, canEdit, roomCubit, categoryCubit, loungeId);
      },
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
                Text(room.nameAr.isNotEmpty ? room.nameAr : room.nameEn, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                if (room.nameEn.isNotEmpty && room.nameEn != room.nameAr)
                  Text(room.nameEn, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
              ],
            ),
          ),
          DataCell(_getSpaceTypeBadge(room.spaceType ?? room.spaceTypeId)),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Single: ${room.hourlyRateSingle.toStringAsFixed(0)} ${AppStrings.egp}/hr', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                Text('Multi: ${room.hourlyRateMulti.toStringAsFixed(0)} ${AppStrings.egp}/hr', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
              ],
            ),
          ),
          DataCell(Text('+${room.extraControllerPrice.toStringAsFixed(0)} EGP/hr', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp))),
          DataCell(_getStatusBadge(room.status)),
          if (canEdit)
            DataCell(
              Switch(
                value: room.status == RoomStatusEnum.available,
                activeThumbColor: AppColors.neonBlue,
                onChanged: (val) => roomCubit.toggleRoomStatus(room.id, room.status),
              ),
            ),
          if (canEdit)
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => _showEditDialog(context, roomCubit, categoryCubit, loungeId, room),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => _confirmDelete(context, roomCubit, room),
                  ),
                ],
              ),
            ),
        ],
      )).toList(),
    );
  }

  Widget _buildMobileRoomCard(
    BuildContext context,
    RoomEntity room,
    bool canEdit,
    RoomCubit cubit,
    CategoryCubit categoryCubit,
    String loungeId,
  ) {
    final isOccupied = room.status == RoomStatusEnum.occupied;
    final isAvailable = room.status == RoomStatusEnum.available;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isOccupied
              ? AppColors.danger.withValues(alpha: 0.5)
              : AppColors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  room.nameAr.isNotEmpty ? room.nameAr : room.nameEn,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _getSpaceTypeBadge(room.spaceType ?? room.spaceTypeId),
            ],
          ),
          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'فردي: ${room.hourlyRateSingle.toStringAsFixed(0)} ج.م/ساعة',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
              ),
              Text(
                'زوجي: ${room.hourlyRateMulti.toStringAsFixed(0)} ج.م/ساعة',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _getStatusBadge(room.status),
              if (canEdit)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'متاحة أونلاين',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                    ),
                    SizedBox(width: 4.w),
                    Switch(
                      value: isAvailable,
                      activeThumbColor: AppColors.neonBlue,
                      onChanged: (_) => cubit.toggleRoomStatus(room.id, room.status),
                    ),
                  ],
                ),
            ],
          ),
          if (canEdit) ...[
            SizedBox(height: 12.h),
            const Divider(color: AppColors.divider),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: isOccupied ? 'إنهاء حجز (مشغولة)' : 'حجز مباشر (Walk-in)',
                    variant: isOccupied ? AppButtonVariant.outlined : AppButtonVariant.primary,
                    icon: isOccupied ? Icons.check_circle_outline : Icons.play_arrow_rounded,
                    height: 48.h,
                    onPressed: () => cubit.toggleWalkInStatus(room.id, room.status),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 22.r),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () => _showEditDialog(context, cubit, categoryCubit, loungeId, room),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 22.r),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () => _confirmDelete(context, cubit, room),
                ),
              ],
            ),
          ],
        ],
      ),
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
