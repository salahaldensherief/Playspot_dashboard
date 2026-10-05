import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/customer_cancellation_summary.dart';

class CustomerCancellationHistoryDialog extends StatelessWidget {
  final String userName;
  final List<BookingCancellationHistoryItem> history;

  const CustomerCancellationHistoryDialog({
    super.key,
    required this.userName,
    required this.history,
  });

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('yyyy/MM/dd hh:mm a').format(dt);
    } catch (_) {
      return dt.toString();
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('yyyy/MM/dd').format(dt);
    } catch (_) {
      return dt.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: AppStrings.cancellationHistoryTitle,
      icon: Icons.history_toggle_off_rounded,
      width: 550.w,
      actions: [
        AppButton(
          text: AppStrings.close,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'customer_name_label'.tr(args: [userName]),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 12.h),
          if (history.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48.r,
                      color: AppColors.success,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      AppStrings.noCancellationHistory,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final item = history[index];
                final reason = item.cancellationReason?.trim();
                return Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.mutedBackground.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.borderDefault),
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
                                Icons.event_seat_rounded,
                                size: 16.r,
                                color: AppColors.neonBlue,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                item.roomName ?? AppStrings.roomLabel,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '#${item.bookingId.length > 8 ? item.bookingId.substring(0, 8) : item.bookingId}',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13.r,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'cancelled_booking_schedule'.tr(
                              args: [
                                _formatDate(item.date),
                                (item.startTime ?? '').toString(),
                                (item.endTime ?? '').toString(),
                              ],
                            ),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            size: 13.r,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'cancelled_at_label'.tr(
                              args: [_formatDateTime(item.cancelledAt)],
                            ),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                      if (reason != null && reason.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'cancellation_reason_label'.tr(
                              args: [reason],
                            ),
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
