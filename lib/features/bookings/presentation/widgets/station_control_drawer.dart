import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import '../../domain/entities/booking.dart';
import '../../../analytics/presentation/dashboard_cubit.dart';
import 'radial_countdown_ring.dart';
import 'add_extras_dialog.dart';
import 'swap_room_dialog.dart';
import 'customer_visit_badge.dart';
import 'booking_products_preview.dart';

/// Slide-over Station Control Drawer for interactive real-time station management.
/// Redesigned to match the stunning design language of BookingCard and LiveSessionCard.
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

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}'.toUpperCase() + '${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
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
          _buildHeader(context, isExpired, accent),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(18.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gamer Profile Card
                  _buildGamerInfoCard(context),
                  SizedBox(height: 16.h),

                  // Session Requests Section
                  _buildSessionRequestsSection(context),

                  // Countdown Gauge Widget
                  _buildCountdownGauge(remaining, isExpired, accent),
                  SizedBox(height: 18.h),

                  // Quick Time Extension Bar (+15m, +30m, +1h)
                  _buildQuickExtensionsBar(context),
                  SizedBox(height: 16.h),

                  // Quick Actions Bar (Extras & Swap)
                  _buildQuickActions(context),
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

  Widget _buildHeader(BuildContext context, bool isExpired, Color accent) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        border: const Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
                  color: accent,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        booking.roomName.isNotEmpty ? booking.roomName : AppStrings.roomLabel,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      StatusBadge.success(AppStrings.inProgress.toUpperCase()),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    booking.playMode ?? "فردي",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildGamerInfoCard(BuildContext context) {
    final userName = (booking.userName != null && booking.userName!.isNotEmpty)
        ? booking.userName!
        : AppStrings.anonymous;
    final userPhone = booking.userPhone?.trim() ?? '';
    final userEmail = booking.userEmail?.trim() ?? '';
    final bookingIdShort = booking.id.isNotEmpty
        ? (booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id)
        : 'زائر';

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.neonBlue.withValues(alpha: 0.75),
                  AppColors.neonPurple.withValues(alpha: 0.75),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(userName),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    CustomerVisitBadge(visitNumber: booking.visitNumber),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    if (userPhone.isNotEmpty && userPhone != 'null' && userPhone != 'No Phone') ...[
                      Icon(Icons.phone_outlined, size: 12.sp, color: AppColors.neonBlue),
                      SizedBox(width: 4.w),
                      Text(
                        userPhone,
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.phoneCopied),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: Icon(Icons.copy_rounded, size: 12.sp, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRequestsSection(BuildContext context) {
    final clientRequestsCubit = context.watch<ClientRequestsCubit?>();
    if (clientRequestsCubit == null) return const SizedBox.shrink();

    final requestsState = clientRequestsCubit.state;
    final sessionRequests = requestsState.requests.where((r) {
      if (r.isAttended) return false;
      final matchBooking = r.bookingId != null && r.bookingId == booking.id;
      final matchRoom = r.roomId != null && r.roomId == booking.roomId;
      return matchBooking || matchRoom;
    }).toList();

    if (sessionRequests.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 16.r),
              SizedBox(width: 6.w),
              Text(
                '${AppStrings.sessionRequests} (${sessionRequests.length})',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...sessionRequests.map((req) {
            final title = req.titleAr.isNotEmpty ? req.titleAr : req.titleEn;
            final body = req.bodyAr.isNotEmpty ? req.bodyAr : req.bodyEn;
            return Container(
              margin: EdgeInsets.only(bottom: 6.h),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (body.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            body,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ClientRequestsCubit>().markAsAttended(
                            req.id,
                            isCanteenOrder: req.isCanteenOrder,
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                    ),
                    child: Text(
                      AppStrings.done,
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCountdownGauge(Duration remaining, bool isExpired, Color accent) {
    final totalDuration = Duration(minutes: booking.durationMinutes);
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          RadialCountdownRing(
            totalDuration: totalDuration,
            remainingDuration: remaining,
            isExpired: isExpired,
            isOpenEnded: booking.isOpenEnded,
            size: 68.0,
            strokeWidth: 5.0,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? AppStrings.timeExpired : AppStrings.remainingTime,
                  style: TextStyle(
                    color: isExpired ? AppColors.danger : AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  booking.isOpenEnded ? 'الوقت مفتوح' : _formatDuration(remaining),
                  style: TextStyle(
                    color: isExpired ? AppColors.danger : AppColors.neonBlue,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppStrings.totalDuration('${booking.durationMinutes} دقيقة'),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.abs();
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    if (totalSeconds >= 3600) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildQuickExtensionsBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.extendTime,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(child: _buildExtensionButton(context, 15)),
            SizedBox(width: 8.w),
            Expanded(child: _buildExtensionButton(context, 30)),
            SizedBox(width: 8.w),
            Expanded(child: _buildExtensionButton(context, 60)),
          ],
        ),
      ],
    );
  }

  Widget _buildExtensionButton(BuildContext context, int minutes) {
    final label = '+$minutes دقيقة';
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () {
        context.read<DashboardCubit>().extendSession(booking.id, minutes);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.mutedBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.neonBlue,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddExtrasDialog(
                  bookingId: booking.id,
                  loungeId: booking.loungeId,
                  onConfirm: (extras, totalCost) {
                    context.read<DashboardCubit>().addExtrasToSession(
                          booking.id,
                          extras,
                          totalCost,
                        );
                  },
                ),
              );
            },
            icon: Icon(Icons.fastfood_rounded, size: 16.sp, color: AppColors.neonPurple),
            label: Text(
              AppStrings.addExtrasToSession,
              style: TextStyle(color: AppColors.neonPurple, fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.neonPurple.withValues(alpha: 0.4)),
              padding: EdgeInsets.symmetric(vertical: 11.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => SwapRoomDialog(
                  bookingId: booking.id,
                  currentRoomId: booking.roomId,
                ),
              );
            },
            icon: Icon(Icons.swap_horiz_rounded, size: 16.sp, color: AppColors.textPrimary),
            label: Text(
              AppStrings.swapRoom,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderDefault),
              padding: EdgeInsets.symmetric(vertical: 11.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
        ),
      ],
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
