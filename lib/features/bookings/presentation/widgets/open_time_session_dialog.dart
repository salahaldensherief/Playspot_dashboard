import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';

class OpenTimeSessionDialog extends StatefulWidget {
  final RoomEntity room;

  const OpenTimeSessionDialog({super.key, required this.room});

  @override
  State<OpenTimeSessionDialog> createState() => _OpenTimeSessionDialogState();
}

class _OpenTimeSessionDialogState extends State<OpenTimeSessionDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _playMode = 'single';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_isSubmitting) return;

    final allowOpenTime =
        context.read<LoginCubit>().state.userLounge?.allowOpenTimeSessions ??
        false;
    if (!allowOpenTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.openTimeDisabledByPolicy),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final bookingCubit = context.read<BookingCubit>();
    final roomCubit = context.read<RoomCubit>();
    final result = await bookingCubit.startOpenTimeSession(
      roomId: widget.room.id,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      playMode: _playMode,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result == null) {
      final message =
          bookingCubit.state.errorMessage ?? AppStrings.failedToStartOpenTime;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
      return;
    }

    roomCubit.watchRooms(widget.room.loungeId, forceRefresh: true);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppStrings.openTimeStartedSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final room = widget.room;

    return AppDialog(
      title: '${AppStrings.startOpenTime} - ${room.nameAr.isNotEmpty ? room.nameAr : room.nameEn}',
      icon: Icons.timer_outlined,
      width: 460.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.startOpenTime,
          icon: Icons.play_arrow_rounded,
          isLoading: _isSubmitting,
          onPressed: _start,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: AppStrings.customerNameOptional,
              filled: true,
              fillColor: AppColors.mutedBackground,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: AppStrings.customerPhoneOptional,
              filled: true,
              fillColor: AppColors.mutedBackground,
            ),
          ),
          SizedBox(height: 14.h),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'single',
                label: Text(AppStrings.single),
              ),
              ButtonSegment(value: 'multi', label: Text(AppStrings.multi)),
            ],
            selected: {_playMode},
            onSelectionChanged: (values) {
              setState(() => _playMode = values.first);
            },
          ),
          SizedBox(height: 12.h),
          Text(
            AppStrings.openTimeDialogNotice,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
