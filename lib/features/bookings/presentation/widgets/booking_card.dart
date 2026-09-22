import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_countdown_timer.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_products_preview.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/customer_visit_badge.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_discount_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/start_session_button.dart';

import '../../../auth/presentation/login/login_cubit.dart';

/// Booking card (redesigned).
///
/// Reading order is built around what the cashier needs first:
///   1. Status + payment method      (tinted header, colored by urgency)
///   2. Who is coming                (avatar, name, visit badge, phone)
///   3. When + where                 (start time as the hero, room + specs)
///   4. Live state                   (cash countdown / session progress)
///   5. Canteen & extras
///   6. Money                        (total, discount, paid state)
///   7. What to do next              (actions)
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

  // ───────────────────────── helpers ─────────────────────────

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

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
    } catch (e) {
      return false;
    }
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return timeStr;
    }
  }

  /// One color that summarizes the urgency of the card.
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

  // ───────────────────────── build ─────────────────────────

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
                  _buildHeader(booking, accent, shortId),

                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2) Customer
                        _buildCustomerRow(booking),
                        SizedBox(height: 12.h),

                        // 3) When + where
                        _buildScheduleBox(booking, accent, isOverdue),

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
                          _SessionProgress(booking: booking),
                        ],

                        // 5) Canteen & extras (widget handles its own spacing / empty state)
                        BookingProductsPreview(booking: booking),

                        SizedBox(height: 12.h),
                        Container(height: 1, color: AppColors.borderDefault.withValues(alpha: 0.6)),
                        SizedBox(height: 10.h),

                        // 6) Money
                        _buildFinancialRow(booking, isPaid),
                        SizedBox(height: 12.h),

                        // 7) Actions
                        _buildActions(
                          booking: booking,
                          isPaid: isPaid,
                          isPending: isPending,
                          isCanStartSession: isCanStartSession,
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

  // ───────────────────────── sections ─────────────────────────

  Widget _buildHeader(Booking booking, Color accent, String shortId) {
    return Container(
      color: accent.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Wrap (not a horizontal scroll) so nothing is hidden inside the card.
          Expanded(
            child: Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _getStatusBadge(booking.status),
                _getPaymentTypeBadge(booking),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          AppText.body(
            '#$shortId',
            fontSize: 10.5.sp,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(Booking booking) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40.r,
          height: 40.r,
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
            _getInitials(booking.userName),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: AppText.subHeading(
                      booking.userName ?? AppStrings.anonymous,
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  CustomerVisitBadge(visitNumber: booking.visitNumber),
                ],
              ),
              SizedBox(height: 2.h),
              AppText.body(
                booking.userPhone ?? booking.userEmail ?? AppStrings.anonymous,
                fontSize: 11.sp,
                color: AppColors.neonBlue,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Start time is the hero of the card. Room + specs sit next to it.
  Widget _buildScheduleBox(Booking booking, Color accent, bool isOverdue) {
    final String durationHrsStr = (booking.durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');
    final String formattedDate = DateFormat('MMM dd').format(booking.date);
    final bool hasPlayMode = booking.playMode != null && booking.playMode!.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                      size: 15.r,
                      color: isOverdue ? AppColors.danger : accent,
                    ),
                    SizedBox(width: 4.w),
                    AppText.subHeading(
                      _formatTime(booking.startTime),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 11.r, color: AppColors.textMuted),
                    SizedBox(width: 4.w),
                    AppText.body(formattedDate, fontSize: 11.sp, color: AppColors.textMuted),
                    SizedBox(width: 6.w),
                    _Chip(
                      label: '$durationHrsStr ${AppStrings.hours}',
                      color: AppColors.neonPurple,
                    ),
                  ],
                ),
              ],
            ),

            Container(
              width: 1,
              margin: EdgeInsets.symmetric(horizontal: 10.w),
              color: AppColors.borderDefault,
            ),

            // Room column
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sports_esports_outlined, color: AppColors.neonPurple, size: 15.r),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: AppText.subHeading(
                          booking.roomName.isNotEmpty ? booking.roomName : AppStrings.roomLabel,
                          fontSize: 12.5.sp,
                          color: AppColors.textPrimary,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  if (hasPlayMode || booking.controllersCount > 0 || booking.screenSize.isNotEmpty) ...[
                    SizedBox(height: 5.h),
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.h,
                      children: [
                        if (hasPlayMode)
                          _Chip(label: booking.playMode!, color: AppColors.neonBlue),
                        if (booking.controllersCount > 0)
                          _Chip(
                            label: '${booking.controllersCount} ${AppStrings.controllersLabel}',
                            icon: Icons.gamepad_outlined,
                            color: AppColors.textSecondary,
                          ),
                        if (booking.screenSize.isNotEmpty)
                          _Chip(
                            label: booking.screenSize,
                            icon: Icons.tv_outlined,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(Booking booking, bool isPaid) {
    final hasDiscount = (booking.discountAmount ?? 0) > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(
                AppStrings.totalPrice,
                fontSize: 10.5.sp,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Flexible(
                    child: AppText.subHeading(
                      '${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                      color: AppColors.neonBlue,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                    ),
                  ),
                  if (hasDiscount) ...[
                    SizedBox(width: 6.w),
                    _Chip(
                      label: '-${booking.discountAmount!.toStringAsFixed(0)} ${AppStrings.egp}',
                      color: AppColors.warning,
                      bordered: true,
                    ),
                  ],
                  SizedBox(width: 6.w),
                  Tooltip(
                    message: AppStrings.applyDiscount,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () => _showDiscountDialog(context),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.local_offer_outlined, size: 14.r, color: AppColors.warning),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        isPaid
            ? StatusBadge.success(AppStrings.paid.toUpperCase())
            : StatusBadge.warning(AppStrings.unpaid.toUpperCase()),
      ],
    );
  }

  /// Same rules as before, only taller buttons (36) for easier tapping.
  Widget _buildActions({
    required Booking booking,
    required bool isPaid,
    required bool isPending,
    required bool isCanStartSession,
  }) {
    final double h = 36.h;

    Widget detailsButton() => AppButton(
          text: AppStrings.bookingDetails,
          variant: AppButtonVariant.outlined,
          onPressed: () => _openDetailsDialog(context),
          width: double.infinity,
          height: h,
        );

    // Approved upcoming booking (Cash, Wallet, or Online)
    if (booking.status == BookingStatus.upcoming) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: StartSessionButton(
              bookingId: booking.id,
              bookingDate: booking.date,
              startTime: booking.startTime,
              onSuccess: widget.onStartSession,
              height: h,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: AppButton(
              text: AppStrings.markNoShowAction,
              variant: AppButtonVariant.outlined,
              height: h,
              onPressed: () => _showNoShowConfirmDialog(context),
            ),
          ),
        ],
      );
    }

    // Cash booking (Pending)
    if (booking.isCashPayment) {
      if (!isCanStartSession) return detailsButton();
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: StartSessionButton(
              bookingId: booking.id,
              bookingDate: booking.date,
              startTime: booking.startTime,
              onSuccess: widget.onStartSession,
              height: h,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: AppButton(
              text: AppStrings.markNoShowAction,
              variant: AppButtonVariant.outlined,
              height: h,
              onPressed: () => _showNoShowConfirmDialog(context),
            ),
          ),
        ],
      );
    }

    // Wallet / e-payment booking
    if (!isPaid && (isPending || isCanStartSession)) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              text: AppStrings.confirmReceipt,
              variant: AppButtonVariant.primary,
              backgroundColor: AppColors.neonBlue,
              height: h,
              onPressed: () {
                if (widget.onConfirmPayment != null) {
                  widget.onConfirmPayment!();
                } else {
                  _openDetailsDialog(context);
                }
              },
            ),
          ),
          if (isPending) ...[
            SizedBox(width: 8.w),
            Expanded(
              child: AppButton(
                text: AppStrings.reject,
                variant: AppButtonVariant.outlined,
                height: h,
                onPressed: () {
                  if (widget.onReject != null) {
                    widget.onReject!();
                  } else {
                    context.read<BookingCubit>().rejectBooking(booking.id);
                  }
                },
              ),
            ),
          ],
        ],
      );
    }

    return detailsButton();
  }

  // ───────────────────────── badges ─────────────────────────

  Widget _getPaymentTypeBadge(Booking booking) {
    if (booking.isCashPayment) {
      return StatusBadge.warning(AppStrings.cashBookingBadge);
    }
    return StatusBadge.info('${AppStrings.walletLabel} (${booking.displayWalletInfo})');
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

  // ───────────────────────── dialogs ─────────────────────────

  void _showNoShowConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Row(
          children: [
            const Icon(Icons.person_off, color: AppColors.danger),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText.subHeading(
                AppStrings.confirmNoShow,
                color: AppColors.danger,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
        content: AppText.body(
          AppStrings.confirmNoShowMessage,
          fontSize: 12.sp,
          color: AppColors.textPrimary,
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppButton(
            text: AppStrings.markNoShow,
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final cubit = context.read<BookingCubit>();
              final success = await cubit.markNoShow(widget.booking.id);
              if (widget.onNoShow != null) {
                widget.onNoShow!();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? AppStrings.noShowSuccess : AppStrings.noShowFailed),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── small widgets ─────────────────────────

/// Small pill used for duration, play mode, controllers, screen size, discount.
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool bordered;

  const _Chip({
    required this.label,
    required this.color,
    this.icon,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: bordered ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.r, color: color),
            SizedBox(width: 3.w),
          ],
          Flexible(
            child: AppText.body(
              label,
              fontSize: 10.5.sp,
              color: color,
              fontWeight: FontWeight.w600,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live session progress. Owns a light timer so the bar and the remaining
/// minutes stay fresh without the parent list having to rebuild.
class _SessionProgress extends StatefulWidget {
  final Booking booking;
  const _SessionProgress({required this.booking});

  @override
  State<_SessionProgress> createState() => _SessionProgressState();
}

class _SessionProgressState extends State<_SessionProgress> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.booking.startDateTime;
    final end = widget.booking.endDateTime;
    final now = DateTime.now();

    int remainingMins = 0;
    double progress = 0.0;

    if (start != null && end != null) {
      final totalDuration = end.difference(start).inMinutes;
      final elapsed = now.difference(start).inMinutes;
      if (totalDuration > 0) {
        progress = (elapsed / totalDuration).clamp(0.0, 1.0);
        remainingMins = (totalDuration - elapsed).clamp(0, 999).toInt();
      }
    }

    final bool almostDone = remainingMins <= 5;
    final String remainingText =
        remainingMins > 0 ? '${AppStrings.remaining}: $remainingMins ${AppStrings.minutesUnit}' : AppStrings.timeUp;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 13.r, color: AppColors.success),
                  SizedBox(width: 4.w),
                  AppText.body(
                    AppStrings.sessionActive,
                    fontSize: 11.sp,
                    color:AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              AppText.body(
                remainingText,
                fontSize: 11.sp,
                color: almostDone ? AppColors.warning : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5.h,
              backgroundColor: AppColors.mutedBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? AppColors.warning : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
