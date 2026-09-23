import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import '../../../requests/presentation/client_requests_cubit.dart';
import '../../../requests/presentation/client_requests_state.dart';
import 'extension_request_tile.dart';

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
                    return ExtensionRequestTile(request: item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}