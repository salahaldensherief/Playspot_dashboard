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

                return CustomDropdown<String>(
                  label: AppStrings.selectNewRoom,
                  value: _selectedRoomId,
                  items: availableRooms.map((r) => r.id).toList(),
                  itemLabel: (id) {
                    final found = availableRooms.firstWhere((r) => r.id == id);
                    return found.nameEn.isNotEmpty ? found.nameEn : found.nameAr;
                  },
                  onChanged: (val) => setState(() => _selectedRoomId = val),
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
                  onPressed: _selectedRoomId == null ? null : () {
                    if (_selectedRoomId != null) {
                      final availableRooms = context.read<RoomCubit>().state.rooms;
                      final foundRoom = availableRooms.firstWhere((r) => r.id == _selectedRoomId);
                      final roomName = foundRoom.nameEn.isNotEmpty ? foundRoom.nameEn : foundRoom.nameAr;
                      
                      context.read<BookingCubit>().swapRoom(
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
}
