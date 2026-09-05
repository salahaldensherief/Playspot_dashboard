import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/status_badge.dart';
import '../../../analytics/presentation/dashboard_cubit.dart';
import '../../domain/entities/client_request_entity.dart';
import '../client_requests_cubit.dart';
import '../client_requests_state.dart';

/// Premium Live Operations Requests Feed handling all client mobile request types:
/// Staff Calls, Canteen Orders, Session Extensions, and General Service Requests.
class LiveRequestsFeed extends StatelessWidget {
  const LiveRequestsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      builder: (context, state) {
        final requests = state.filteredRequests;
        final unreadCount = state.unreadCount;

        return Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: unreadCount > 0
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : AppColors.borderDefault,
              width: unreadCount > 0 ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (unreadCount > 0)
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: unreadCount > 0
                              ? AppColors.warning.withValues(alpha: 0.15)
                              : AppColors.neonBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          color: unreadCount > 0 ? AppColors.warning : AppColors.neonBlue,
                          size: 20.r,
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
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: AppText.body(
                            '$unreadCount',
                            color: Colors.black,
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
                      count: state.requests.length,
                    ),
                    SizedBox(width: 8.w),
                    _buildFilterChip(
                      context,
                      label: AppStrings.callStaff,
                      filter: RequestFilter.callStaff,
                      currentFilter: state.filter,
                      count: state.requests.where((r) => r.type == ClientRequestType.callStaff && !r.isAttended).length,
                    ),
                    SizedBox(width: 8.w),
                    _buildFilterChip(
                      context,
                      label: AppStrings.canteenOrder,
                      filter: RequestFilter.canteenOrders,
                      currentFilter: state.filter,
                      count: state.requests.where((r) => r.isCanteenOrder && !r.isAttended).length,
                    ),
                    SizedBox(width: 8.w),
                    _buildFilterChip(
                      context,
                      label: AppStrings.unread,
                      filter: RequestFilter.unattendedOnly,
                      currentFilter: state.filter,
                      count: unreadCount,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Content List / Empty State
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
                  itemCount: requests.take(15).length,
                  separatorBuilder: (context, index) => Divider(color: AppColors.divider, height: 16.h),
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
    int count = 0,
  }) {
    final isSelected = filter == currentFilter;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.body(
            label,
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontSize: 11.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          if (count > 0) ...[
            SizedBox(width: 4.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withValues(alpha: 0.2) : AppColors.neonBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppText.body(
                '$count',
                color: isSelected ? Colors.black : AppColors.neonBlue,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      selectedColor: AppColors.neonBlue,
      backgroundColor: AppColors.mutedBackground,
      side: BorderSide(color: isSelected ? AppColors.neonBlue : AppColors.borderDefault),
      onSelected: (selected) {
        if (selected) {
          context.read<ClientRequestsCubit>().setFilter(filter);
        }
      },
    );
  }

  Widget _buildRequestTile(BuildContext context, ClientRequestEntity request) {
    final requestsCubit = context.read<ClientRequestsCubit>();
    final dashboardCubit = context.read<DashboardCubit>();

    final isCallStaff = request.type == ClientRequestType.callStaff;
    final isExtension = request.type == ClientRequestType.extendSession;
    final isCanteen = request.isCanteenOrder;
    final timeFormatted = DateFormat('hh:mm a').format(request.createdAt);

    Color themeColor;
    IconData iconData;

    if (isCallStaff) {
      themeColor = AppColors.warning;
      iconData = Icons.notifications_active_rounded;
    } else if (isExtension) {
      themeColor = AppColors.neonBlue;
      iconData = Icons.add_alarm_rounded;
    } else if (isCanteen) {
      themeColor = AppColors.success;
      iconData = Icons.restaurant_menu_rounded;
    } else {
      themeColor = AppColors.neonPurple;
      iconData = Icons.room_service_rounded;
    }

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: request.isAttended
            ? Colors.transparent
            : themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: request.isAttended
              ? AppColors.borderDefault.withValues(alpha: 0.5)
              : themeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Room & User + Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: themeColor.withValues(alpha: 0.15),
                child: Icon(
                  iconData,
                  color: themeColor,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppText.subHeading(
                          request.roomName ?? request.userName ?? AppStrings.anonymous,
                          fontSize: 13.sp,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 6.w),
                        if (request.userName != null && request.userName?.isNotEmpty == true)
                          AppText.body(
                            '(${request.userName})',
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    AppText.body(
                      request.titleAr.isNotEmpty ? request.titleAr : request.bodyAr,
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              AppText.body(
                timeFormatted,
                fontSize: 10.sp,
                color: AppColors.textMuted,
              ),
            ],
          ),

          // Request Specific Metadata Body
          if (isExtension) ...[
            SizedBox(height: 10.h),
            _buildExtensionDetailsRow(request),
          ] else if (isCanteen && request.canteenItems.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _buildCanteenItemsBox(request),
          ],

          SizedBox(height: 10.h),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (request.isAttended)
                StatusBadge.success(AppStrings.attended)
              else if (isExtension) ...[
                // Reject Extension Button
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                  ),
                  onPressed: () async {
                    final firstItem = request.metadata.items.isNotEmpty ? request.metadata.items.first : <String, dynamic>{};
                    final reqMins = (firstItem['requested_minutes'] ?? firstItem['minutes'] as num?)?.toInt() ?? 30;
                    final curDuration = (firstItem['current_duration'] as num?)?.toInt() ?? 60;
                    final bookingId = request.bookingId ?? request.id.replaceFirst('ext_', '');

                    final success = await dashboardCubit.reviewExtensionRequest(
                      bookingId: bookingId,
                      isApproved: false,
                      requestedMinutes: reqMins,
                      currentDurationMinutes: curDuration,
                    );

                    if (success && context.mounted) {
                      requestsCubit.markAsAttended(request.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.requestRejected),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.close, size: 14.r, color: AppColors.danger),
                      SizedBox(width: 4.w),
                      AppText.body(AppStrings.rejectRequest, color: AppColors.danger, fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),

                // Approve Extension Button
                AppButton(
                  text: AppStrings.approveRequest,
                  icon: Icons.check,
                  variant: AppButtonVariant.primary,
                  height: 30.h,
                  onPressed: () async {
                    final firstItem = request.metadata.items.isNotEmpty ? request.metadata.items.first : <String, dynamic>{};
                    final reqMins = (firstItem['requested_minutes'] ?? firstItem['minutes'] as num?)?.toInt() ?? 30;
                    final curDuration = (firstItem['current_duration'] as num?)?.toInt() ?? 60;
                    final bookingId = request.bookingId ?? request.id.replaceFirst('ext_', '');

                    final success = await dashboardCubit.reviewExtensionRequest(
                      bookingId: bookingId,
                      isApproved: true,
                      requestedMinutes: reqMins,
                      currentDurationMinutes: curDuration,
                    );

                    if (success && context.mounted) {
                      requestsCubit.markAsAttended(request.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.requestApproved),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ] else
                AppButton(
                  text: AppStrings.markAsAttended,
                  icon: Icons.done_all_rounded,
                  variant: AppButtonVariant.primary,
                  height: 30.h,
                  onPressed: () {
                    requestsCubit.markAsAttended(
                      request.id,
                      isCanteenOrder: isCanteen,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionDetailsRow(ClientRequestEntity request) {
    final firstMetadataItem = request.metadata.items.isNotEmpty
        ? request.metadata.items.first
        : <String, dynamic>{};

    final int requestedMinutes = (firstMetadataItem['requested_minutes'] ??
            firstMetadataItem['minutes'] as num?)
        ?.toInt() ??
        30;

    final int currentDuration =
        (firstMetadataItem['current_duration'] as num?)?.toInt() ?? 60;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.neonBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 14.r, color: AppColors.neonBlue),
              SizedBox(width: 4.w),
              AppText.subHeading(
                '+$requestedMinutes ${AppStrings.minutesUnit}',
                fontSize: 12.sp,
                color: AppColors.neonBlue,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        AppText.body(
          '${AppStrings.remainingTime}: $currentDuration ${AppStrings.minutesUnit}',
          fontSize: 11.sp,
          color: AppColors.textMuted,
        ),
      ],
    );
  }

  Widget _buildCanteenItemsBox(ClientRequestEntity request) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...request.canteenItems.map((item) {
            final name = item['name_ar'] ?? item['name'] ?? item['name_en'] ?? 'Item';
            final qty = item['quantity'] ?? item['qty'] ?? 1;
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.body('• ${qty}x $name', fontSize: 11.sp, color: AppColors.textPrimary),
                  if (price > 0)
                    AppText.body('${(price * qty).toStringAsFixed(0)} ${AppStrings.egp}', fontSize: 11.sp, color: AppColors.success),
                ],
              ),
            );
          }),
          if (request.totalPrice != null && request.totalPrice! > 0) ...[
            Divider(color: AppColors.borderDefault, height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.body(AppStrings.extrasTotal, fontSize: 11.sp, color: AppColors.textMuted),
                AppText.subHeading(
                  '${request.totalPrice!.toStringAsFixed(0)} ${AppStrings.egp}',
                  fontSize: 12.sp,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
