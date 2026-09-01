import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/swap_room_dialog.dart';
import '../../domain/entities/booking.dart';

class BookingDetailsDialog extends StatefulWidget {
  final Booking booking;
  final Function(double discountAmount, double discountPercentage, String? reason) onConfirmPayment;
  final VoidCallback onCancel;

  const BookingDetailsDialog({
    super.key,
    required this.booking,
    required this.onConfirmPayment,
    required this.onCancel,
  });

  @override
  State<BookingDetailsDialog> createState() => _BookingDetailsDialogState();
}

class _BookingDetailsDialogState extends State<BookingDetailsDialog> {
  final _discountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isPercentage = false;

  @override
  void dispose() {
    _discountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double get _discountValue => double.tryParse(_discountController.text) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 700.w,
        padding: EdgeInsets.all(32.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 24.h),
              _buildInfoGrid(),
              if (widget.booking.extras.isNotEmpty) ...[
                SizedBox(height: 24.h),
                _buildExtrasSection(),
              ],
              if (widget.booking.paymentStatus != PaymentStatus.paid) ...[
                SizedBox(height: 24.h),
                _buildDiscountSection(),
              ],
              SizedBox(height: 32.h),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.heading(AppStrings.bookingDetails, fontSize: 24.sp),
            SizedBox(height: 4.h),
            AppText.body('ID: ${widget.booking.id}', fontSize: 12.sp),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      children: [
        _buildInfoItem(AppStrings.customerName, widget.booking.userName ?? AppStrings.anonymous),
        _buildInfoItem(AppStrings.phoneNumber, widget.booking.userPhone ?? '-'),
        _buildInfoItem(AppStrings.roomLabel, widget.booking.roomName),
        _buildInfoItem(AppStrings.schedule, '${widget.booking.startTime} - ${widget.booking.endTime}'),
        _buildInfoItem(AppStrings.date, DateFormat('MMM dd, yyyy').format(widget.booking.date)),
        _buildInfoItem(AppStrings.totalPrice, '${widget.booking.totalPrice.toStringAsFixed(2)} ${AppStrings.egp}', valueColor: AppColors.neonBlue),
        _buildInfoItem(AppStrings.payment, widget.booking.paymentStatus == PaymentStatus.paid ? AppStrings.paid : AppStrings.unpaid),
        _buildInfoItem(AppStrings.status, '', customWidget: _getStatusBadge(widget.booking.status)),
      ],
    );
  }

  Widget _buildExtrasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fastfood_outlined, color: AppColors.neonBlue, size: 20),
            SizedBox(width: 8.w),
            AppText.subHeading(AppStrings.additionalItems, fontSize: 18.sp),
          ],
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: widget.booking.extras.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.body('${item['quantity']}x ${item['name_en'] ?? item['name']}', color: AppColors.textPrimary),
                  AppText.body('${item['price'] ?? 0} ${AppStrings.egp}', color: AppColors.textSecondary),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(AppStrings.discount, fontSize: 18.sp),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                label: AppStrings.discount,
                controller: _discountController,
                keyboardType: TextInputType.number,
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isPercentage = false),
                      child: Text('EGP', style: TextStyle(color: !_isPercentage ? AppColors.neonBlue : Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isPercentage = true),
                      child: Text('%', style: TextStyle(color: _isPercentage ? AppColors.neonBlue : Colors.white)),
                    ),
                  ],
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              flex: 3,
              child: AppTextField(
                label: AppStrings.discountReason,
                controller: _reasonController,
                hintText: 'Enter reason for audit...',
                validator: (val) => (_discountValue > 0 && (val == null || val.isEmpty)) ? AppStrings.reasonRequired : null,
              ),
            ),
          ],
        ),
        if (_discountValue > 0) ...[
          SizedBox(height: 12.h),
          AppText.body(
            'Final Price: ${(widget.booking.totalPrice - (_isPercentage ? (widget.booking.totalPrice * _discountValue / 100) : _discountValue)).toStringAsFixed(2)} ${AppStrings.egp}',
            color: AppColors.success,
            fontWeight: FontWeight.bold,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor, Widget? customWidget}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontSize: 12.sp),
        SizedBox(height: 4.h),
        customWidget ?? AppText.subHeading(
          value,
          fontSize: 16.sp,
          color: valueColor,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final bool isSessionActive = widget.booking.status == BookingStatus.inProgress || widget.booking.status == BookingStatus.upcoming;
    final user = context.read<LoginCubit>().state.user;
    final bool isCashier = user?.isCashier == true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isSessionActive)
          AppButton(
            text: AppStrings.swapRoom,
            variant: AppButtonVariant.outlined,
            onPressed: () {
              showDialog(
                context: context,
                useRootNavigator: false,
                builder: (_) => SwapRoomDialog(
                  bookingId: widget.booking.id,
                  currentRoomId: widget.booking.roomId,
                ),
              );
            },
          ),
        SizedBox(width: 16.w),
        AppButton(
          text: AppStrings.cancelBooking,
          variant: AppButtonVariant.outlined,
          onPressed: () {
            widget.onCancel();
            Navigator.pop(context);
          },
        ),
        SizedBox(width: 16.w),
        if (widget.booking.paymentStatus != PaymentStatus.paid)
          AppButton(
            text: AppStrings.confirmCash,
            onPressed: () {
              final discount = _discountValue;
              final percent = _isPercentage ? discount : (discount / widget.booking.totalPrice * 100);
              
              if (isCashier && percent > 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.managerOverrideRequired), backgroundColor: AppColors.danger),
                );
                return;
              }

              if (discount > 0 && _reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(AppStrings.reasonRequired), backgroundColor: AppColors.danger),
                );
                return;
              }

              widget.onConfirmPayment(
                _isPercentage ? (widget.booking.totalPrice * discount / 100) : discount,
                percent,
                _reasonController.text.trim(),
              );
              Navigator.pop(context);
            },
          ),
      ],
    );
  }

  Widget _getStatusBadge(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return StatusBadge.warning(AppStrings.pending.toUpperCase());
      case BookingStatus.upcoming: return StatusBadge.info(AppStrings.upcoming.toUpperCase());
      case BookingStatus.completed: return StatusBadge.success(AppStrings.completed.toUpperCase());
      case BookingStatus.cancelled: return StatusBadge.danger(AppStrings.cancelled.toUpperCase());
      default: return StatusBadge.info(status.name.toUpperCase());
    }
  }
}
