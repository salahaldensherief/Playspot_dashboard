import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card_actions.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card_customer_row.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card_financial_row.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card_header.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card_schedule_box.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_countdown_timer.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_products_preview.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_session_progress.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_discount_dialog.dart';

import '../../../auth/presentation/login/login_cubit.dart';

/// Booking card (redesigned & decomposed).
class BookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onConfirmPayment;
  final VoidCallback? onStartSession;
  final VoidCallback? onNoShow;
  final double? width;

  const BookingCard({
    super.key,
    required this.booking,
    this.onApprove,
    this.onReject,
    this.onConfirmPayment,
    this.onStartSession,
    this.onNoShow,
    this.width,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _isHovered = false;

  void _openDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => BookingDetailsDialog(
        booking: widget.booking,
        onConfirmPayment: (amount, percent, reason) {
          context.read<BookingCubit>().confirmCashPayment(
                widget.booking.id,
                discountAmount: amount,
                discountPercentage: percent,
                discountReason: reason,
              );
        },
        onCancel: () => context.read<BookingCubit>().rejectBooking(widget.booking.id),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => RoomDiscountDialog(
        roomName: widget.booking.roomName.isNotEmpty ? widget.booking.roomName : AppStrings.roomLabel,
        currentPrice: widget.booking.totalPrice,
        onApplyDiscount: (amount, percent, reason) {
          context.read<BookingCubit>().confirmCashPayment(
                widget.booking.id,
                discountAmount: amount,
                discountPercentage: percent,
                discountReason: reason,
              );
        },
      ),
    );
  }

  bool _isPastStartTime(Booking booking) {
    if (booking.status != BookingStatus.pending && booking.status != BookingStatus.upcoming) {
      return false;
    }
    try {
      final date = booking.date;
      final parts = booking.startTime.trim().split(':');
      if (parts.length < 2) return false;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final scheduledStart = DateTime(date.year, date.month, date.day, hour, minute);
      final now = DateTime.now();
      return now.isAfter(scheduledStart) || now.isAtSameMomentAs(scheduledStart);
    } catch (_) {
      return false;
    }
  }

  Color _accentColor({
    required bool isOverdue,
    required bool isPending,
    required bool isInProgress,
  }) {
    if (isOverdue) return AppColors.danger;
    if (isPending) return AppColors.warning;
    if (isInProgress) return AppColors.success;
    return AppColors.neonBlue;
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    final bool isCashUnconfirmed = booking.isCashPayment && booking.paymentStatus != PaymentStatus.paid;
    final isPending = booking.status == BookingStatus.pending || isCashUnconfirmed;
    final isPaid = booking.paymentStatus == PaymentStatus.paid;
    final isCanStartSession = isPending || booking.status == BookingStatus.upcoming;
    final isOverdue = _isPastStartTime(booking);
    final isInProgress = booking.status == BookingStatus.inProgress;

    final graceMinutes = context.select(
      (LoginCubit c) => c.state.userLounge?.cashGracePeriodMinutes ?? 15,
    );

    final accent = _accentColor(
      isOverdue: isOverdue,
      isPending: isPending,
      isInProgress: isInProgress,
    );
    final bool hasAlertState = isOverdue || isPending || isInProgress;

    final Color borderColor = _isHovered
        ? accent.withValues(alpha: 0.9)
        : (hasAlertState ? accent.withValues(alpha: 0.55) : AppColors.borderDefault);

    final String shortId = booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id;

    return MouseRegion(
      onEnter: (_) {
        if (mounted && !_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (mounted && _isHovered) {
          setState(() => _isHovered = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: widget.width ?? 320.w,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: _isHovered || isOverdue ? 1.5 : 1.0),
          boxShadow: [
            BoxShadow(
              color: hasAlertState || _isHovered
                  ? accent.withValues(alpha: _isHovered ? 0.18 : 0.10)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: _isHovered ? 14 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openDetailsDialog(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1) Header: status + payment method + short id
                  BookingCardHeader(
                    booking: booking,
                    accent: accent,
                    shortId: shortId,
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2) Customer
                        BookingCardCustomerRow(booking: booking),
                        SizedBox(height: 12.h),

                        // 3) When + where
                        BookingCardScheduleBox(
                          booking: booking,
                          accent: accent,
                          isOverdue: isOverdue,
                        ),

                        // 4) Live state
                        if (booking.isCashPayment && isCanStartSession && !isInProgress) ...[
                          SizedBox(height: 8.h),
                          BookingCountdownTimer(
                            booking: booking,
                            gracePeriodMinutes: graceMinutes,
                          ),
                        ],
                        if (isInProgress) ...[
                          SizedBox(height: 8.h),
                          BookingSessionProgress(booking: booking),
                        ],

                        // 5) Canteen & extras
                        BookingProductsPreview(booking: booking),

                        SizedBox(height: 12.h),
                        Container(height: 1, color: AppColors.borderDefault.withValues(alpha: 0.6)),
                        SizedBox(height: 10.h),

                        // 6) Money
                        BookingCardFinancialRow(
                          booking: booking,
                          isPaid: isPaid,
                          onShowDiscount: () => _showDiscountDialog(context),
                        ),
                        SizedBox(height: 12.h),

                        // 7) Actions
                        BookingCardActions(
                          booking: booking,
                          isPaid: isPaid,
                          isPending: isPending,
                          isCanStartSession: isCanStartSession,
                          onOpenDetails: () => _openDetailsDialog(context),
                          onStartSession: widget.onStartSession,
                          onConfirmPayment: widget.onConfirmPayment,
                          onReject: widget.onReject,
                          onNoShow: widget.onNoShow,
                        ),
                      ],
                    ),
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
