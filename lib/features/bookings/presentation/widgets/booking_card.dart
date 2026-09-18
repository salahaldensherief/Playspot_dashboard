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
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_products_preview.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/customer_visit_badge.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_discount_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/start_session_button.dart';

/// Redesigned Compact & Feature-Rich Booking Card Widget
/// Displays status, live session progress, customer visit badge (new/returning/VIP),
/// room specs, itemized canteen orders & extras, total price, and quick actions.
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

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isPending = booking.status == BookingStatus.pending;
    final isPaid = booking.paymentStatus == PaymentStatus.paid;
    final isCanStartSession = isPending || booking.status == BookingStatus.upcoming;
    final isOverdue = _isPastStartTime(booking);
    final isInProgress = booking.status == BookingStatus.inProgress;

    final String durationHrsStr = (booking.durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');
    final String userInitials = _getInitials(booking.userName);
    final String formattedDate = DateFormat('MMM dd').format(booking.date);
    final String shortId = booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id;

    Color borderColor = AppColors.borderDefault;
    if (isOverdue) {
      borderColor = AppColors.danger.withValues(alpha: 0.8);
    } else if (isPending) {
      borderColor = AppColors.warning.withValues(alpha: 0.6);
    } else if (isInProgress) {
      borderColor = AppColors.success.withValues(alpha: 0.7);
    }

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
        duration: const Duration(milliseconds: 200),
        width: widget.width ?? 320.w,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: _isHovered || isOverdue || isInProgress ? 1.5 : 1.0),
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? AppColors.danger.withValues(alpha: 0.15)
                  : (isInProgress
                      ? AppColors.success.withValues(alpha: 0.12)
                      : (_isHovered ? AppColors.neonBlue.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08))),
              blurRadius: _isHovered || isInProgress ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          child: InkWell(
            onTap: () => _openDetailsDialog(context),
            borderRadius: BorderRadius.circular(14.r),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header: Status Badge + ID + Time / Live Countdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _getStatusBadge(booking.status),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.mutedBackground,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: AppText.body(
                              '#$shortId',
                              fontSize: 9.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (isOverdue) ...[
                            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 13.r),
                            SizedBox(width: 3.w),
                          ],
                          AppText.body(
                            _formatTime(booking.startTime),
                            fontSize: 10.sp,
                            color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // 2. Customer Row: Avatar + Name + Customer Visit Badge + Phone
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 34.r,
                        height: 34.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.neonBlue.withValues(alpha: 0.7),
                              AppColors.neonPurple.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userInitials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6.w,
                              runSpacing: 2.h,
                              children: [
                                AppText.subHeading(
                                  booking.userName ?? AppStrings.anonymous,
                                  fontSize: 13.sp,
                                  color: AppColors.textPrimary,
                                  maxLines: 1,
                                ),
                                CustomerVisitBadge(visitNumber: booking.visitNumber),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            AppText.body(
                              booking.userPhone ?? booking.userEmail ?? AppStrings.anonymous,
                              fontSize: 10.sp,
                              color: AppColors.neonBlue,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // 3. Compact Room & Specs Box
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sports_esports_outlined, color: AppColors.neonPurple, size: 14.r),
                                SizedBox(width: 4.w),
                                AppText.subHeading(
                                  booking.roomName.isNotEmpty ? booking.roomName : AppStrings.roomLabel,
                                  fontSize: 11.sp,
                                  color: AppColors.textPrimary,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 10.r, color: AppColors.textMuted),
                                SizedBox(width: 3.w),
                                AppText.body(
                                  formattedDate,
                                  fontSize: 10.sp,
                                  color: AppColors.textMuted,
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: AppText.body(
                                    '$durationHrsStr ${AppStrings.hours}',
                                    fontSize: 9.sp,
                                    color: AppColors.neonPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (booking.controllersCount > 0 || booking.screenSize.isNotEmpty || booking.playMode != null) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              if (booking.controllersCount > 0) ...[
                                Icon(Icons.gamepad_outlined, size: 10.r, color: AppColors.textSecondary),
                                SizedBox(width: 3.w),
                                AppText.body(
                                  '${booking.controllersCount} دراعات',
                                  fontSize: 9.5.sp,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 8.w),
                              ],
                              if (booking.screenSize.isNotEmpty) ...[
                                Icon(Icons.tv_outlined, size: 10.r, color: AppColors.textSecondary),
                                SizedBox(width: 3.w),
                                AppText.body(
                                  booking.screenSize,
                                  fontSize: 9.5.sp,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 8.w),
                              ],
                              if (booking.playMode != null && booking.playMode!.isNotEmpty) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonBlue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: AppText.body(
                                    booking.playMode!,
                                    fontSize: 9.sp,
                                    color: AppColors.neonBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 4. Live Session Timer Bar (For Active In-Progress Bookings)
                  if (isInProgress) ...[
                    SizedBox(height: 6.h),
                    _buildSessionProgressBar(booking),
                  ],

                  // 5. Itemized Products Box (Canteen Orders & Extras)
                  BookingProductsPreview(booking: booking),

                  SizedBox(height: 8.h),

                  // 6. Financials Bar: Price & Paid Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          AppText.body('${AppStrings.totalPrice}: ', fontSize: 10.sp, color: AppColors.textMuted),
                          AppText.subHeading(
                            '${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                            color: AppColors.neonBlue,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          if ((booking.discountAmount ?? 0) > 0) ...[
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '-${booking.discountAmount!.toStringAsFixed(0)} ج.م',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(width: 4.w),
                          IconButton(
                            icon: Icon(Icons.local_offer_outlined, size: 14.r, color: AppColors.warning),
                            tooltip: AppStrings.applyDiscount,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showDiscountDialog(context),
                          ),
                        ],
                      ),
                      isPaid
                          ? StatusBadge.success(AppStrings.paid.toUpperCase())
                          : StatusBadge.warning(AppStrings.unpaid.toUpperCase()),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // 7. Compact Action Buttons Bar
                  if (isPending)
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: AppStrings.approve,
                            onPressed: () {
                              if (widget.onApprove != null) {
                                widget.onApprove!();
                              } else {
                                context.read<BookingCubit>().approveBooking(booking.id);
                              }
                            },
                            height: 30.h,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: AppButton(
                            text: AppStrings.reject,
                            variant: AppButtonVariant.outlined,
                            onPressed: () {
                              if (widget.onReject != null) {
                                widget.onReject!();
                              } else {
                                context.read<BookingCubit>().rejectBooking(booking.id);
                              }
                            },
                            height: 30.h,
                          ),
                        ),
                      ],
                    )
                  else if (isCanStartSession)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: StartSessionButton(
                            bookingId: booking.id,
                            bookingDate: booking.date,
                            startTime: booking.startTime,
                            onSuccess: widget.onStartSession,
                            height: 30.h,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            text: AppStrings.noShow,
                            variant: AppButtonVariant.outlined,
                            height: 30.h,
                            onPressed: isOverdue ? () => _showNoShowConfirmDialog(context) : null,
                          ),
                        ),
                      ],
                    )
                  else if (!isPaid && widget.onConfirmPayment != null)
                    AppButton(
                      text: AppStrings.confirmCash,
                      onPressed: widget.onConfirmPayment ?? () {},
                      width: double.infinity,
                      height: 30.h,
                      icon: Icons.payments_outlined,
                    )
                  else
                    AppButton(
                      text: AppStrings.bookingDetails,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => _openDetailsDialog(context),
                      width: double.infinity,
                      height: 30.h,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionProgressBar(Booking booking) {
    final start = booking.startDateTime;
    final end = booking.endDateTime;
    final now = DateTime.now();

    int remainingMins = 0;
    double progress = 0.0;

    if (start != null && end != null) {
      final totalDuration = end.difference(start).inMinutes;
      final elapsed = now.difference(start).inMinutes;
      if (totalDuration > 0) {
        progress = (elapsed / totalDuration).clamp(0.0, 1.0);
        remainingMins = (totalDuration - elapsed).clamp(0, 999);
      }
    }

    final String remainingText = remainingMins > 0 ? 'متبقي: $remainingMins دقيقة' : 'انتهى الوقت!';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
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
                  Icon(Icons.timer_outlined, size: 11.r, color: AppColors.success),
                  SizedBox(width: 4.w),
                  Text(
                    'الجلسة نشطة',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                remainingText,
                style: TextStyle(
                  color: remainingMins <= 5 ? AppColors.warning : AppColors.textPrimary,
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.h,
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
