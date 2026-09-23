import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';

class StationControlRequestsSection extends StatelessWidget {
  final Booking booking;

  const StationControlRequestsSection({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      buildWhen: (previous, current) {
        // Only rebuild if requests matching this booking/room have changed
        final prevMatch = previous.requests.any((r) =>
            !r.isAttended && (r.bookingId == booking.id || r.roomId == booking.roomId));
        final currMatch = current.requests.any((r) =>
            !r.isAttended && (r.bookingId == booking.id || r.roomId == booking.roomId));
        return prevMatch != currMatch || previous.requests != current.requests;
      },
      builder: (context, requestsState) {
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
      },
    );
  }
}
