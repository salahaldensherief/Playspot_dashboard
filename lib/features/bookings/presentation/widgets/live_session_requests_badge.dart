import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/utils/item_name_resolver.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';

class LiveSessionRequestsBadge extends StatelessWidget {
  final Booking booking;

  const LiveSessionRequestsBadge({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      buildWhen: (prev, curr) => prev.requests != curr.requests,
      builder: (context, requestsState) {
        final sessionRequests = requestsState.requests.where((r) {
          if (r.isAttended) return false;
          final matchBooking = r.bookingId != null && r.bookingId == booking.id;
          final matchRoom = r.roomId != null && r.roomId == booking.roomId;
          return matchBooking || matchRoom;
        }).toList();

        if (sessionRequests.isEmpty) return const SizedBox.shrink();

        final extrasCubit = context.read<ExtrasCubit?>();
        final List<ExtraEntity> availableExtras = extrasCubit?.state.extras ?? [];

        return Container(
          margin: EdgeInsets.only(top: 8.h),
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 14.r),
                  SizedBox(width: 4.w),
                  AppText.body(
                    '${AppStrings.sessionRequests} (${sessionRequests.length})',
                    fontSize: 11.sp,
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ...sessionRequests.take(2).map((req) {
                String displayText = '';
                if (req.isCanteenOrder && req.canteenItems.isNotEmpty) {
                  final itemsText = req.canteenItems.map((it) {
                    final qty = it['quantity'] ?? it['qty'] ?? 1;
                    final name = resolveItemName(it, availableExtras);
                    return '${qty}x $name';
                  }).join(', ');
                  displayText = '${AppStrings.canteenOrderLabel}: $itemsText';
                } else {
                  displayText = req.bodyAr.isNotEmpty ? req.bodyAr : req.titleAr;
                }

                final notes = req.metadata.notes;
                if (notes != null && notes.isNotEmpty) {
                  displayText += ' (ملاحظة: $notes)';
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText.body(
                          '• $displayText',
                          fontSize: 11.sp,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      InkWell(
                        borderRadius: BorderRadius.circular(6.r),
                        onTap: () {
                          context.read<ClientRequestsCubit>().markAsAttended(
                                req.id,
                                isCanteenOrder: req.isCanteenOrder,
                              );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            AppStrings.done,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10.sp,
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
