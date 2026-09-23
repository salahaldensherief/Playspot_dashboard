import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_products_preview.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/station_control_actions_bar.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/station_control_countdown_gauge.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/station_control_gamer_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/station_control_header.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/station_control_requests_section.dart';

/// Slide-over Station Control Drawer for interactive real-time station management.
class StationControlDrawer extends StatelessWidget {
  final Booking booking;
  final VoidCallback onClose;
  final VoidCallback? onEndSession;

  const StationControlDrawer({
    super.key,
    required this.booking,
    required this.onClose,
    this.onEndSession,
  });

  static void show(
    BuildContext context, {
    required Booking booking,
    VoidCallback? onEndSession,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StationControlDrawer',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 420.w,
              height: double.infinity,
              child: StationControlDrawer(
                booking: booking,
                onClose: () => Navigator.of(context).pop(),
                onEndSession: () {
                  Navigator.of(context).pop();
                  if (onEndSession != null) {
                    onEndSession();
                  }
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  double _calculateExtrasTotal() {
    double total = 0.0;
    for (final extra in booking.extras) {
      final price = (extra['price'] ?? extra['total_price'] ?? extra['unit_price'] as num?)?.toDouble() ?? 0.0;
      final qty = (extra['quantity'] ?? extra['qty'] ?? extra['count'] as num?)?.toInt() ?? 1;
      total += (price * qty);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = booking.remainingDuration();
    final isExpired = booking.isSessionExpired();
    final extrasTotal = _calculateExtrasTotal();
    final totalBalance = booking.totalPrice + extrasTotal;

    final Color accent = isExpired
        ? AppColors.danger
        : (remaining.inMinutes <= 5 && !booking.isOpenEnded ? AppColors.warning : AppColors.success);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: const Border(
          left: BorderSide(color: AppColors.borderDefault, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          StationControlHeader(
            booking: booking,
            accent: accent,
            onClose: onClose,
          ),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(18.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gamer Profile Card
                  StationControlGamerCard(booking: booking),
                  SizedBox(height: 16.h),

                  // Session Requests Section (Targeted BlocBuilder)
                  StationControlRequestsSection(booking: booking),

                  // Countdown Gauge Widget
                  StationControlCountdownGauge(
                    booking: booking,
                    remaining: remaining,
                    isExpired: isExpired,
                    accent: accent,
                  ),
                  SizedBox(height: 18.h),

                  // Quick Time Extension & Action Bar
                  StationControlActionsBar(booking: booking),
                  SizedBox(height: 16.h),

                  // Canteen & Extras Preview
                  BookingProductsPreview(booking: booking),
                  SizedBox(height: 16.h),

                  // Itemized Balance Breakdown Card
                  _buildBalanceBreakdown(extrasTotal, totalBalance),
                ],
              ),
            ),
          ),

          // Sticky Footer Checkout Button
          _buildFooter(context, totalBalance),
        ],
      ),
    );
  }

  Widget _buildBalanceBreakdown(double extrasTotal, double totalBalance) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.basePrice,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
              ),
              Text(
                '${booking.totalPrice.toStringAsFixed(2)} ${AppStrings.egp}',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.extrasTotal,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
              ),
              Text(
                '${extrasTotal.toStringAsFixed(2)} ${AppStrings.egp}',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: AppColors.borderDefault, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalPrice,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              Text(
                '${totalBalance.toStringAsFixed(2)} ${AppStrings.egp}',
                style: TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, double totalBalance) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: AppButton(
        onPressed: onEndSession ??
            () {
              context.read<DashboardCubit>().endSession(booking.id);
              onClose();
            },
        text: '${AppStrings.endSession} (${totalBalance.toStringAsFixed(2)} ${AppStrings.egp})',
        backgroundColor: AppColors.danger,
        height: 42.h,
      ),
    );
  }
}
