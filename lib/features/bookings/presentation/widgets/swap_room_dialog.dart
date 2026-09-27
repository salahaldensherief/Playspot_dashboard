import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';

class SwapRoomDialog extends StatefulWidget {
  final String bookingId;
  final String currentRoomId;

  const SwapRoomDialog({
    super.key,
    required this.bookingId,
    required this.currentRoomId,
  });

  @override
  State<SwapRoomDialog> createState() => _SwapRoomDialogState();
}

class _SwapRoomDialogState extends State<SwapRoomDialog> {
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<LoginCubit>().state.user;
      final loungeId = user?.loungeId;
      if (loungeId != null && loungeId.isNotEmpty) {
        context.read<RoomCubit>().watchRooms(loungeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 450.w,
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.heading(AppStrings.swapRoom, fontSize: 24.sp),
            SizedBox(height: 24.h),
            BlocBuilder<RoomCubit, RoomState>(
              builder: (context, state) {
                final availableRooms = state.rooms
                    .where((r) => r.status == RoomStatusEnum.available && r.id != widget.currentRoomId)
                    .toList();

                if (state.status == RoomStatus.loading && availableRooms.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.neonBlue)),
                  );
                }

                if (availableRooms.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Center(
                      child: AppText.body(AppStrings.noAvailableRooms, color: AppColors.danger),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDropdown<String>(
                      label: AppStrings.selectNewRoom,
                      value: _selectedRoomId,
                      items: availableRooms.map((r) => r.id).toList(),
                      itemLabel: (id) {
                        final found = availableRooms.firstWhere((r) => r.id == id);
                        return found.nameEn.isNotEmpty ? found.nameEn : found.nameAr;
                      },
                      onChanged: (val) => setState(() => _selectedRoomId = val),
                    ),
                    if (_selectedRoomId != null) ...[
                      SizedBox(height: 20.h),
                      _buildRateBreakdownCard(state.rooms),
                    ],
                  ],
                );
              },
            ),
            SizedBox(height: 32.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: AppStrings.cancel,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 16.w),
                AppButton(
                  text: AppStrings.confirmSwap,
                  onPressed: _selectedRoomId == null
                      ? null
                      : () {
                          if (_selectedRoomId != null) {
                            final bookingCubit = context.read<BookingCubit>();
                            final bookings = bookingCubit.state.bookings;
                            final currentBookingList = bookings.where((b) => b.id == widget.bookingId);

                            if (currentBookingList.isNotEmpty) {
                              final b = currentBookingList.first;
                              if (b.status != BookingStatus.inProgress && b.checkedInAt == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'يجب بدء الجلسة أولاً قبل تبديل الغرفة (تطلب وقت البدء الفعلي).',
                                    ),
                                    backgroundColor: AppColors.danger,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }
                            }

                            final availableRooms = context.read<RoomCubit>().state.rooms;
                            final foundRoom = availableRooms.firstWhere((r) => r.id == _selectedRoomId);
                            final roomName =
                                foundRoom.nameEn.isNotEmpty ? foundRoom.nameEn : foundRoom.nameAr;

                            bookingCubit.swapRoom(
                              widget.bookingId,
                              _selectedRoomId!,
                              user?.id ?? '',
                              newRoomName: roomName,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.roomSwappedSuccess),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateBreakdownCard(List<RoomEntity> rooms) {
    final currentRoomList = rooms.where((r) => r.id == widget.currentRoomId);
    final targetRoomList = rooms.where((r) => r.id == _selectedRoomId);

    if (currentRoomList.isEmpty || targetRoomList.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentRoom = currentRoomList.first;
    final targetRoom = targetRoomList.first;

    final currentRate = currentRoom.hourlyRateSingle;
    final targetRate = targetRoom.hourlyRateSingle;
    final diff = targetRate - currentRate;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.currentRoom}: ${currentRoom.nameEn.isNotEmpty ? currentRoom.nameEn : currentRoom.nameAr}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
              ),
              Text(
                '${currentRate.toStringAsFixed(2)} ${AppStrings.egp}/hr',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.selectNewRoom}: ${targetRoom.nameEn.isNotEmpty ? targetRoom.nameEn : targetRoom.nameAr}',
                style: TextStyle(color: AppColors.neonBlue, fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
              Text(
                '${targetRate.toStringAsFixed(2)} ${AppStrings.egp}/hr',
                style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            ],
          ),
          Divider(color: AppColors.borderDefault, height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.recalculatedRateDifference,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(2)} ${AppStrings.egp}/hr',
                style: TextStyle(
                  color: diff > 0
                      ? AppColors.warning
                      : (diff < 0 ? AppColors.success : AppColors.textSecondary),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
