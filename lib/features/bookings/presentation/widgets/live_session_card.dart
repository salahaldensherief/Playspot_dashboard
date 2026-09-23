import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card_customer_row.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card_financial_row.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_products_preview.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_session_card_actions.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_session_card_header.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_session_requests_badge.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_session_timer_box.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_discount_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_ticker.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/station_control_drawer.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/swap_room_dialog.dart';

/// Interactive UI Card Widget for live active gaming sessions.
/// Listens to global SessionTickerScope without running individual timers.
class LiveSessionCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onEndSession;
  final VoidCallback? onExtendSession;
  final Function(int additionalMinutes)? onExtendMinutes;
  final double? width;

  const LiveSessionCard({
    super.key,
    required this.booking,
    this.onEndSession,
    this.onExtendSession,
    this.onExtendMinutes,
    this.width,
  });

  @override
  State<LiveSessionCard> createState() => _LiveSessionCardState();
}

class _LiveSessionCardState extends State<LiveSessionCard> {
  bool _isHovered = false;

  void _openStationControl() {
    StationControlDrawer.show(
      context,
      booking: widget.booking,
      onEndSession: widget.onEndSession,
    );
  }

  void _showSwapRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => SwapRoomDialog(
        bookingId: widget.booking.id,
        currentRoomId: widget.booking.roomId,
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

  Future<void> _handleExtendMinutes(int minutes) async {
    if (widget.onExtendMinutes != null) {
      widget.onExtendMinutes!(minutes);
      return;
    }

    final dashboardCubit = context.read<DashboardCubit>();
    final success = await dashboardCubit.extendSession(widget.booking.id, minutes);
    if (!mounted) return;

    if (success) {
      context.read<BookingCubit>().startWatchingBookings(loungeId: widget.booking.loungeId, forceRefresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.timeExtendedSuccess),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final errorMsg = dashboardCubit.state.errorMessage ?? AppStrings.extendFallbackError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = SessionTickerScope.nowOf(context);
    final booking = widget.booking;
    final remaining = booking.remainingDuration(now);
    final isExpired = booking.isSessionExpired(now);

    final Color accent = isExpired
        ? AppColors.danger
        : (remaining.inMinutes <= 10 ? AppColors.warning : AppColors.neonBlue);

    final Color borderColor = _isHovered
        ? accent.withValues(alpha: 0.9)
        : (isExpired
            ? AppColors.danger.withValues(alpha: 0.7)
            : accent.withValues(alpha: 0.3));

    return MouseRegion(
      onEnter: (_) {
        if (mounted && !_isHovered) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted && _isHovered) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = false);
          });
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
          border: Border.all(color: borderColor, width: _isHovered || isExpired ? 1.5 : 1.0),
          boxShadow: [
            BoxShadow(
              color: isExpired
                  ? AppColors.danger.withValues(alpha: _isHovered ? 0.22 : 0.12)
                  : accent.withValues(alpha: _isHovered ? 0.18 : 0.08),
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
              onTap: _openStationControl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LiveSessionCardHeader(
                    booking: booking,
                    accent: accent,
                    onSwapRoom: () => _showSwapRoomDialog(context),
                    onOpenStationControl: _openStationControl,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookingCardCustomerRow(booking: booking),
                        SizedBox(height: 12.h),
                        LiveSessionTimerBox(
                          booking: booking,
                          accent: accent,
                          isExpired: isExpired,
                          remaining: remaining,
                          onOpenStationControl: _openStationControl,
                          onExtendMinutes: _handleExtendMinutes,
                        ),
                        LiveSessionRequestsBadge(booking: booking),
                        BookingProductsPreview(booking: booking),
                        SizedBox(height: 12.h),
                        Container(height: 1, color: AppColors.borderDefault.withValues(alpha: 0.6)),
                        SizedBox(height: 10.h),
                        BookingCardFinancialRow(
                          booking: booking,
                          isPaid: booking.paymentStatus == PaymentStatus.paid,
                          onShowDiscount: () => _showDiscountDialog(context),
                        ),
                        SizedBox(height: 12.h),
                        LiveSessionCardActions(
                          booking: booking,
                          onEndSession: widget.onEndSession,
                          onExtendSession: widget.onExtendSession,
                          onExtendMinutes: widget.onExtendMinutes,
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
