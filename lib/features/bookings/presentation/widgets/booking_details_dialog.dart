import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'booking_details_action_panel.dart';
import 'booking_details_customer_card.dart';
import 'booking_details_financial_summary.dart';
import 'booking_receipt_card.dart';
import 'booking_specifications_card.dart';

class BookingDetailsDialog extends StatefulWidget {
  final Booking booking;
  final Function(double discountAmount, double discountPercentage, String? reason)?
      onConfirmPayment;
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
  final bool _isPercentage = false;

  @override
  void dispose() {
    _discountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double get _discountValue =>
      double.tryParse(_discountController.text) ?? 0.0;

  void _handleConfirmPayment(BuildContext context, Booking activeBooking) {
    final user = context.read<LoginCubit>().state.user;
    final isCashier = user?.isCashier == true;
    final discount = _discountValue;
    final percent = _isPercentage
        ? discount
        : (activeBooking.totalPrice > 0
            ? (discount / activeBooking.totalPrice * 100)
            : 0.0);

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

  Widget _getStatusBadge(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingVerification:
        return StatusBadge.warning(AppStrings.pendingVerification.toUpperCase());
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
      case BookingStatus.rejected:
        return StatusBadge.danger(AppStrings.requestRejected.toUpperCase());
    }
  }

  Widget _buildHeader(BuildContext context, Booking booking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withAlpha(25),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.confirmation_number_outlined,
                    color: AppColors.neonBlue),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: [
                        AppText.heading(AppStrings.bookingDetails,
                            fontSize: 18.sp),
                        _getStatusBadge(booking.status),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '#${booking.id}',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
          icon: const Icon(Icons.close_rounded,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth >= 850;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: isDesktopOrTablet ? 900.w : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.all(20.r),
        child: BlocBuilder<BookingCubit, BookingState>(
          builder: (context, state) {
            final activeBookingList =
                state.bookings.where((b) => b.id == widget.booking.id).toList();
            final currentBooking = activeBookingList.isNotEmpty
                ? activeBookingList.first
                : widget.booking;
            final isLoading = state.status == BookingStatusState.loading;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, currentBooking),
                SizedBox(height: 16.h),
                const Divider(color: AppColors.borderDefault, height: 1),
                SizedBox(height: 16.h),
                Expanded(
                  child: isDesktopOrTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    BookingDetailsCustomerCard(
                                        booking: currentBooking),
                                    SizedBox(height: 12.h),
                                    BookingSpecificationsCard(
                                        booking: currentBooking),
                                    SizedBox(height: 12.h),
                                    BookingReceiptCard(
                                        booking: currentBooking),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: BookingDetailsFinancialSummary(
                                          booking: currentBooking),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  BookingDetailsActionPanel(
                                    booking: currentBooking,
                                    isLoading: isLoading,
                                    onConfirmCashPayment: () =>
                                        _handleConfirmPayment(
                                            context, currentBooking),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              BookingDetailsCustomerCard(
                                  booking: currentBooking),
                              SizedBox(height: 12.h),
                              BookingSpecificationsCard(
                                  booking: currentBooking),
                              SizedBox(height: 12.h),
                              BookingDetailsFinancialSummary(
                                  booking: currentBooking),
                              SizedBox(height: 12.h),
                              BookingReceiptCard(booking: currentBooking),
                              SizedBox(height: 16.h),
                              BookingDetailsActionPanel(
                                booking: currentBooking,
                                isLoading: isLoading,
                                onConfirmCashPayment: () =>
                                    _handleConfirmPayment(
                                        context, currentBooking),
                              ),
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
}