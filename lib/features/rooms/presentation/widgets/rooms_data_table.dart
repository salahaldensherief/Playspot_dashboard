import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
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
    context.locale;
    final user = context.watch<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';
    final permissions = context.watch<PermissionsCubit>();
    final bool canEdit =
        user != null &&
        permissions.hasPermission(
          'rooms_manage',
          userRole: user.role.name,
          userId: user.id,
        );
    final roomCubit = context.read<RoomCubit>();
    final categoryCubit = context.read<CategoryCubit>();

    return DataTableWidget(
      mobileCardBuilder: (ctx, index) {
        final room = rooms[index];
        return _buildMobileRoomCard(
          ctx,
          room,
          canEdit,
          roomCubit,
          categoryCubit,
          loungeId,
        );
      },
      columns: [
        AppStrings.roomName,
        AppStrings.spaceType,
        AppStrings.pricePerHour,
        AppStrings.extraControllerPrice,
        AppStrings.status,
        if (canEdit) AppStrings.onlineAvailable,
        if (canEdit) AppStrings.actions,
      ],
      rows: rooms
          .map(
            (room) => DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _roomName(context, room),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (room.nameEn.isNotEmpty &&
                          room.nameAr.isNotEmpty &&
                          room.nameEn != room.nameAr)
                        Text(
                          context.locale.languageCode == 'ar'
                              ? room.nameEn
                              : room.nameAr,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                DataCell(
                  _getSpaceTypeBadge(room.spaceType ?? room.spaceTypeId),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppStrings.singlePriceLabel} ${room.hourlyRateSingle.toStringAsFixed(0)} ${AppStrings.egpPerHour}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${AppStrings.multiPriceLabel} ${room.hourlyRateMulti.toStringAsFixed(0)} ${AppStrings.egpPerHour}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    '+${room.extraControllerPrice.toStringAsFixed(0)} ${AppStrings.egpPerHour}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                DataCell(_getStatusBadge(room.status)),
                if (canEdit)
                  DataCell(
                    Switch(
                      value: room.status == RoomStatusEnum.available,
                      activeThumbColor: AppColors.neonBlue,
                      onChanged: room.status == RoomStatusEnum.occupied
                          ? null
                          : (val) => roomCubit.toggleRoomStatus(
                              room.id,
                              room.status,
                            ),
                    ),
                  ),
                if (canEdit)
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          tooltip: AppStrings.edit,
                          icon: Icon(
                            Icons.edit_outlined,
                            color: AppColors.textSecondary,
                            size: 20.r,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () => _showEditDialog(
                            context,
                            roomCubit,
                            categoryCubit,
                            loungeId,
                            room,
                          ),
                        ),
                        IconButton(
                          tooltip: AppStrings.delete,
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                            size: 20.r,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () =>
                              _confirmDelete(context, roomCubit, room),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )
          .toList(),
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
                  _roomName(context, room),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _getSpaceTypeBadge(room.spaceType ?? room.spaceTypeId),
            ],
          ),
          SizedBox(height: 8.h),

          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(
                '${AppStrings.singlePriceLabel} ${room.hourlyRateSingle.toStringAsFixed(0)} ${AppStrings.egpPerHour}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '${AppStrings.multiPriceLabel} ${room.hourlyRateMulti.toStringAsFixed(0)} ${AppStrings.egpPerHour}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _getStatusBadge(room.status),
              if (canEdit)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      AppStrings.onlineAvailable,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    Switch(
                      value: isAvailable,
                      activeThumbColor: AppColors.neonBlue,
                      onChanged: isOccupied
                          ? null
                          : (_) => cubit.toggleRoomStatus(room.id, room.status),
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
                    text: AppStrings.bookings,
                    variant: isOccupied
                        ? AppButtonVariant.outlined
                        : AppButtonVariant.primary,
                    icon: isOccupied
                        ? Icons.check_circle_outline
                        : Icons.play_arrow_rounded,
                    height: 48.h,
                    onPressed: () => context.go(RouterKeys.loungeAdminLiveOps),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  tooltip: AppStrings.edit,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary,
                    size: 22.r,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _showEditDialog(
                    context,
                    cubit,
                    categoryCubit,
                    loungeId,
                    room,
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.delete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                    size: 22.r,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _confirmDelete(context, cubit, room),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    RoomCubit cubit,
    CategoryCubit categoryCubit,
    String loungeId,
    RoomEntity room,
  ) {
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

  void _confirmDelete(
    BuildContext context,
    RoomCubit cubit,
    RoomEntity room,
  ) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.deleteConfirmation,
      message: '${AppStrings.deleteWarning} "${_roomName(context, room)}"?',
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
        return StatusBadge.success(AppStrings.availableStatus);
      case RoomStatusEnum.maintenance:
        return StatusBadge.warning(AppStrings.maintenanceStatus);
      case RoomStatusEnum.occupied:
        return StatusBadge.danger(AppStrings.occupiedStatus);
    }
  }

  String _roomName(BuildContext context, RoomEntity room) {
    final primary = context.locale.languageCode == 'ar'
        ? room.nameAr
        : room.nameEn;
    return primary.isNotEmpty
        ? primary
        : (room.nameAr.isNotEmpty ? room.nameAr : room.nameEn);
  }

  Widget _getSpaceTypeBadge(String? type) {
    final typeLower = type?.toLowerCase() ?? '';
    if (typeLower.contains('open') ||
        typeLower.contains('صالة') ||
        typeLower == 'open_area') {
      return StatusBadge.info(AppStrings.openArea);
    } else if (typeLower.contains('vip') ||
        typeLower.contains('فيب') ||
        typeLower == 'vip_room') {
      return StatusBadge.warning(AppStrings.vipRoom);
    } else if (typeLower.contains('standard') ||
        typeLower.contains('عادية') ||
        typeLower == 'standard_room') {
      return StatusBadge.secondary(AppStrings.standardRoom);
    } else {
      return StatusBadge.neutral(type ?? AppStrings.notAvailable);
    }
  }
}
