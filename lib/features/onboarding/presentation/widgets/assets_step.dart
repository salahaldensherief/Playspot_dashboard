import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../rooms/presentation/widgets/room_dialog.dart';
import '../cubit/onboarding_cubit.dart';

class AssetsStep extends StatelessWidget {
  final String loungeId;

  const AssetsStep({super.key, required this.loungeId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(AppStrings.assets, fontSize: 18.sp),
        SizedBox(height: 8.h),
        AppText.body(AppStrings.assetsSubtitle),
        SizedBox(height: 24.h),
        BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            if (state.rooms.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.rooms.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final room = state.rooms[index];
                return _buildRoomItem(room);
              },
            );
          },
        ),
        SizedBox(height: 24.h),
        AppButton(
          text: AppStrings.addRoomStation,
          variant: AppButtonVariant.outlined,
          icon: Icons.add,
          onPressed: () => _showAddRoomDialog(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.meeting_room_outlined, color: AppColors.textSecondary, size: 48.r),
            SizedBox(height: 16.h),
            AppText.body(AppStrings.noRoomsAdded, fontSize: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomItem(dynamic room) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.neonBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.videogame_asset, color: AppColors.neonBlue),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subHeading(room.nameEn),
                AppText.body(
                  '${room.capacity} ${AppStrings.persons} • ${room.pricePerHour} ${AppStrings.priceEgp}/hr',
                  fontSize: 12.sp,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
            onPressed: () {
              // TODO: Remove room
            },
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (diagContext) => RoomDialog(
        loungeId: loungeId,
        onSave: (newRoom) => context.read<OnboardingCubit>().addNewRoom(newRoom),
      ),
    );
  }
}
