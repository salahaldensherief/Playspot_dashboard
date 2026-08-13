import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
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
  TimeOfDay _endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.scaffoldBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 500.w,
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
                children: [
                  Expanded(
                    child: _buildPickerField(
                      label: AppStrings.date,
                      value: DateFormat('yyyy-MM-dd').format(_selectedDate),
                      icon: Icons.calendar_today,
                      onTap: _pickDate,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildPickerField(
                      label: AppStrings.opensAt,
                      value: _startTime.format(context),
                      icon: Icons.access_time,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildPickerField(
                      label: AppStrings.closesAt,
                      value: _endTime.format(context),
                      icon: Icons.access_time,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Price Calculation Summary
              if (_selectedRoom != null) _buildSummaryCard(),

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
                AppText.body(value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final double duration = _calculateDuration();
    final double totalPrice = duration * (_selectedRoom?.pricePerHour ?? 0);

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
              AppText.body("${AppStrings.schedule}: $duration ${AppStrings.gaming}", color: AppColors.textSecondary),
              AppText.body("${AppStrings.pricePerHour}: ${_selectedRoom?.pricePerHour} ${AppStrings.egp}", color: AppColors.textSecondary),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.body(AppStrings.totalPrice, fontWeight: FontWeight.bold),
              AppText.subHeading("${totalPrice.toStringAsFixed(0)} ${AppStrings.egp}", color: AppColors.neonBlue),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateDuration() {
    double start = _startTime.hour + (_startTime.minute / 60);
    double end = _endTime.hour + (_endTime.minute / 60);
    if (end <= start) end += 24;
    return end - start;
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

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (time != null) setState(() => isStart ? _startTime = time : _endTime = time);
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedRoom == null) return;

    final startTimeStr = "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00";
    final endTimeStr = "${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00";

    // UI-level overlap check (for better UX)
    final bookingCubit = context.read<BookingCubit>();
    final isOverlapping = bookingCubit.state.bookings.any((b) {
      if (b.roomId != _selectedRoom!.id || b.status == BookingStatus.cancelled) return false;
      
      // Basic time comparison (simplified for the same day)
      // For cross-day logic, we'd need more robust parsing, but the DB will catch it anyway.
      return b.date.year == _selectedDate.year && 
             b.date.month == _selectedDate.month && 
             b.date.day == _selectedDate.day &&
             _checkTimeOverlap(b.startTime, b.endTime, startTimeStr, endTimeStr);
    });

    if (isOverlapping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("هذه الغرفة محجوزة بالفعل في الوقت المختار"), backgroundColor: AppColors.danger),
      );
      return;
    }

    final booking = Booking(
      id: '', // Will be generated by DB
      userId: '', 
      userName: _nameController.text,
      userPhone: _phoneController.text,
      loungeId: widget.loungeId,
      roomId: _selectedRoom!.id,
      roomName: _selectedRoom!.nameEn,
      date: _selectedDate,
      startTime: startTimeStr,
      endTime: endTimeStr,
      status: BookingStatus.upcoming,
      totalPrice: _calculateDuration() * _selectedRoom!.pricePerHour,
    );

    context.read<BookingCubit>().createManualBooking(booking);
    Navigator.pop(context);
  }

  bool _checkTimeOverlap(String s1, String e1, String s2, String e2) {
    return s1.compareTo(e2) < 0 && e1.compareTo(s2) > 0;
  }
}
