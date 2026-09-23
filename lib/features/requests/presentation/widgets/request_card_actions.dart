import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';

class RequestCardActions extends StatelessWidget {
  final ClientRequestEntity request;
  final DashboardCubit dashboardCubit;
  final ClientRequestsCubit requestsCubit;

  const RequestCardActions({
    super.key,
    required this.request,
    required this.dashboardCubit,
    required this.requestsCubit,
  });

  void _showLiveApproveDialog(BuildContext context, String bookingId) {
    final costController = TextEditingController(text: '0.0');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: AppText.subHeading(AppStrings.approveExtensionTitle, fontSize: 16.sp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(AppStrings.approveExtensionCostLabel, fontSize: 13.sp),
            SizedBox(height: 10.h),
            TextField(
              controller: costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: AppStrings.additionalCostField,
                labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                filled: true,
                fillColor: AppColors.scaffoldBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppButton(
            text: AppStrings.approveRequest,
            variant: AppButtonVariant.primary,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final cost = double.tryParse(costController.text) ?? 0.0;
              final success = await dashboardCubit.reviewExtensionRequest(
                bookingId: bookingId,
                isApproved: true,
                additionalCost: cost,
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
    );
  }

  void _showLiveRejectDialog(BuildContext context, String bookingId) {
    final reasonController = TextEditingController(text: 'لا يوجد وقت متاح بعد الحجز الحالي');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: AppText.subHeading(AppStrings.rejectExtensionTitle, fontSize: 16.sp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(AppStrings.rejectReasonLabel, fontSize: 13.sp),
            SizedBox(height: 10.h),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: AppStrings.rejectionReasonField,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppButton(
            text: AppStrings.rejectRequest,
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final reason = reasonController.text.trim();
              final success = await dashboardCubit.reviewExtensionRequest(
                bookingId: bookingId,
                isApproved: false,
                reason: reason.isEmpty ? AppStrings.rejectReasonDefault : reason,
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (request.isAttended) {
      return Center(child: StatusBadge.success(AppStrings.attended));
    }

    final isExtension = request.type == ClientRequestType.extendSession;
    final isCanteen = request.isCanteenOrder;
    final bookingId = request.bookingId ?? request.id.replaceFirst('ext_', '');

    if (isExtension) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              text: AppStrings.rejectRequest,
              icon: Icons.close_rounded,
              variant: AppButtonVariant.danger,
              height: 34.h,
              onPressed: () => _showLiveRejectDialog(context, bookingId),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: AppButton(
              text: AppStrings.approveRequest,
              icon: Icons.check_rounded,
              variant: AppButtonVariant.primary,
              height: 34.h,
              onPressed: () => _showLiveApproveDialog(context, bookingId),
            ),
          ),
        ],
      );
    }

    return AppButton(
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
    );
  }
}
