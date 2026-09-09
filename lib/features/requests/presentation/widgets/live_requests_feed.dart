import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_cached_image.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/status_badge.dart';
import '../../../analytics/presentation/dashboard_cubit.dart';
import '../../domain/entities/client_request_entity.dart';
import '../../domain/entities/notification_metadata.dart';
import '../client_requests_cubit.dart';
import '../client_requests_state.dart';

/// Premium Responsive Live Operations Requests Feed handling all client mobile request types.
class LiveRequestsFeed extends StatelessWidget {
  const LiveRequestsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.requests != curr.requests ||
          prev.filter != curr.filter,
      builder: (context, state) {
        final requests = state.filteredRequests;
        final unreadCount = state.unreadCount;

        return Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.borderDefault,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _LiveRequestsHeader(
                unreadCount: unreadCount,
                isLoading: state.status == ClientRequestsStatus.loading && requests.isEmpty,
              ),
              SizedBox(height: 14.h),

              // Filter Bar
              _LiveRequestsFilterBar(
                currentFilter: state.filter,
                requests: state.requests,
                unreadCount: unreadCount,
              ),
              SizedBox(height: 16.h),

              // Content Grid / Empty State
              if (requests.isEmpty)
                const _LiveRequestsEmptyState()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double totalWidth = constraints.maxWidth;
                    int columns = 1;
                    if (totalWidth >= 1100) {
                      columns = 3;
                    } else if (totalWidth >= 600) {
                      columns = 2;
                    }

                    final double cardWidth = (totalWidth - ((columns - 1) * 14.w)) / columns;

                    return Wrap(
                      spacing: 14.w,
                      runSpacing: 14.h,
                      children: requests.take(15).map((request) {
                        return SizedBox(
                          key: ValueKey(request.id),
                          width: cardWidth,
                          child: RequestCard(request: request),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveRequestsHeader extends StatelessWidget {
  final int unreadCount;
  final bool isLoading;

  const _LiveRequestsHeader({
    required this.unreadCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                color: AppColors.neonBlue,
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
                  color: AppColors.neonBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AppText.body(
                  '$unreadCount',
                  color: AppColors.neonBlue,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        if (isLoading)
          SizedBox(
            width: 16.r,
            height: 16.r,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _LiveRequestsFilterBar extends StatelessWidget {
  final RequestFilter currentFilter;
  final List<ClientRequestEntity> requests;
  final int unreadCount;

  const _LiveRequestsFilterBar({
    required this.currentFilter,
    required this.requests,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClientRequestsCubit>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          LiveRequestsFilterChip(
            label: AppStrings.all,
            filter: RequestFilter.all,
            currentFilter: currentFilter,
            count: requests.length,
            onSelected: cubit.setFilter,
          ),
          SizedBox(width: 8.w),
          LiveRequestsFilterChip(
            label: AppStrings.callStaff,
            filter: RequestFilter.callStaff,
            currentFilter: currentFilter,
            count: requests.where((r) => r.type == ClientRequestType.callStaff && !r.isAttended).length,
            onSelected: cubit.setFilter,
          ),
          SizedBox(width: 8.w),
          LiveRequestsFilterChip(
            label: AppStrings.canteenOrder,
            filter: RequestFilter.canteenOrders,
            currentFilter: currentFilter,
            count: requests.where((r) => r.isCanteenOrder && !r.isAttended).length,
            onSelected: cubit.setFilter,
          ),
          SizedBox(width: 8.w),
          LiveRequestsFilterChip(
            label: AppStrings.unread,
            filter: RequestFilter.unattendedOnly,
            currentFilter: currentFilter,
            count: unreadCount,
            onSelected: cubit.setFilter,
          ),
        ],
      ),
    );
  }
}

class LiveRequestsFilterChip extends StatelessWidget {
  final String label;
  final RequestFilter filter;
  final RequestFilter currentFilter;
  final int count;
  final ValueChanged<RequestFilter> onSelected;

  const LiveRequestsFilterChip({
    super.key,
    required this.label,
    required this.filter,
    required this.currentFilter,
    this.count = 0,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
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
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.neonBlue.withValues(alpha: 0.2),
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
        if (selected) onSelected(filter);
      },
    );
  }
}

class _LiveRequestsEmptyState extends StatelessWidget {
  const _LiveRequestsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

class RequestCard extends StatelessWidget {
  final ClientRequestEntity request;

  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final requestsCubit = context.read<ClientRequestsCubit>();
    final dashboardCubit = context.read<DashboardCubit>();

    final isCallStaff = request.type == ClientRequestType.callStaff;
    final isExtension = request.type == ClientRequestType.extendSession;
    final isCanteen = request.isCanteenOrder;
    final timeFormatted = DateFormat('hh:mm a').format(request.createdAt);

    Color themeColor;
    String typeTagAr;

    if (isCallStaff) {
      themeColor = AppColors.warning;
      typeTagAr = 'نداء عامل';
    } else if (isExtension) {
      themeColor = AppColors.neonBlue;
      typeTagAr = 'تمديد وقت';
    } else if (isCanteen) {
      themeColor = AppColors.success;
      typeTagAr = 'طلب كافيتريا';
    } else {
      themeColor = AppColors.neonPurple;
      typeTagAr = 'طلب خدمة';
    }

    String descriptionText = request.bodyAr;
    if (descriptionText.isEmpty || descriptionText == 'طلب من العميل') {
      if (isCallStaff) {
        descriptionText = 'طلب مساعدة من العامل في الغرفة';
      } else if (isCanteen) {
        descriptionText = 'طلب أصناف من الكافيتريا';
      } else if (isExtension) {
        descriptionText = 'طلب تمديد مدة الجلسة';
      }
    }

    final roomDisplayName = request.roomName ?? 'غرفة/جهاز';
    final userDisplayName = (request.userName != null && request.userName!.isNotEmpty) ? request.userName! : 'عميل';

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: request.isAttended
            ? AppColors.cardBackground.withValues(alpha: 0.4)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.borderDefault,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Bar: Type Tag + Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    AppText.body(
                      typeTagAr,
                      color: AppColors.textPrimary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 12.r, color: AppColors.textMuted),
                  SizedBox(width: 4.w),
                  AppText.body(
                    timeFormatted,
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // 2. Room Name Header
          AppText.subHeading(
            roomDisplayName,
            fontSize: 14.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),

          SizedBox(height: 10.h),

          // 3. Customer Info Tile
          RequestCustomerTile(
            userName: userDisplayName,
            userPhone: request.userPhone,
            userAvatarUrl: request.userAvatarUrl,
          ),

          SizedBox(height: 10.h),

          // 4. Description Body
          AppText.body(
            descriptionText,
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),

          // 5. Details Section (Canteen Items or Extension)
          if (isExtension) ...[
            SizedBox(height: 10.h),
            ExtensionDetailsRow(metadata: request.metadata),
          ] else if (isCanteen && request.canteenItems.isNotEmpty) ...[
            SizedBox(height: 10.h),
            CanteenItemsDetailsBox(
              items: request.canteenItems,
              totalPrice: request.totalPrice,
            ),
          ],

          SizedBox(height: 14.h),

          // 6. Action Button Footer
          SizedBox(
            width: double.infinity,
            child: request.isAttended
                ? Center(child: StatusBadge.success(AppStrings.attended))
                : isExtension
                    ? Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: AppStrings.rejectRequest,
                              icon: Icons.close_rounded,
                              variant: AppButtonVariant.danger,
                              height: 34.h,
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
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: AppButton(
                              text: AppStrings.approveRequest,
                              icon: Icons.check_rounded,
                              variant: AppButtonVariant.primary,
                              height: 34.h,
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
                                }
                              },
                            ),
                          ),
                        ],
                      )
                    : AppButton(
                        text: AppStrings.markAsAttended,
                        icon: Icons.done_all_rounded,
                        variant: AppButtonVariant.primary,
                        height: 34.h,
                        onPressed: () {
                          requestsCubit.markAsAttended(
                            request.id,
                            isCanteenOrder: isCanteen,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class RequestCustomerTile extends StatelessWidget {
  final String userName;
  final String? userPhone;
  final String? userAvatarUrl;

  const RequestCustomerTile({
    super.key,
    required this.userName,
    this.userPhone,
    this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          RequestUserAvatar(avatarUrl: userAvatarUrl, userName: userName),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subHeading(
                  userName,
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                if (userPhone != null && userPhone!.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  AppText.body(
                    userPhone!,
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
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

class RequestUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String userName;

  const RequestUserAvatar({
    super.key,
    this.avatarUrl,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final String initial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'U';

    final provider = AppCachedImage.provider(avatarUrl);

    return Container(
      width: 32.r,
      height: 32.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderDefault, width: 1),
        color: AppColors.cardBackground,
        image: (hasAvatar && provider != null)
            ? DecorationImage(
                image: provider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: (!hasAvatar || provider == null)
          ? Text(
              initial,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            )
          : null,
    );
  }
}

class ExtensionDetailsRow extends StatelessWidget {
  final NotificationMetadata metadata;

  const ExtensionDetailsRow({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final firstMetadataItem = metadata.items.isNotEmpty
        ? metadata.items.first
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
            color: AppColors.mutedBackground,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: AppColors.borderDefault),
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
}

class CanteenItemsDetailsBox extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double? totalPrice;

  const CanteenItemsDetailsBox({
    super.key,
    required this.items,
    this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.map((item) {
            final name = item['name_ar'] ?? item['name'] ?? item['name_en'] ?? item['item_name'] ?? 'صنف';
            final qty = item['quantity'] ?? item['qty'] ?? 1;
            final price = (item['price'] ?? item['unit_price'] as num?)?.toDouble() ?? 0.0;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.body(
                    '${qty}x $name',
                    fontSize: 11.sp,
                    color: AppColors.textPrimary,
                  ),
                  if (price > 0)
                    AppText.body(
                      '${(price * qty).toStringAsFixed(0)} ${AppStrings.egp}',
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                ],
              ),
            );
          }),
          if (totalPrice != null && totalPrice! > 0) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Divider(color: AppColors.borderDefault.withValues(alpha: 0.5), height: 1.h),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.body(AppStrings.extrasTotal, fontSize: 11.sp, color: AppColors.textMuted),
                AppText.subHeading(
                  '${totalPrice!.toStringAsFixed(0)} ${AppStrings.egp}',
                  fontSize: 11.sp,
                  color: AppColors.neonBlue,
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
