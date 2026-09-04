import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/status_badge.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import '../../../requests/presentation/client_requests_cubit.dart';
import '../../../requests/presentation/client_requests_state.dart';
import '../dashboard_cubit.dart';

/// Clean Dashboard UI component for managing live session extension requests from clients.
class PendingExtensionsCard extends StatelessWidget {
  const PendingExtensionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.requests != curr.requests,
      builder: (context, state) {
        final pendingExtensions = state.requests.where((r) {
          return r.type == ClientRequestType.extendSession && !r.isAttended;
        }).toList();

        final unreadCount = pendingExtensions.length;

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
                          Icons.add_alarm_rounded,
                          color: unreadCount > 0
                              ? AppColors.warning
                              : AppColors.neonBlue,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      AppText.heading(
                        AppStrings.clientRequestedExtension,
                        fontSize: 16.sp,
                      ),
                      if (unreadCount > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
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
                  if (state.status == ClientRequestsStatus.loading &&
                      pendingExtensions.isEmpty)
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              SizedBox(height: 16.h),

              // Content Body
              if (pendingExtensions.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 36.r,
                          color: AppColors.textMuted,
                        ),
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
                  itemCount: pendingExtensions.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: AppColors.divider, height: 16.h),
                  itemBuilder: (context, index) {
                    final item = pendingExtensions[index];
                    return _buildExtensionRequestTile(context, item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExtensionRequestTile(
    BuildContext context,
    ClientRequestEntity request,
  ) {
    final requestsCubit = context.read<ClientRequestsCubit>();
    final dashboardCubit = context.read<DashboardCubit>();

    final firstMetadataItem = request.metadata.items.isNotEmpty
        ? request.metadata.items.first
        : <String, dynamic>{};

    final int requestedMinutes = (firstMetadataItem['requested_minutes'] ??
            firstMetadataItem['minutes'] as num?)
        ?.toInt() ??
        30;

    final int currentDuration =
        (firstMetadataItem['current_duration'] as num?)?.toInt() ?? 60;

    final String timeFormatted = DateFormat('hh:mm a').format(request.createdAt);
    final String bookingId = request.bookingId ??
        request.id.replaceFirst('ext_', '');

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Room & Customer Info + Request Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_esports_outlined,
                    size: 18.r,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 8.w),
                  AppText.subHeading(
                    request.roomName ?? request.userName ?? AppStrings.anonymous,
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: 8.w),
                  if (request.userName != null && request.userName?.isNotEmpty == true)
                    AppText.body(
                      '(${request.userName ?? ''})',
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              AppText.body(
                timeFormatted,
                fontSize: 10.sp,
                color: AppColors.textMuted,
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Row 2: Requested Duration Badge & Info
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.neonBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 14.r,
                      color: AppColors.neonBlue,
                    ),
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
          ),
          SizedBox(height: 12.h),

          // Row 3: Action Buttons (Reject & Approve)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Reject Button
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                onPressed: () async {
                  final success = await dashboardCubit.reviewExtensionRequest(
                    bookingId: bookingId,
                    isApproved: false,
                    requestedMinutes: requestedMinutes,
                    currentDurationMinutes: currentDuration,
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
                    Icon(
                      Icons.close,
                      size: 14.r,
                      color: AppColors.danger,
                    ),
                    SizedBox(width: 4.w),
                    AppText.body(
                      AppStrings.rejectRequest,
                      color: AppColors.danger,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Approve Button
              AppButton(
                text: AppStrings.approveRequest,
                icon: Icons.check,
                variant: AppButtonVariant.primary,
                height: 32.h,
                onPressed: () async {
                  final success = await dashboardCubit.reviewExtensionRequest(
                    bookingId: bookingId,
                    isApproved: true,
                    requestedMinutes: requestedMinutes,
                    currentDurationMinutes: currentDuration,
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
            ],
          ),
        ],
      ),
    );
  }
}
