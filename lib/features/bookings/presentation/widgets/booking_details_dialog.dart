import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'booking_receipt_card.dart';
import 'swap_room_dialog.dart';

class BookingDetailsDialog extends StatefulWidget {
  final Booking booking;
  final Function(double discountAmount, double discountPercentage, String? reason)? onConfirmPayment;
  final VoidCallback? onCancel;

  const BookingDetailsDialog({
    super.key,
    required this.booking,
    this.onConfirmPayment,
    this.onCancel,
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

  void _handleConfirmPayment(BuildContext context, Booking activeBooking) {
    final user = context.read<LoginCubit>().state.user;
    final isCashier = user?.isCashier == true;
    final discount = _discountValue;
    final percent = _isPercentage
        ? discount
        : (activeBooking.totalPrice > 0 ? (discount / activeBooking.totalPrice * 100) : 0.0);

    if (isCashier && percent > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.managerOverrideRequired),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (discount > 0 && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.reasonRequired),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final calculatedDiscountAmount = _isPercentage
        ? (activeBooking.totalPrice * discount / 100)
        : discount;

    if (widget.onConfirmPayment != null) {
      widget.onConfirmPayment!(
        calculatedDiscountAmount,
        percent,
        _reasonController.text.trim(),
      );
    } else {
      context.read<BookingCubit>().confirmCashPayment(
        activeBooking.id,
        discountAmount: calculatedDiscountAmount,
        discountPercentage: percent,
        discountReason: _reasonController.text.trim(),
      );
    }
    Navigator.of(context, rootNavigator: false).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth >= 850;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: isDesktopOrTablet ? 900.w : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.all(20.r),
        child: BlocBuilder<BookingCubit, BookingState>(
          builder: (context, state) {
            final activeBookingList = state.bookings.where((b) => b.id == widget.booking.id).toList();
            final currentBooking = activeBookingList.isNotEmpty ? activeBookingList.first : widget.booking;
            final isLoading = state.status == BookingStatusState.loading;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Bar
                _buildHeader(context, currentBooking),
                SizedBox(height: 16.h),
                const Divider(color: AppColors.borderDefault, height: 1),
                SizedBox(height: 16.h),

                // 2. Main Content (Responsive: Split on Desktop, Column on Mobile)
                Expanded(
                  child: isDesktopOrTablet
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Section (60%): Booking Details & Specifications
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildCustomerCard(currentBooking),
                              SizedBox(height: 12.h),
                              _buildBookingSpecCard(currentBooking),
                              SizedBox(height: 12.h),
                              BookingReceiptCard(booking: currentBooking),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // Right Section (40%): Financials & Sticky Actions
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildFinancialSummary(currentBooking),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _buildActionPanel(context, currentBooking, isLoading),
                          ],
                        ),
                      ),
                    ],
                  )
                      : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCustomerCard(currentBooking),
                        SizedBox(height: 12.h),
                        _buildBookingSpecCard(currentBooking),
                        SizedBox(height: 12.h),
                        _buildFinancialSummary(currentBooking),
                        SizedBox(height: 12.h),
                        BookingReceiptCard(booking: currentBooking),
                        SizedBox(height: 16.h),
                        _buildActionPanel(context, currentBooking, isLoading),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Booking booking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withAlpha(25),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: const Icon(Icons.confirmation_number_outlined, color: AppColors.neonBlue),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppText.heading(AppStrings.bookingDetails, fontSize: 18.sp),
                    SizedBox(width: 8.w),
                    _getStatusBadge(booking.status),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  '#${booking.id}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(Booking booking) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: AppColors.neonBlue.withAlpha(30),
            child: Text(
              (booking.userName ?? 'C').substring(0, 1).toUpperCase(),
              style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.userName ?? AppStrings.anonymous,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Text(
                  booking.userPhone ?? 'لا يوجد هاتف',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_pin_circle_outlined, size: 14.r, color: AppColors.neonPurple),
                SizedBox(width: 4.w),
                Text(
                  'عميل مسجل',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSpecCard(Booking booking) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 16.r, color: AppColors.neonBlue),
                  SizedBox(width: 6.w),
                  AppText.subHeading(booking.roomName, fontSize: 14.sp),
                ],
              ),
              Text(
                '${booking.startTime} - ${booking.endTime}',
                style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w600, fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _buildBadgeItem(Icons.group_outlined, 'الضيوف: 1'),
              _buildBadgeItem(Icons.sports_esports_outlined, booking.loungeName.isNotEmpty ? booking.loungeName : 'الفرع الرئيسي'),
              if (booking.paymentMethod != null)
                _buildBadgeItem(Icons.payment_outlined, booking.paymentMethod!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: AppColors.textSecondary),
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(Booking booking) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.subHeading('ملخص الحساب والفاتورة', fontSize: 13.sp),
              StatusBadge(
                text: booking.paymentStatus == PaymentStatus.paid ? 'تم الدفع' : 'غير مدفوع',
                color: booking.paymentStatus == PaymentStatus.paid ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildBillRow('سعر الغرفة الأساسي', '${booking.roomPrice ?? booking.totalPrice} ${AppStrings.egp}'),
          _buildBillRow('الطلبات والمشروبات الإضافية', '0 ${AppStrings.egp}'),
          if (booking.discountAmount != null && booking.discountAmount! > 0)
            _buildBillRow('الخصم', '-${booking.discountAmount} ${AppStrings.egp}', color: AppColors.danger),
          const Divider(color: AppColors.borderDefault),
          _buildBillRow(
            'الإجمالي النهائي المطلوب',
            '${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
            isTotal: true,
            color: AppColors.neonGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 13.sp : 12.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 15.sp : 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(BuildContext context, Booking booking, bool isLoading) {
    final cubit = context.read<BookingCubit>();
    final isPending = booking.status == BookingStatus.pending;
    final isInProgress = booking.status == BookingStatus.inProgress;
    final isUpcoming = booking.status == BookingStatus.upcoming;
    final isUnpaid = booking.paymentStatus != PaymentStatus.paid;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(color: AppColors.neonBlue),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary Call To Action (Action based on state)
        if (isPending)
          AppButton(
            text: 'قبول الحجز الآن',
            variant: AppButtonVariant.primary,
            backgroundColor: AppColors.success,
            height: 40.h,
            onPressed: () => cubit.approveBooking(booking.id),
          ),
        if (isUpcoming || isInProgress)
          AppButton(
            text: isInProgress ? 'إنهاء وحساب الجلسة' : 'بدء الجلسة الآن',
            variant: AppButtonVariant.primary,
            height: 40.h,
            onPressed: () {
              if (isInProgress) {
                cubit.changeBookingStatus(booking.id, BookingStatus.completed);
              }
            },
          ),
        if (isUnpaid && !isPending) ...[
          SizedBox(height: 8.h),
          AppButton(
            text: AppStrings.confirmCash,
            variant: AppButtonVariant.primary,
            backgroundColor: AppColors.neonBlue,
            height: 40.h,
            onPressed: () => _handleConfirmPayment(context, booking),
          ),
        ],
        SizedBox(height: 8.h),
        // Secondary Actions (Room swap & Cancel)
        Row(
          children: [
            if (isInProgress || isUpcoming)
              Expanded(
                child: AppButton(
                  text: AppStrings.swapRoom,
                  variant: AppButtonVariant.outlined,
                  height: 36.h,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SwapRoomDialog(
                        bookingId: booking.id,
                        currentRoomId: booking.roomId,
                      ),
                    );
                  },
                ),
              ),
            if (isInProgress || isUpcoming) SizedBox(width: 8.w),
            if (booking.status != BookingStatus.cancelled && booking.status != BookingStatus.completed)
              Expanded(
                child: AppButton(
                  text: AppStrings.cancelBooking,
                  variant: AppButtonVariant.danger,
                  height: 36.h,
                  onPressed: () {
                    cubit.rejectBooking(booking.id);
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _getStatusBadge(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return StatusBadge.warning(AppStrings.pending.toUpperCase());
      case BookingStatus.upcoming:
        return StatusBadge.info(AppStrings.upcoming.toUpperCase());
      case BookingStatus.inProgress:
        return StatusBadge.success(AppStrings.inProgress.toUpperCase());
      case BookingStatus.completed:
        return StatusBadge.success(AppStrings.completed.toUpperCase());
      case BookingStatus.cancelled:
        return StatusBadge.danger(AppStrings.cancelled.toUpperCase());
    }
  }
}