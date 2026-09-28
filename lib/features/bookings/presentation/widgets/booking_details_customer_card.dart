import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/customer_cancellation_summary.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_repository.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/moderation_cubit.dart';
import 'package:play_spot_dashboard/features/users/presentation/widgets/report_user_ban_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_cancellation_history_dialog.dart';

class BookingDetailsCustomerCard extends StatefulWidget {
  final Booking booking;

  const BookingDetailsCustomerCard({super.key, required this.booking});

  @override
  State<BookingDetailsCustomerCard> createState() => _BookingDetailsCustomerCardState();
}

class _BookingDetailsCustomerCardState extends State<BookingDetailsCustomerCard> {
  CustomerCancellationSummary? _summary;
  bool _isLoadingSummary = true;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    if (widget.booking.loungeId.isEmpty || widget.booking.userId.isEmpty) {
      if (mounted) setState(() => _isLoadingSummary = false);
      return;
    }

    try {
      final repository = sl<BookingRepository>();
      final result = await repository.getBookingCancellationSummary(
        loungeId: widget.booking.loungeId,
        userId: widget.booking.userId,
      );

      result.fold(
        (_) {
          if (mounted) setState(() => _isLoadingSummary = false);
        },
        (summaryData) {
          if (mounted) {
            setState(() {
              _summary = summaryData;
              _isLoadingSummary = false;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  void _subscribeRealtime() {
    if (widget.booking.loungeId.isEmpty) return;
    try {
      final channelName = 'public:bookings_cancellation_${widget.booking.loungeId}_${widget.booking.userId}';
      _realtimeChannel = Supabase.instance.client.channel(channelName);
      _realtimeChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'lounge_id',
              value: widget.booking.loungeId,
            ),
            callback: (payload) {
              final newStatus = payload.newRecord['status']?.toString();
              if (newStatus == 'cancelled' || payload.eventType == PostgresChangeEvent.update) {
                _fetchSummary();
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void _showWarningIssueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8.w),
            Text(AppStrings.issueWarningBtn, style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'سيتم تسجيل تحذير للعميل ${widget.booking.userName ?? ""} على تجاوزه حد الإلغاءات بعد الموافقة.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.pop(diagContext),
          ),
          AppButton(
            text: 'إرسال التحذير',
            backgroundColor: AppColors.warning,
            onPressed: () {
              Navigator.pop(diagContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تسجيل وإرسال التحذير للعميل بنجاح'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openBanReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => sl<ModerationCubit>(),
        child: ReportUserBanDialog(
          loungeId: widget.booking.loungeId,
          userId: widget.booking.userId,
          bookingId: widget.booking.id,
          userName: widget.booking.userName,
        ),
      ),
    );
  }

  void _openHistoryDialog(BuildContext context) {
    if (_summary == null) return;
    showDialog(
      context: context,
      builder: (_) => CustomerCancellationHistoryDialog(
        userName: widget.booking.userName ?? AppStrings.anonymous,
        history: _summary!.history,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final currentUser = context.watch<LoginCubit>().state.user;
    final isLoungeAdmin = currentUser?.isLoungeAdmin == true;

    final afterApprovalCount = _summary?.afterApprovalCount ?? 0;
    final last90DaysCount = _summary?.last90DaysCount ?? 0;
    final bool hasCancellationAlert = afterApprovalCount >= 1;

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
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.neonBlue.withAlpha(30),
                child: Text(
                  (booking.userName ?? 'C').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.neonBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.userName ?? AppStrings.anonymous,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      booking.userPhone ?? 'لا يوجد هاتف',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoungeAdmin)
                IconButton(
                  icon: const Icon(Icons.report_problem_outlined,
                      color: AppColors.danger, size: 20),
                  tooltip: AppStrings.reportCustomerTooltip,
                  onPressed: () => _openBanReportDialog(context),
                ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: booking.isFirstBooking
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: booking.isFirstBooking
                        ? AppColors.warning.withValues(alpha: 0.5)
                        : AppColors.borderDefault,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      booking.isFirstBooking ? Icons.star_rounded : Icons.person_pin_circle_outlined,
                      size: 14.r,
                      color: booking.isFirstBooking ? AppColors.warning : AppColors.neonPurple,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      booking.isFirstBooking ? AppStrings.firstBookingBadge : AppStrings.returningCustomerBadge,
                      style: TextStyle(
                        color: booking.isFirstBooking ? AppColors.warning : AppColors.textPrimary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Cancellation summary section
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: hasCancellationAlert
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : AppColors.borderDefault,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 16.r,
                          color: hasCancellationAlert ? AppColors.warning : AppColors.textMuted,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          AppStrings.cancellationSummary,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_summary != null && _summary!.history.isNotEmpty)
                      InkWell(
                        onTap: () => _openHistoryDialog(context),
                        child: Text(
                          AppStrings.viewCancellationHistory,
                          style: TextStyle(
                            color: AppColors.neonBlue,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                if (_isLoadingSummary)
                  SizedBox(
                    height: 20.h,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12.r,
                          height: 12.r,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonBlue),
                        ),
                        SizedBox(width: 8.w),
                        Text('جاري تحميل سجل الإلغاءات...',
                            style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 4.h,
                    children: [
                      Text(
                        '${AppStrings.afterApprovalCountLabel}: $afterApprovalCount',
                        style: TextStyle(
                          color: afterApprovalCount > 0 ? AppColors.warning : AppColors.textSecondary,
                          fontSize: 11.sp,
                          fontWeight: afterApprovalCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        '${AppStrings.last90DaysCountLabel}: $last90DaysCount',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),

                // Threshold Alert Banner & Action Buttons for Manager / Owner
                if (hasCancellationAlert) ...[
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.cancellationThresholdWarning,
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isLoungeAdmin) ...[
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.warning),
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(Icons.warning_amber_rounded, size: 14.r, color: AppColors.warning),
                                label: Text(
                                  AppStrings.issueWarningBtn,
                                  style: TextStyle(fontSize: 11.sp, color: AppColors.warning),
                                ),
                                onPressed: () => _showWarningIssueDialog(context),
                              ),
                              SizedBox(width: 8.w),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(Icons.gavel_rounded, size: 14.r, color: Colors.white),
                                label: Text(
                                  AppStrings.requestBanBtn,
                                  style: TextStyle(fontSize: 11.sp, color: Colors.white),
                                ),
                                onPressed: () => _openBanReportDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
