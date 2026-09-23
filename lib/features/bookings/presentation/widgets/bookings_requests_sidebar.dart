import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/live_requests_feed.dart';

class BookingsRequestsSidebar extends StatelessWidget {
  final bool isDrawer;
  final VoidCallback? onCloseDrawer;

  const BookingsRequestsSidebar({
    super.key,
    this.isDrawer = false,
    this.onCloseDrawer,
  });

  @override
  Widget build(BuildContext context) {
    if (isDrawer) {
      return Drawer(
        backgroundColor: AppColors.cardBackground,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.heading(AppStrings.clientRequestsAndAlerts, fontSize: 16.sp),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: onCloseDrawer,
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.borderDefault),
              const Expanded(child: RepaintBoundary(child: LiveRequestsFeed())),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 18),
                    ),
                    SizedBox(width: 8.w),
                    AppText.subHeading(AppStrings.clientRequestsAndAlerts, fontSize: 13.sp),
                  ],
                ),
                BlocSelector<ClientRequestsCubit, ClientRequestsState, int>(
                  selector: (state) => state.unreadCount,
                  builder: (context, unreadCount) {
                    if (unreadCount == 0) return const SizedBox.shrink();
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderDefault, height: 1),
          const Expanded(child: RepaintBoundary(child: LiveRequestsFeed())),
        ],
      ),
    );
  }
}
