import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_customer_fields.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_extras_section.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_schedule_picker.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_summary_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_voucher_section.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';

class AddBookingDialog extends StatefulWidget {
  final String loungeId;
  final RoomEntity? initialRoom;

  const AddBookingDialog({
    super.key,
    required this.loungeId,
    this.initialRoom,
  });

  @override
  State<AddBookingDialog> createState() => _AddBookingDialogState();
}

class _AddBookingDialogState extends State<AddBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _appliedVoucherCode;
  double _voucherDiscount = 0.0;

  RoomEntity? _selectedRoom;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  List<Map<String, dynamic>> _selectedExtras = [];
  double _extrasTotal = 0.0;
  bool _startSessionImmediately = true;

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.initialRoom;
    context.read<BookingCubit>().updateSelectedDuration(60);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onExtrasChanged(List<Map<String, dynamic>> extras) {
    double total = 0.0;
    for (final item in extras) {
      final qty = item['quantity'] ?? item['qty'] ?? 1;
      final price = (item['price'] ?? item['unit_price'] ?? 0.0) as num;
      total += price.toDouble() * (qty as num).toDouble();
    }
    setState(() {
      _selectedExtras = extras;
      _extrasTotal = total;
    });
  }

  void _onVoucherChanged(({String? code, double discount}) voucher) {
    setState(() {
      _appliedVoucherCode = voucher.code;
      _voucherDiscount = voucher.discount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.scaffoldBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500.r,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.heading(AppStrings.newBooking, fontSize: 24.sp),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Divider(height: 32.h, color: AppColors.borderDefault),

                // Customer Info
                AddBookingCustomerFields(
                  nameController: _nameController,
                  phoneController: _phoneController,
                ),
                SizedBox(height: 16.h),

                // Room Selection
                AppText.body(AppStrings.roomLabel, fontWeight: FontWeight.bold),
                SizedBox(height: 8.h),
                BlocBuilder<RoomCubit, RoomState>(
                  builder: (context, state) {
                    final rooms = state.rooms.where((r) => r.status == RoomStatusEnum.available).toList();
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RoomEntity>(
                          value: _selectedRoom,
                          hint: AppText.body(AppStrings.roomLabel, color: AppColors.textSecondary),
                          isExpanded: true,
                          dropdownColor: AppColors.cardBackground,
                          items: rooms
                              .map((room) => DropdownMenuItem(
                                    value: room,
                                    child: AppText.body(room.nameEn),
                                  ))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedRoom = val),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24.h),

                // Date, Time & Duration Picker
                AddBookingSchedulePicker(
                  selectedDate: _selectedDate,
                  startTime: _startTime,
                  onDateChanged: (date) => setState(() => _selectedDate = date),
                  onStartTimeChanged: (time) => setState(() => _startTime = time),
                ),
                SizedBox(height: 20.h),

                // Extras Section
                AddBookingExtrasSection(
                  loungeId: widget.loungeId,
                  selectedExtras: _selectedExtras,
                  onExtrasChanged: _onExtrasChanged,
                ),
                SizedBox(height: 20.h),

                // Start Session Immediately Switch
                _buildImmediateSwitch(),
                SizedBox(height: 20.h),

                // Voucher Section
                AddBookingVoucherSection(onVoucherChanged: _onVoucherChanged),
                SizedBox(height: 20.h),

                // Price Calculation Summary
                if (_selectedRoom != null)
                  BlocBuilder<BookingCubit, BookingState>(
                    buildWhen: (p, c) => p.selectedDurationMinutes != c.selectedDurationMinutes,
                    builder: (context, state) {
                      return AddBookingSummaryCard(
                        room: _selectedRoom,
                        durationMinutes: state.selectedDurationMinutes,
                        extrasTotal: _extrasTotal,
                        voucherDiscount: _voucherDiscount,
                      );
                    },
                  ),
                SizedBox(height: 24.h),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: AppStrings.cancel,
                      variant: AppButtonVariant.text,
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 16.w),
                    AppButton(
                      text: AppStrings.newBooking,
                      variant: AppButtonVariant.primary,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImmediateSwitch() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: _startSessionImmediately ? AppColors.neonBlue.withValues(alpha: 0.5) : AppColors.borderDefault,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: _startSessionImmediately ? AppColors.neonBlue : AppColors.textMuted,
                  size: 22.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        'بدء الجلسة وعّد الوقت فوراً عند الحفظ',
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                      AppText.body(
                        'سيتم تحويل الغرفة لمشغولة وتشغيل حاسبة وقت اللعب والإضافات فوراً',
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _startSessionImmediately,
            activeTrackColor: AppColors.neonBlue.withValues(alpha: 0.4),
            activeThumbColor: AppColors.neonBlue,
            onChanged: (val) => setState(() => _startSessionImmediately = val),
          ),
        ],
      ),
    );
  }



  TimeOfDay _calculateEndTime(TimeOfDay start, int durationMinutes) {
    int totalMinutes = start.hour * 60 + start.minute + durationMinutes;
    int hour = (totalMinutes ~/ 60) % 24;
    int minute = totalMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _checkTimeOverlap(String s1, String e1, String s2, String e2) {
    return s1.compareTo(e2) < 0 && e1.compareTo(s2) > 0;
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedRoom == null) return;

    final durationMinutes = context.read<BookingCubit>().state.selectedDurationMinutes;
    final endTime = _calculateEndTime(_startTime, durationMinutes);

    final startTimeStr =
        "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00";
    final endTimeStr =
        "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00";

    final bookingCubit = context.read<BookingCubit>();
    final selectedRoom = _selectedRoom;
    if (selectedRoom == null) return;

    final isOverlapping = bookingCubit.state.bookings.any((b) {
      if (b.roomId != selectedRoom.id || b.status == BookingStatus.cancelled) return false;

      return b.date.year == _selectedDate.year &&
          b.date.month == _selectedDate.month &&
          b.date.day == _selectedDate.day &&
          _checkTimeOverlap(b.startTime, b.endTime, startTimeStr, endTimeStr);
    });

    if (isOverlapping) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.overlappingBookingError), backgroundColor: AppColors.danger),
      );
      return;
    }

    final activeShiftId = context.read<ShiftCubit>().state.activeShift?.id;
    final double roomTotal = (durationMinutes / 60.0) * selectedRoom.pricePerHour;
    final double grandTotal = (roomTotal + _extrasTotal - _voucherDiscount).clamp(0.0, double.infinity);

    final booking = Booking(
      id: '',
      userId: '',
      userName: _nameController.text,
      userPhone: _phoneController.text,
      loungeId: widget.loungeId,
      roomId: selectedRoom.id,
      roomName: selectedRoom.nameEn,
      date: _selectedDate,
      startTime: startTimeStr,
      endTime: endTimeStr,
      durationMinutes: durationMinutes,
      status: _startSessionImmediately ? BookingStatus.inProgress : BookingStatus.upcoming,
      checkedInAt: _startSessionImmediately ? DateTime.now() : null,
      totalPrice: grandTotal,
      addonsPrice: _extrasTotal > 0 ? _extrasTotal : null,
      voucherDiscount: _voucherDiscount > 0 ? _voucherDiscount : null,
      voucherCode: _appliedVoucherCode,
      extras: _selectedExtras,
      shiftId: activeShiftId,
    );

    context.read<BookingCubit>().createManualBooking(booking);
    Navigator.pop(context);
  }
}
