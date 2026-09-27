import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

import 'add_booking_dialog.dart';

class RoomOccupancyWalkInSection extends StatelessWidget {
  final RoomEntity room;

  const RoomOccupancyWalkInSection({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.directions_walk_rounded, color: AppColors.danger, size: 18.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.walkInBooking,
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                    Text(
                      AppStrings.roomOccupiedByWalkIn,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: AppStrings.bookingAndClientDetails,
                icon: Icons.play_arrow_rounded,
                variant: AppButtonVariant.primary,
                height: 36.h,
                onPressed: () {
                  showDialog(
                    context: context,
                    useRootNavigator: false,
                    builder: (_) => AddBookingDialog(
                      loungeId: room.loungeId,
                      initialRoom: room,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 8.w),
            BlocBuilder<RoomCubit, RoomState>(
              buildWhen: (prev, curr) =>
                  prev.isRoomUpdating(room.id) != curr.isRoomUpdating(room.id),
              builder: (context, roomState) {
                final isUpdating = roomState.isRoomUpdating(room.id);
                return AppButton(
                  text: AppStrings.vacateRoom,
                  icon: Icons.check_circle_outline_rounded,
                  variant: AppButtonVariant.outlined,
                  height: 36.h,
                  isLoading: isUpdating,
                  onPressed: isUpdating
                      ? null
                      : () {
                          context
                              .read<RoomCubit>()
                              .toggleWalkInStatus(room.id, room.status);
                        },
                );
              },
            ),
          ],
        ),

      ],
    );
  }
}
