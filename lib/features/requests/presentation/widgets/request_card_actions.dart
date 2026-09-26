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
    showDialog(
      context: context,
      builder: (dialogContext) => _LiveApproveExtensionDialog(
        parentContext: context,
        bookingId: bookingId,
        request: request,
        dashboardCubit: dashboardCubit,
        requestsCubit: requestsCubit,
      ),
    );
  }

  void _showLiveRejectDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (dialogContext) => _LiveRejectExtensionDialog(
        parentContext: context,
        bookingId: bookingId,
        request: request,
        dashboardCubit: dashboardCubit,
        requestsCubit: requestsCubit,
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

class _LiveApproveExtensionDialog extends StatefulWidget {
  final BuildContext parentContext;
  final String bookingId;
  final ClientRequestEntity request;
  final DashboardCubit dashboardCubit;
  final ClientRequestsCubit requestsCubit;

  const _LiveApproveExtensionDialog({
    required this.parentContext,
    required this.bookingId,
    required this.request,
    required this.dashboardCubit,
    required this.requestsCubit,
  });

  @override
  State<_LiveApproveExtensionDialog> createState() => _LiveApproveExtensionDialogState();
}

class _LiveApproveExtensionDialogState extends State<_LiveApproveExtensionDialog> {
  final _costController = TextEditingController(text: '0.0');

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: AppText.subHeading(AppStrings.approveExtensionTitle, fontSize: 16.sp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.body(AppStrings.approveExtensionCostLabel, fontSize: 13.sp),
          SizedBox(height: 10.h),
          TextField(
            controller: _costController,
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          text: AppStrings.approveRequest,
          variant: AppButtonVariant.primary,
          onPressed: () async {
            Navigator.of(context).pop();
            final cost = double.tryParse(_costController.text) ?? 0.0;
            final success = await widget.dashboardCubit.reviewExtensionRequest(
              bookingId: widget.bookingId,
              isApproved: true,
              additionalCost: cost,
            );
            if (success && widget.parentContext.mounted) {
              widget.requestsCubit.markAsAttended(widget.request.id);
              ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.requestApproved),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class _LiveRejectExtensionDialog extends StatefulWidget {
  final BuildContext parentContext;
  final String bookingId;
  final ClientRequestEntity request;
  final DashboardCubit dashboardCubit;
  final ClientRequestsCubit requestsCubit;

  const _LiveRejectExtensionDialog({
    required this.parentContext,
    required this.bookingId,
    required this.request,
    required this.dashboardCubit,
    required this.requestsCubit,
  });

  @override
  State<_LiveRejectExtensionDialog> createState() => _LiveRejectExtensionDialogState();
}

class _LiveRejectExtensionDialogState extends State<_LiveRejectExtensionDialog> {
  final _reasonController = TextEditingController(text: 'لا يوجد وقت متاح بعد الحجز الحالي');

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: AppText.subHeading(AppStrings.rejectExtensionTitle, fontSize: 16.sp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.body(AppStrings.rejectReasonLabel, fontSize: 13.sp),
          SizedBox(height: 10.h),
          TextField(
            controller: _reasonController,
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          text: AppStrings.rejectRequest,
          variant: AppButtonVariant.danger,
          onPressed: () async {
            Navigator.of(context).pop();
            final reason = _reasonController.text.trim();
            final success = await widget.dashboardCubit.reviewExtensionRequest(
              bookingId: widget.bookingId,
              isApproved: false,
              reason: reason.isEmpty ? AppStrings.rejectReasonDefault : reason,
            );
            if (success && widget.parentContext.mounted) {
              widget.requestsCubit.markAsAttended(widget.request.id);
              ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.requestRejected),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
