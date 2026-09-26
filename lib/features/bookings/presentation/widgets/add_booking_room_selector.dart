import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

class AddBookingRoomSelector extends StatelessWidget {
  final RoomEntity? initialRoom;
  final RoomEntity? selectedRoom;
  final ValueChanged<RoomEntity?> onRoomSelected;

  const AddBookingRoomSelector({
    super.key,
    this.initialRoom,
    required this.selectedRoom,
    required this.onRoomSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(AppStrings.roomLabel, fontWeight: FontWeight.bold),
        SizedBox(height: 8.h),
        if (initialRoom != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.sports_esports_rounded, color: AppColors.neonBlue, size: 20.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    initialRoom!.nameAr.isNotEmpty ? initialRoom!.nameAr : initialRoom!.nameEn,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                if (initialRoom!.activityNames.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      initialRoom!.activityNames.first,
                      style: TextStyle(
                        color: AppColors.neonBlue,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          BlocBuilder<RoomCubit, RoomState>(
            builder: (context, state) {
              final rooms = state.rooms
                  .where((r) => r.status == RoomStatusEnum.available || r.id == selectedRoom?.id)
                  .toList();

              final selectedRoomInList = rooms.cast<RoomEntity?>().firstWhere(
                (r) => r?.id == selectedRoom?.id,
                orElse: () => rooms.isNotEmpty ? rooms.first : null,
              );

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RoomEntity>(
                    value: selectedRoomInList,
                    hint: AppText.body(AppStrings.roomLabel, color: AppColors.textSecondary),
                    isExpanded: true,
                    dropdownColor: AppColors.cardBackground,
                    items: rooms
                        .map((room) => DropdownMenuItem<RoomEntity>(
                              value: room,
                              child: AppText.body(room.nameAr.isNotEmpty ? room.nameAr : room.nameEn),
                            ))
                        .toList(),
                    onChanged: onRoomSelected,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
