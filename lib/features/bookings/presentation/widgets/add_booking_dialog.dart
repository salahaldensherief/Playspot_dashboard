import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

class AddBookingDialog extends StatefulWidget {
  final String loungeId;
  const AddBookingDialog({super.key, required this.loungeId});

  @override
  State<AddBookingDialog> createState() => _AddBookingDialogState();
}

class _AddBookingDialogState extends State<AddBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  RoomEntity? _selectedRoom;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    // Default duration is 60 mins
    context.read<BookingCubit>().updateSelectedDuration(60);
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

                SizedBox(height: 32.h),

                // Price Calculation Summary
                if (_selectedRoom != null) 
                  BlocBuilder<BookingCubit, BookingState>(
                    buildWhen: (p, c) => p.selectedDurationMinutes != c.selectedDurationMinutes,
                    builder: (context, state) {
                      return _buildSummaryCard(state.selectedDurationMinutes);
                    },
                  ),

                SizedBox(height: 32.h),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: AppText.body(AppStrings.cancel, color: AppColors.textSecondary),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonBlue,
                        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      child: AppText.body(AppStrings.newBooking, color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildSummaryCard(int durationMinutes) {
    final double durationHours = durationMinutes / 60.0;
    final double totalPrice = durationHours * (_selectedRoom?.pricePerHour ?? 0);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.neonBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.neonBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body("${AppStrings.schedule}: $durationHours ${AppStrings.gaming}", color: AppColors.textSecondary),
              AppText.body("${AppStrings.pricePerHour}: ${_selectedRoom?.pricePerHour} ${AppStrings.egp}", color: AppColors.textSecondary),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.body(AppStrings.totalPrice, fontWeight: FontWeight.bold),
              AppText.subHeading("${totalPrice.toStringAsFixed(2)} ${AppStrings.egp}", color: AppColors.neonBlue),
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
      totalPrice: (durationMinutes / 60.0) * selectedRoom.pricePerHour,
      shiftId: activeShiftId,
    );

    context.read<BookingCubit>().createManualBooking(booking);
    Navigator.pop(context);
  }

  bool _checkTimeOverlap(String s1, String e1, String s2, String e2) {
    return s1.compareTo(e2) < 0 && e1.compareTo(s2) > 0;
  }
}
