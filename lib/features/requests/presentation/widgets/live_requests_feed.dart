import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/status_badge.dart';
import '../../domain/entities/client_request_entity.dart';
import '../cubit/client_requests_cubit.dart';
import '../cubit/client_requests_state.dart';

class LiveRequestsFeed extends StatelessWidget {
  const LiveRequestsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      builder: (context, state) {
        final requests = state.filteredRequests;
        final unreadCount = state.unreadCount;

        return Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Unread Count Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: unreadCount > 0
                              ? AppColors.danger.withValues(alpha: 0.15)
                              : AppColors.neonBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          unreadCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                          color: unreadCount > 0 ? AppColors.danger : AppColors.neonBlue,
                          size: 18.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      AppText.heading(
                        AppStrings.requestsFeed,
                        fontSize: 16.sp,
                      ),
                      if (unreadCount > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: AppText.body(
                            '$unreadCount',
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (state.status == ClientRequestsStatus.loading && requests.isEmpty)
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              SizedBox(height: 14.h),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      label: AppStrings.all,
                      filter: RequestFilter.all,
                      currentFilter: state.filter,
                    ),
                    SizedBox(width: 6.w),
                    _buildFilterChip(
                      context,
                      label: AppStrings.callStaff,
                      filter: RequestFilter.callStaff,
                      currentFilter: state.filter,
                    ),
                    SizedBox(width: 6.w),
                    _buildFilterChip(
                      context,
                      label: AppStrings.canteenOrder,
                      filter: RequestFilter.canteenOrders,
                      currentFilter: state.filter,
                    ),
                    SizedBox(width: 6.w),
                    _buildFilterChip(
                      context,
                      label: AppStrings.unread,
                      filter: RequestFilter.unattendedOnly,
                      currentFilter: state.filter,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Requests List
              if (requests.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 36.r, color: AppColors.textMuted),
                        SizedBox(height: 8.h),
                        AppText.body(
                          AppStrings.noActiveRequests,
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.take(10).length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.divider, height: 20.h),
                  itemBuilder: (context, index) {
                    final item = requests[index];
                    return _buildRequestTile(context, item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required RequestFilter filter,
    required RequestFilter currentFilter,
  }) {
    final isSelected = filter == currentFilter;
    return ChoiceChip(
      label: AppText.body(
        label,
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontSize: 11.sp,
      ),
      selected: isSelected,
      selectedColor: AppColors.neonBlue,
      backgroundColor: AppColors.cardBackground,
      side: BorderSide(color: isSelected ? AppColors.neonBlue : AppColors.borderDefault),
      onSelected: (selected) {
        if (selected) {
          context.read<ClientRequestsCubit>().setFilter(filter);
        }
      },
    );
  }

  Widget _buildRequestTile(BuildContext context, ClientRequestEntity request) {
    final cubit = context.read<ClientRequestsCubit>();
    final isCallStaff = request.type == ClientRequestType.callStaff;
    final isCanteen = request.isCanteenOrder;
    final timeFormatted = DateFormat('hh:mm a').format(request.createdAt);

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: request.isAttended
            ? Colors.transparent
            : AppColors.neonBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: request.isAttended
              ? Colors.transparent
              : AppColors.neonBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Avatar
          CircleAvatar(
            radius: 18.r,
            backgroundColor: isCallStaff
                ? AppColors.warning.withValues(alpha: 0.15)
                : AppColors.success.withValues(alpha: 0.15),
            child: Icon(
              isCallStaff
                  ? Icons.notifications_active
                  : (isCanteen ? Icons.restaurant_menu : Icons.room_service),
              color: isCallStaff ? AppColors.warning : AppColors.success,
              size: 18.r,
            ),
          ),
          SizedBox(width: 12.w),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.subHeading(
                      request.roomName ?? request.userName ?? AppStrings.anonymous,
                      fontSize: 13.sp,
                      color: AppColors.textPrimary,
                    ),
                    AppText.body(
                      timeFormatted,
                      fontSize: 10.sp,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Request Title/Body
                AppText.body(
                  request.titleAr.isNotEmpty ? request.titleAr : request.bodyAr,
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),

                // Canteen Items Summary
                if (request.canteenItems.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: request.canteenItems.map((item) {
                        final name = item['name_ar'] ?? item['name'] ?? item['name_en'] ?? '';
                        final qty = item['quantity'] ?? item['qty'] ?? 1;
                        return AppText.body(
                          '• ${qty}x $name',
                          fontSize: 10.sp,
                          color: AppColors.textPrimary,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Action Button / Attended Status
          if (request.isAttended)
            StatusBadge.success(AppStrings.attended)
          else
            AppButton(
              text: AppStrings.markAsAttended,
              variant: AppButtonVariant.primary,
              height: 28.h,
              onPressed: () {
                cubit.markAsAttended(
                  request.id,
                  isCanteenOrder: request.isCanteenOrder,
                );
              },
            ),
        ],
      ),
    );
  }
}
