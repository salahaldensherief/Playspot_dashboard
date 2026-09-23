import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

class RoomOccupancyAvailableSection extends StatelessWidget {
  final RoomEntity room;
  final String loungeId;

  const RoomOccupancyAvailableSection({
    super.key,
    required this.room,
    required this.loungeId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.body('سعر الفردي:', fontSize: 11.sp, color: AppColors.textSecondary),
                  AppText.body(
                    '${room.pricePerHourSingle.toStringAsFixed(0)} ${AppStrings.egp}/ساعة',
                    fontSize: 11.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.body('سعر الزوجي (Multi):', fontSize: 11.sp, color: AppColors.textSecondary),
                  AppText.body(
                    '${room.pricePerHourMulti.toStringAsFixed(0)} ${AppStrings.egp}/ساعة',
                    fontSize: 11.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // One-Tap Walk-in Quick Toggle & Quick Booking Dialog
        BlocBuilder<RoomCubit, RoomState>(
          buildWhen: (prev, curr) => prev.isRoomUpdating(room.id) != curr.isRoomUpdating(room.id),
          builder: (context, roomState) {
            final isUpdating = roomState.isRoomUpdating(room.id);
            return Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'حجز مباشر (Walk-in)',
                    icon: Icons.flash_on_rounded,
                    variant: AppButtonVariant.primary,
                    height: 36.h,
                    isLoading: isUpdating,
                    onPressed: isUpdating
                        ? null
                        : () {
                            context.read<RoomCubit>().toggleWalkInStatus(room.id, room.status);
                          },
                  ),
                ),
                SizedBox(width: 8.w),
                AppButton(
                  text: 'حجز تفصيلي',
                  icon: Icons.add_rounded,
                  variant: AppButtonVariant.outlined,
                  height: 36.h,
                  onPressed: () {
                    showDialog(
                      context: context,
                      useRootNavigator: false,
                      builder: (_) => AddBookingDialog(
                        loungeId: loungeId,
                        initialRoom: room,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
