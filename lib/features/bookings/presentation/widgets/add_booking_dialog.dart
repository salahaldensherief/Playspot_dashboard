import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking_price_calculator.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_customer_fields.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_extras_section.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_immediate_toggle.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_play_mode_selector.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_room_selector.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_schedule_picker.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_summary_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_voucher_section.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';

class AddBookingDialog extends StatefulWidget {
  final String loungeId;
  final RoomEntity? initialRoom;
  final bool quickMode;

  const AddBookingDialog({
    super.key,
    required this.loungeId,
    this.initialRoom,
    this.quickMode = false,
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
  bool _startSessionImmediately = true;
  bool _isSubmitting = false;
  String _playMode = 'single';

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
    setState(() {
      _selectedExtras = extras;
    });
  }

  void _onVoucherChanged(({String? code, double discount}) voucher) {
    setState(() {
      _appliedVoucherCode = voucher.code;
      _voucherDiscount = voucher.discount;
    });
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

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate() || _selectedRoom == null) return;
    setState(() => _isSubmitting = true);
    try {
      if (_startSessionImmediately) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: Text('booking_cash_confirmation_title'.tr()),
            content: Text(
              (widget.quickMode
                      ? 'booking_cash_confirmation_quick_description'
                      : 'booking_cash_confirmation_description')
                  .tr(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('booking_cash_confirmation_action'.tr()),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
      }

      if (widget.quickMode) {
        final now = DateTime.now();
        _selectedDate = now;
        _startTime = TimeOfDay.fromDateTime(now);
      }

      final durationMinutes = context
          .read<BookingCubit>()
          .state
          .selectedDurationMinutes;
      final endTime = _calculateEndTime(_startTime, durationMinutes);

      final startTimeStr =
          "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00";
      final endTimeStr =
          "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00";

      final bookingCubit = context.read<BookingCubit>();
      final selectedRoom = _selectedRoom!;

      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));

      // 1. Local time overlap check
      final isOverlapping = bookingCubit.state.bookings.any((b) {
        if (b.roomId != selectedRoom.id ||
            b.status == BookingStatus.cancelled ||
            b.status == BookingStatus.rejected) {
          return false;
        }

        return b.date.year == _selectedDate.year &&
            b.date.month == _selectedDate.month &&
            b.date.day == _selectedDate.day &&
            _checkTimeOverlap(b.startTime, b.endTime, startTimeStr, endTimeStr);
      });

      if (isOverlapping) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.overlappingBookingError),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      // 2. Server slot verification
      try {
        final holdResult = await bookingCubit.repository.verifyAndHoldSlot(
          roomId: selectedRoom.id,
          startTime: startDateTime,
          endTime: endDateTime,
          holdMinutes: 10,
        );
        if (!mounted) return;
        final holdFailure = holdResult.fold((failure) => failure, (_) => null);
        if (holdFailure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(holdFailure.message),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
      } catch (e) {
        if (mounted) {
          final cleanMsg = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cleanMsg),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final activeShiftId = context.read<ShiftCubit>().state.activeShift?.id;

      // Single source of truth calculation via BookingPriceCalculator
      final calculation = BookingPriceCalculator.calculate(
        room: selectedRoom,
        durationMinutes: durationMinutes,
        extras: _selectedExtras,
        voucherDiscount: _voucherDiscount,
        playMode: _playMode,
      );

      final booking = Booking(
        id: '',
        userId: '',
        userName: _nameController.text.trim().isEmpty
            ? AppStrings.walkInCustomer
            : _nameController.text.trim(),
        userPhone: _phoneController.text.trim(),
        loungeId: widget.loungeId,
        roomId: selectedRoom.id,
        loungeName: '',
        roomName: selectedRoom.nameAr.isNotEmpty
            ? selectedRoom.nameAr
            : selectedRoom.nameEn,
        controllersCount: selectedRoom.controllersCount,
        screenSize: selectedRoom.screenSize,
        date: _selectedDate,
        startTime: startTimeStr,
        endTime: endTimeStr,
        durationMinutes: durationMinutes,
        status: _startSessionImmediately
            ? BookingStatus.inProgress
            : BookingStatus.upcoming,
        paymentStatus: _startSessionImmediately
            ? PaymentStatus.paid
            : PaymentStatus.unpaid,
        totalPrice: calculation.grandTotal,
        voucherDiscount: calculation.voucherDiscount,
        voucherCode: _appliedVoucherCode,
        extras: _selectedExtras,
        shiftId: activeShiftId,
        playMode: _playMode,
        roomPrice: calculation.roomTotal,
      );

      final success = await bookingCubit.createBooking(booking);
      if (success && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return Dialog(
      backgroundColor: AppColors.scaffoldBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AbsorbPointer(
            absorbing: _isSubmitting,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AppText.heading(
                          widget.quickMode
                              ? AppStrings.walkInBooking
                              : AppStrings.detailedBooking,
                          fontSize: 24,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
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

                  // Room Selector Widget
                  if (!widget.quickMode)
                    AddBookingRoomSelector(
                      initialRoom: widget.initialRoom,
                      selectedRoom: _selectedRoom,
                      onRoomSelected: (val) =>
                          setState(() => _selectedRoom = val),
                    ),
                  if (!widget.quickMode) SizedBox(height: 16.h),

                  // Play Mode Selector Widget
                  AddBookingPlayModeSelector(
                    room: _selectedRoom,
                    selectedMode: _playMode,
                    onModeChanged: (mode) => setState(() => _playMode = mode),
                  ),
                  SizedBox(height: 24.h),

                  // Date, Time & Duration Picker
                  AddBookingSchedulePicker(
                    selectedDate: _selectedDate,
                    startTime: _startTime,
                    onDateChanged: (date) =>
                        setState(() => _selectedDate = date),
                    onStartTimeChanged: (time) =>
                        setState(() => _startTime = time),
                    quickMode: widget.quickMode,
                  ),
                  SizedBox(height: 20.h),

                  // Extras Section
                  if (!widget.quickMode)
                    AddBookingExtrasSection(
                      loungeId: widget.loungeId,
                      selectedExtras: _selectedExtras,
                      onExtrasChanged: _onExtrasChanged,
                    ),
                  if (!widget.quickMode) SizedBox(height: 20.h),

                  // Immediate Session Start Toggle
                  if (!widget.quickMode)
                    AddBookingImmediateToggle(
                      isImmediate: _startSessionImmediately,
                      onChanged: (val) =>
                          setState(() => _startSessionImmediately = val),
                    ),
                  if (!widget.quickMode) SizedBox(height: 20.h),

                  // Voucher Section
                  if (!widget.quickMode)
                    AddBookingVoucherSection(
                      onVoucherChanged: _onVoucherChanged,
                    ),
                  if (!widget.quickMode) SizedBox(height: 20.h),

                  // Price Calculation Summary Card
                  if (_selectedRoom != null)
                    BlocBuilder<BookingCubit, BookingState>(
                      buildWhen: (p, c) =>
                          p.selectedDurationMinutes !=
                          c.selectedDurationMinutes,
                      builder: (context, state) {
                        return AddBookingSummaryCard(
                          room: _selectedRoom,
                          durationMinutes: state.selectedDurationMinutes,
                          selectedExtras: _selectedExtras,
                          voucherDiscount: _voucherDiscount,
                          playMode: _playMode,
                        );
                      },
                    ),
                  SizedBox(height: 24.h),

                  // Action Buttons
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      AppButton(
                        text: AppStrings.cancel,
                        variant: AppButtonVariant.text,
                        onPressed: () => Navigator.pop(context),
                      ),
                      AppButton(
                        text: widget.quickMode
                            ? AppStrings.walkInBooking
                            : AppStrings.newBooking,
                        variant: AppButtonVariant.primary,
                        isLoading: _isSubmitting,
                        onPressed: _selectedRoom == null || _isSubmitting
                            ? null
                            : _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
