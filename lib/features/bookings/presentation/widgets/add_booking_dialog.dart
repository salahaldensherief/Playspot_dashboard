import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_extras_dialog.dart';

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
  final _voucherCodeController = TextEditingController();

  bool _isValidatingVoucher = false;
  String? _appliedVoucherCode;
  double _voucherDiscount = 0.0;
  String? _voucherError;
  
  RoomEntity? _selectedRoom;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  List<Map<String, dynamic>> _selectedExtras = [];
  double _extrasTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.initialRoom;
    // Default duration is 60 mins
    context.read<BookingCubit>().updateSelectedDuration(60);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _voucherCodeController.dispose();
    super.dispose();
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
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nameController,
                        label: AppStrings.customerName,
                        hint: AppStrings.fullName,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        label: AppStrings.phoneNumber,
                        hint: "01xxxxxxxxx",
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
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
                          items: rooms.map((room) => DropdownMenuItem(
                            value: room,
                            child: AppText.body(room.nameEn),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedRoom = val),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24.h),

                // Date & Time Selection
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildPickerField(
                        label: AppStrings.date,
                        value: DateFormat('yyyy-MM-dd').format(_selectedDate),
                        icon: Icons.calendar_today,
                        onTap: _pickDate,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: 2,
                      child: _buildPickerField(
                        label: AppStrings.opensAt,
                        value: _startTime.format(context),
                        icon: Icons.access_time,
                        onTap: _pickStartTime,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: 3,
                      child: BlocBuilder<BookingCubit, BookingState>(
                        buildWhen: (p, c) => p.selectedDurationMinutes != c.selectedDurationMinutes,
                        builder: (context, state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.body("Duration", fontWeight: FontWeight.bold),
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: AppColors.borderDefault),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: AppColors.neonBlue, size: 20),
                                      onPressed: state.selectedDurationMinutes > 30 
                                        ? () => context.read<BookingCubit>().updateSelectedDuration(state.selectedDurationMinutes - 30)
                                        : null,
                                    ),
                                    AppText.body("${state.selectedDurationMinutes / 60.0} hrs"),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: AppColors.neonBlue, size: 20),
                                      onPressed: () => context.read<BookingCubit>().updateSelectedDuration(state.selectedDurationMinutes + 30),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                // End Time Display
                BlocBuilder<BookingCubit, BookingState>(
                  buildWhen: (p, c) => p.selectedDurationMinutes != c.selectedDurationMinutes,
                  builder: (context, state) {
                    final endTime = _calculateEndTime(_startTime, state.selectedDurationMinutes);
                    return AppText.body(
                      "Ends at: ${endTime.format(context)} (${state.selectedDurationMinutes / 60.0} hrs total)",
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    );
                  },
                ),

                SizedBox(height: 20.h),

                // Extras Section
                _buildExtrasSection(),

                SizedBox(height: 20.h),

                // Voucher Section
                _buildVoucherSection(),

                SizedBox(height: 20.h),

                // Price Calculation Summary
                if (_selectedRoom != null) 
                  BlocBuilder<BookingCubit, BookingState>(
                    buildWhen: (p, c) => p.selectedDurationMinutes != c.selectedDurationMinutes,
                    builder: (context, state) {
                      return _buildSummaryCard(state.selectedDurationMinutes);
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontWeight: FontWeight.bold),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: AppColors.borderDefault)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: AppColors.borderDefault)),
          ),
          validator: (val) => val == null || val.isEmpty ? AppStrings.fieldRequired : null,
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontWeight: FontWeight.bold),
        SizedBox(height: 8.h),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.neonBlue),
                SizedBox(width: 8.w),
                Expanded(
                  child: AppText.body(
                    value, 
                    fontSize: 13.sp,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExtrasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu_rounded, size: 18.r, color: AppColors.neonBlue),
                SizedBox(width: 6.w),
                AppText.body(AppStrings.extras, fontWeight: FontWeight.bold),
              ],
            ),
            InkWell(
              onTap: _openAddExtrasModal,
              borderRadius: BorderRadius.circular(6.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16.r, color: AppColors.neonBlue),
                    SizedBox(width: 4.w),
                    AppText.body(
                      AppStrings.addExtrasToSession,
                      fontSize: 12.sp,
                      color: AppColors.neonBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_selectedExtras.isEmpty)
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16.r, color: AppColors.textMuted),
                SizedBox(width: 8.w),
                Expanded(
                  child: AppText.body(
                    'لم يتم إضافة مشروبات أو مأكولات مع الحجز حتى الآن',
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _selectedExtras.map((item) {
              final name = item['name_ar'] ?? item['name'] ?? '';
              final qty = item['quantity'] ?? item['qty'] ?? 1;
              final price = (item['price'] ?? item['unit_price'] ?? 0.0) * qty;

              return Chip(
                backgroundColor: AppColors.neonBlue.withValues(alpha: 0.1),
                side: const BorderSide(color: AppColors.neonBlue),
                avatar: CircleAvatar(
                  backgroundColor: AppColors.neonBlue,
                  child: Text('$qty', style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                ),
                label: Text(
                  '$name (${price.toStringAsFixed(0)} ${AppStrings.egp})',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 11.sp),
                ),
                deleteIcon: const Icon(Icons.close, size: 14),
                deleteIconColor: AppColors.danger,
                onDeleted: () {
                  setState(() {
                    _selectedExtras.remove(item);
                    _extrasTotal -= price;
                    if (_extrasTotal < 0) _extrasTotal = 0;
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  void _openAddExtrasModal() {
    showDialog(
      context: context,
      builder: (ctx) => AddExtrasDialog(
        bookingId: '',
        loungeId: widget.loungeId,
        onConfirm: (extras, totalCost) {
          setState(() {
            _selectedExtras = extras;
            _extrasTotal = totalCost;
          });
        },
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body('كود القسيمة / Voucher Code', fontWeight: FontWeight.bold),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _voucherCodeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل الكود (مثال: 9326D324)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                ),
                onChanged: (_) {
                  if (_voucherError != null || _appliedVoucherCode != null) {
                    setState(() {
                      _voucherError = null;
                      _appliedVoucherCode = null;
                      _voucherDiscount = 0.0;
                    });
                  }
                },
              ),
            ),
            SizedBox(width: 8.w),
            AppButton(
              text: _isValidatingVoucher ? 'جاري التحقق...' : 'تطبيق',
              variant: AppButtonVariant.primary,
              isLoading: _isValidatingVoucher,
              onPressed: _isValidatingVoucher ? null : _validateVoucher,
            ),
          ],
        ),
        if (_voucherError != null) ...[
          SizedBox(height: 6.h),
          Text(
            _voucherError!,
            style: TextStyle(color: AppColors.danger, fontSize: 12.sp),
          ),
        ],
        if (_appliedVoucherCode != null) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 16),
              SizedBox(width: 4.w),
              Text(
                'تم تطبيق الخصم بنجاح لكود $_appliedVoucherCode (${_voucherDiscount.toStringAsFixed(2)} ${AppStrings.egp})',
                style: TextStyle(color: AppColors.success, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _validateVoucher() async {
    final code = _voucherCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingVoucher = true;
      _voucherError = null;
    });

    try {
      final validation = await Supabase.instance.client.rpc(
        'validate_voucher_by_code',
        params: {
          'p_code': code,
        },
      );

      if (validation is Map) {
        final map = Map<String, dynamic>.from(validation);
        final isValid = map['is_valid'] ?? map['valid'] ?? map['success'] ?? true;
        if (isValid == false) {
          final err = map['error'] ?? map['message'] ?? 'كود القسيمة غير صالح أو منتهي الصلاحية';
          setState(() {
            _voucherError = err.toString();
            _appliedVoucherCode = null;
            _voucherDiscount = 0.0;
          });
          return;
        }

        final discount = (map['discount_amount'] ?? map['discount_value'] ?? map['amount'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          _appliedVoucherCode = code;
          _voucherDiscount = discount;
          _voucherError = null;
        });
      } else {
        setState(() {
          _appliedVoucherCode = code;
          _voucherDiscount = 0.0;
          _voucherError = null;
        });
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _voucherError = cleanMsg;
        _appliedVoucherCode = null;
        _voucherDiscount = 0.0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isValidatingVoucher = false;
        });
      }
    }
  }

  Widget _buildSummaryCard(int durationMinutes) {
    final double durationHours = durationMinutes / 60.0;
    final double roomTotal = durationHours * (_selectedRoom?.pricePerHour ?? 0);
    final double grandTotal = (roomTotal + _extrasTotal - _voucherDiscount).clamp(0.0, double.infinity);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.neonBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body("${AppStrings.schedule}: $durationHours ${AppStrings.gaming}", color: AppColors.textSecondary),
              AppText.body("${AppStrings.pricePerHour}: ${_selectedRoom?.pricePerHour} ${AppStrings.egp}", color: AppColors.textSecondary),
              if (_extrasTotal > 0)
                AppText.body("مجموع الإضافات: ${_extrasTotal.toStringAsFixed(0)} ${AppStrings.egp}", color: AppColors.neonPurple),
              if (_voucherDiscount > 0)
                AppText.body("خصم القسيمة: -${_voucherDiscount.toStringAsFixed(2)} ${AppStrings.egp}", color: AppColors.success),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.body(AppStrings.totalPrice, fontWeight: FontWeight.bold),
              AppText.subHeading("${grandTotal.toStringAsFixed(2)} ${AppStrings.egp}", color: AppColors.neonBlue),
            ],
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (time != null) setState(() => _startTime = time);
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedRoom == null) return;

    final durationMinutes = context.read<BookingCubit>().state.selectedDurationMinutes;
    final endTime = _calculateEndTime(_startTime, durationMinutes);

    final startTimeStr = "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00";
    final endTimeStr = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00";

    // UI-level overlap check
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
      status: BookingStatus.upcoming,
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

  bool _checkTimeOverlap(String s1, String e1, String s2, String e2) {
    return s1.compareTo(e2) < 0 && e1.compareTo(s2) > 0;
  }
}
