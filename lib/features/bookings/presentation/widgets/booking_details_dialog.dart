import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/swap_room_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_financials_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_specifications_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_status_actions.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_user_info_card.dart';

/// Comprehensive Booking Details Dialog displaying:
/// 1. User & Contact Info (Name, email, phone, avatar)
/// 2. Booking Specifications (Lounge, room, specs, guests, schedule)
/// 3. Financials & Extras (Base price, detailed extra items, discounts, total, payment status)
/// 4. Status Control Actions (Approve, cancel, complete, confirm payment, swap room)
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
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 720.w,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.all(24.r),
        child: BlocConsumer<BookingCubit, BookingState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == BookingStatusState.failure && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
          buildWhen: (previous, current) =>
              previous.status != current.status || previous.bookings != current.bookings,
          builder: (context, state) {
            final activeBookingList = state.bookings.where((b) => b.id == widget.booking.id).toList();
            final currentBooking = activeBookingList.isNotEmpty ? activeBookingList.first : widget.booking;
            final isLoading = state.status == BookingStatusState.loading;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, currentBooking),
                SizedBox(height: 20.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. User & Contact Info Card
                        BookingUserInfoCard(booking: currentBooking),
                        SizedBox(height: 16.h),

                        // 2. Booking Specifications Card
                        BookingSpecificationsCard(booking: currentBooking),
                        SizedBox(height: 16.h),

                        // 3. Financials & Extras Card
                        BookingFinancialsCard(
                          booking: currentBooking,
                          discountController: _discountController,
                          reasonController: _reasonController,
                          isPercentage: _isPercentage,
                          onTogglePercentage: (val) => setState(() => _isPercentage = val),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // 4. Status Control Actions
                BookingStatusActions(
                  booking: currentBooking,
                  isLoading: isLoading,
                  onApprove: () => context.read<BookingCubit>().approveBooking(currentBooking.id),
                  onCancel: () {
                    if (widget.onCancel != null) {
                      widget.onCancel!();
                    } else {
                      context.read<BookingCubit>().rejectBooking(currentBooking.id);
                    }
                    Navigator.of(context, rootNavigator: false).pop();
                  },
                  onComplete: () => context.read<BookingCubit>().changeBookingStatus(
                        currentBooking.id,
                        BookingStatus.completed,
                      ),
                  onConfirmPayment: () => _handleConfirmPayment(context, currentBooking),
                  onSwapRoom: () {
                    showDialog(
                      context: context,
                      useRootNavigator: false,
                      builder: (_) => SwapRoomDialog(
                        bookingId: currentBooking.id,
                        currentRoomId: currentBooking.roomId,
                      ),
                    );
                  },
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
            AppText.heading(AppStrings.bookingDetails, fontSize: 20.sp),
            SizedBox(width: 12.w),
            _getStatusBadge(booking.status),
          ],
        ),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: AppText.body(
                'ID: ${booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id}',
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(width: 12.w),
            IconButton(
              onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
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
