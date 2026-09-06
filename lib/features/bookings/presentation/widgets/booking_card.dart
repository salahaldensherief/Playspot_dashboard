import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/start_session_button.dart';

/// Redesigned Booking Card Widget accommodating all returned booking,
/// user, room, schedule, extras, financial, and action data.
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

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isPending = booking.status == BookingStatus.pending;
    final isPaid = booking.paymentStatus == PaymentStatus.paid;
    final isCanStartSession = isPending || booking.status == BookingStatus.upcoming;
    final isOverdue = _isPastStartTime(booking);
    final bool canAddItems = context.hasPermission('pos_view_menu') &&
        (booking.status == BookingStatus.upcoming || booking.status == BookingStatus.inProgress);

    final String durationHrsStr = (booking.durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');
    final String userInitials = _getInitials(booking.userName);
    final String formattedDate = DateFormat('MMM dd').format(booking.date);
    final String shortId = booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id;

    // Card Border Color based on status
    Color borderColor = AppColors.borderDefault;
    if (isOverdue) {
      borderColor = AppColors.danger.withValues(alpha: 0.8);
    } else if (isPending) {
      borderColor = AppColors.warning.withValues(alpha: 0.6);
    } else if (booking.status == BookingStatus.inProgress) {
      borderColor = AppColors.success.withValues(alpha: 0.6);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width ?? 320.w,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: _isHovered || isOverdue ? 1.5 : 1.0),
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? AppColors.danger.withValues(alpha: 0.15)
                  : (_isHovered
                      ? AppColors.neonBlue.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08)),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            onTap: () => _openDetailsDialog(context),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header Bar: Status Badge + ID + Time/Overdue
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _getStatusBadge(booking.status),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.mutedBackground,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: AppText.body(
                              '#$shortId',
                              fontSize: 10.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (isOverdue) ...[
                            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 14.r),
                            SizedBox(width: 4.w),
                          ],
                          AppText.body(
                            _formatTime(booking.startTime),
                            fontSize: 11.sp,
                            color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // 2. Customer Section: Avatar + Name + Contact Info
                  Row(
                    children: [
                      Container(
                        width: 38.r,
                        height: 38.r,
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
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.subHeading(
                              booking.userName ?? AppStrings.anonymous,
                              fontSize: 14.sp,
                              color: AppColors.textPrimary,
                              maxLines: 1,
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                if (booking.userPhone != null && booking.userPhone!.isNotEmpty) ...[
                                  Icon(Icons.phone_outlined, size: 12.r, color: AppColors.neonBlue),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: AppText.body(
                                      booking.userPhone!,
                                      fontSize: 11.sp,
                                      color: AppColors.neonBlue,
                                      maxLines: 1,
                                    ),
                                  ),
                                ] else if (booking.userEmail != null && booking.userEmail!.isNotEmpty) ...[
                                  Icon(Icons.email_outlined, size: 12.r, color: AppColors.textSecondary),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: AppText.body(
                                      booking.userEmail!,
                                      fontSize: 11.sp,
                                      color: AppColors.textSecondary,
                                      maxLines: 1,
                                    ),
                                  ),
                                ] else ...[
                                  AppText.body(
                                    AppStrings.anonymous,
                                    fontSize: 11.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // 3. Booking Specifications Box: Lounge, Room, Specs, Date & Time
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room & Controllers Info
                        Row(
                          children: [
                            Icon(Icons.sports_esports_outlined, color: AppColors.neonPurple, size: 16.r),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: AppText.subHeading(
                                booking.roomName.isNotEmpty ? booking.roomName : AppStrings.roomLabel,
                                fontSize: 13.sp,
                                color: AppColors.textPrimary,
                                maxLines: 1,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: AppText.body(
                                '$durationHrsStr ${AppStrings.hours}',
                                fontSize: 10.sp,
                                color: AppColors.neonPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),

                        // Schedule & Specs Subtitle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 12.r, color: AppColors.textSecondary),
                                SizedBox(width: 4.w),
                                AppText.body(
                                  formattedDate,
                                  fontSize: 11.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                            if (booking.controllersCount > 0)
                              AppText.body(
                                '${booking.controllersCount} ${AppStrings.controllers}',
                                fontSize: 11.sp,
                                color: AppColors.textMuted,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Extras Summary (if present)
                  if (booking.extras.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(8.r),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fastfood_outlined, size: 12.r, color: AppColors.neonBlue),
                              SizedBox(width: 4.w),
                              AppText.body(
                                '${AppStrings.additionalItems} (${booking.extras.length})',
                                fontSize: 10.sp,
                                color: AppColors.neonBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            booking.extras
                                .map((item) {
                                  final qty = item['quantity'] ?? item['qty'] ?? item['count'] ?? 1;
                                  final name = item['name'] ?? item['name_ar'] ?? item['name_en'] ?? item['title'] ?? 'إضافة';
                                  return '${qty}x $name';
                                })
                                .join(' • '),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 12.h),
                  const Divider(color: AppColors.borderDefault, height: 1),
                  SizedBox(height: 10.h),

                  // 5. Price & Financials Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.body(AppStrings.totalPrice, fontSize: 10.sp, color: AppColors.textMuted),
                          Row(
                            children: [
                              AppText.subHeading(
                                '${booking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                                color: AppColors.neonBlue,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              if ((booking.discountAmount ?? 0) > 0 || (booking.voucherDiscount ?? 0) > 0) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: AppText.body(
                                    AppStrings.discount,
                                    fontSize: 9.sp,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      isPaid
                          ? StatusBadge.success(AppStrings.paid.toUpperCase())
                          : StatusBadge.warning(AppStrings.unpaid.toUpperCase()),
                    ],
                  ),

                  // 6. Interactive Actions Bar
                  if (isPending || isCanStartSession || (!isPaid && widget.onConfirmPayment != null) || canAddItems) ...[
                    SizedBox(height: 12.h),
                    if (isCanStartSession)
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: StartSessionButton(
                                bookingId: booking.id,
                                bookingDate: booking.date,
                                startTime: booking.startTime,
                                onSuccess: widget.onStartSession,
                                height: 34.h,
                              ),
                            ),
                            if (isCanStartSession) ...[
                              SizedBox(width: 8.w),
                              Expanded(
                                flex: 2,
                                child: AppButton(
                                  text: AppStrings.noShow,
                                  icon: Icons.person_off_outlined,
                                  variant: AppButtonVariant.outlined,
                                  height: 34.h,
                                  onPressed: isOverdue ? () => _showNoShowConfirmDialog(context) : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
                              height: 34.h,
                            ),
                          ),
                          SizedBox(width: 8.w),
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
                              height: 34.h,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      if (canAddItems)
                        Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: AppButton(
                            text: AppStrings.addNew,
                            onPressed: () => _showAddExtrasDialog(context),
                            width: double.infinity,
                            height: 34.h,
                            variant: AppButtonVariant.outlined,
                            icon: Icons.add_shopping_cart,
                          ),
                        ),
                      if (!isPaid && widget.onConfirmPayment != null)
                        AppButton(
                          text: AppStrings.confirmCash,
                          onPressed: widget.onConfirmPayment ?? () {},
                          width: double.infinity,
                          height: 34.h,
                          icon: Icons.payments_outlined,
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
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
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        content: AppText.body(
          AppStrings.confirmNoShowMessage,
          fontSize: 13.sp,
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

  void _showAddExtrasDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.underConstruction)),
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
