import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class RoomOccupancyRequestsBadge extends StatelessWidget {
  final Booking booking;
  final RoomEntity room;

  const RoomOccupancyRequestsBadge({
    super.key,
    required this.booking,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      buildWhen: (previous, current) => previous.requests != current.requests,
      builder: (context, requestsState) {
        final sessionRequests = requestsState.requests.where((r) {
          if (r.isAttended) return false;
          final matchBooking = r.bookingId != null && r.bookingId == booking.id;
          final matchRoom = r.roomId != null && r.roomId == room.id;
          return matchBooking || matchRoom;
        }).toList();

        if (sessionRequests.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: EdgeInsets.only(top: 8.h),
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.warning),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.warning,
                    size: 14,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'طلبات الجلسة (${sessionRequests.length})',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              ...sessionRequests.map((req) {
                final title = req.titleAr.isNotEmpty ? req.titleAr : req.titleEn;
                final body = req.bodyAr.isNotEmpty ? req.bodyAr : req.bodyEn;
                return Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '• $title ${body.isNotEmpty ? "($body)" : ""}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      InkWell(
                        onTap: () {
                          context.read<ClientRequestsCubit>().markAsAttended(
                                req.id,
                                isCanteenOrder: req.isCanteenOrder,
                              );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'تم التنفيذ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
