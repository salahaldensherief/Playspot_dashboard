import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'activity_item.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      buildWhen: (prev, curr) => prev.requests != curr.requests,
      builder: (context, requestsState) {
        return BlocBuilder<BookingCubit, BookingState>(
          buildWhen: (prev, curr) => prev.bookings != curr.bookings,
          builder: (context, bookingState) {
            final requests = requestsState.requests;
            final bookings = bookingState.bookings;

            final activityWidgets = <Widget>[];

            // 1. Add recent client requests
            for (final req in requests.take(3)) {
              activityWidgets.add(
                ActivityItem(
                  user: (req.userName != null && req.userName!.isNotEmpty) ? req.userName! : AppStrings.userLabel,
                  action: req.titleEn.isNotEmpty ? req.titleEn : req.type.name,
                  target: (req.roomName != null && req.roomName!.isNotEmpty) ? req.roomName! : AppStrings.rooms,
                  time: 'Active',
                  icon: req.isCanteenOrder ? Icons.fastfood_outlined : Icons.notifications_active_outlined,
                  iconColor: AppColors.warning,
                ),
              );
            }

            // 2. Add recent bookings
            for (final b in bookings.take(3)) {
              activityWidgets.add(
                ActivityItem(
                  user: (b.userName != null && b.userName!.isNotEmpty) ? b.userName! : AppStrings.userLabel,
                  action: AppStrings.bookingDetails,
                  target: b.roomName.isNotEmpty ? b.roomName : AppStrings.rooms,
                  time: b.status.name,
                  icon: Icons.event_available_outlined,
                  iconColor: AppColors.neonBlue,
                ),
              );
            }

            return Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.heading(
                        AppStrings.recentActivity,
                        fontSize: 18.sp,
                      ),
                      AppButton(
                        text: AppStrings.viewAll,
                        variant: AppButtonVariant.text,
                        onPressed: () => context.push(RouterKeys.loungeAdminLiveOps),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  if (activityWidgets.isNotEmpty)
                    ...activityWidgets
                  else ...[
                    SizedBox(height: 24.h),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_outlined,
                            size: 40.r,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12.h),
                          AppText.body(
                            AppStrings.noResultsMatching.replaceFirst("\"{}\"", ""),
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
