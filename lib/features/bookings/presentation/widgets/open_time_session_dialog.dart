import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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
      final message = bookingCubit.state.errorMessage ?? 'تعذر بدء الوقت المفتوح';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
      return;
    }

    roomCubit.watchRooms(widget.room.loungeId, forceRefresh: true);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم بدء الوقت المفتوح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460.w),
        child: Padding(
          padding: EdgeInsets.all(22.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'بدء وقت مفتوح - ${room.nameAr.isNotEmpty ? room.nameAr : room.nameEn}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'اسم العميل اختياري',
                  filled: true,
                  fillColor: AppColors.mutedBackground,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف اختياري',
                  filled: true,
                  fillColor: AppColors.mutedBackground,
                ),
              ),
              SizedBox(height: 14.h),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'single', label: Text('Single')),
                  ButtonSegment(value: 'multi', label: Text('Multi')),
                ],
                selected: {_playMode},
                onSelectionChanged: (values) {
                  setState(() => _playMode = values.first);
                },
              ),
              SizedBox(height: 12.h),
              Text(
                'الحساب سيتم عند إنهاء الجلسة حسب إعدادات الغرفة. الحجوزات المؤكدة القادمة تظل لها الأولوية.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 22.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    text: 'بدء الوقت المفتوح',
                    icon: Icons.play_arrow_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _start,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
