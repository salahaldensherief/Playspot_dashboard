import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/canteen_items_details_box.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/extension_details_row.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/request_card_actions.dart';
import 'package:play_spot_dashboard/features/requests/presentation/widgets/request_customer_tile.dart';

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
      typeTagAr = AppStrings.callStaff;
    } else if (isExtension) {
      themeColor = AppColors.neonBlue;
      typeTagAr = AppStrings.clientRequestedExtension;
    } else if (isCanteen) {
      themeColor = AppColors.success;
      typeTagAr = AppStrings.canteenOrder;
    } else {
      themeColor = AppColors.neonPurple;
      typeTagAr = AppStrings.serviceCall;
    }

    String descriptionText = request.bodyAr;
    if (descriptionText.isEmpty || descriptionText == 'طلب من العميل') {
      if (isCallStaff) {
        descriptionText = AppStrings.callStaff;
      } else if (isCanteen) {
        descriptionText = AppStrings.clientRequestedExtras;
      } else if (isExtension) {
        descriptionText = AppStrings.clientRequestedExtension;
      }
    }

    final roomDisplayName = request.roomName ?? AppStrings.roomLabel;
    final userDisplayName =
        (request.userName != null && request.userName!.isNotEmpty)
            ? request.userName!
            : AppStrings.anonymous;

    return Container(
      decoration: BoxDecoration(
        color: request.isAttended
            ? AppColors.cardBackground.withValues(alpha: 0.4)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: request.isAttended
              ? AppColors.borderDefault.withValues(alpha: 0.5)
              : themeColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          if (!request.isAttended)
            BoxShadow(
              color: themeColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: themeColor,
                width: 4.r,
              ),
            ),
          ),
          padding: EdgeInsets.all(14.r),
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
                  note: request.metadata.notes,
                ),
              ],
              SizedBox(height: 14.h),

              // 6. Action Button Footer
              SizedBox(
                width: double.infinity,
                child: RequestCardActions(
                  request: request,
                  dashboardCubit: dashboardCubit,
                  requestsCubit: requestsCubit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
