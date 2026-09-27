import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import '../../../requests/presentation/client_requests_cubit.dart';
import '../dashboard_cubit.dart';

class ExtensionRequestTile extends StatelessWidget {
  final ClientRequestEntity request;

  const ExtensionRequestTile({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
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
    final String bookingId = request.bookingId ?? request.id.replaceFirst('ext_', '');

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  if (request.userName != null && (request.userName?.isNotEmpty ?? false))
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
          Row(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                text: AppStrings.rejectRequest,
                icon: Icons.close,
                variant: AppButtonVariant.danger,
                height: 32.h,
                onPressed: () => _showRejectDialog(
                  context,
                  dashboardCubit,
                  requestsCubit,
                  request,
                  bookingId,
                ),
              ),
              SizedBox(width: 8.w),
              AppButton(
                text: AppStrings.approveRequest,
                icon: Icons.check,
                variant: AppButtonVariant.primary,
                height: 32.h,
                onPressed: () => _showApproveDialog(
                  context,
                  dashboardCubit,
                  requestsCubit,
                  request,
                  bookingId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    DashboardCubit dashboardCubit,
    ClientRequestsCubit requestsCubit,
    ClientRequestEntity request,
    String bookingId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ApproveExtensionDialog(
        parentContext: context,
        dashboardCubit: dashboardCubit,
        requestsCubit: requestsCubit,
        request: request,
        bookingId: bookingId,
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    DashboardCubit dashboardCubit,
    ClientRequestsCubit requestsCubit,
    ClientRequestEntity request,
    String bookingId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _RejectExtensionDialog(
        parentContext: context,
        dashboardCubit: dashboardCubit,
        requestsCubit: requestsCubit,
        request: request,
        bookingId: bookingId,
      ),
    );
  }
}

class _ApproveExtensionDialog extends StatefulWidget {
  final BuildContext parentContext;
  final DashboardCubit dashboardCubit;
  final ClientRequestsCubit requestsCubit;
  final ClientRequestEntity request;
  final String bookingId;

  const _ApproveExtensionDialog({
    required this.parentContext,
    required this.dashboardCubit,
    required this.requestsCubit,
    required this.request,
    required this.bookingId,
  });

  @override
  State<_ApproveExtensionDialog> createState() => _ApproveExtensionDialogState();
}

class _ApproveExtensionDialogState extends State<_ApproveExtensionDialog> {
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
      title: AppText.subHeading(AppStrings.approveRequest, fontSize: 16.sp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.body(AppStrings.pricePerHour, fontSize: 13.sp),
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
              labelText: AppStrings.amount,
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

class _RejectExtensionDialog extends StatefulWidget {
  final BuildContext parentContext;
  final DashboardCubit dashboardCubit;
  final ClientRequestsCubit requestsCubit;
  final ClientRequestEntity request;
  final String bookingId;

  const _RejectExtensionDialog({
    required this.parentContext,
    required this.dashboardCubit,
    required this.requestsCubit,
    required this.request,
    required this.bookingId,
  });

  @override
  State<_RejectExtensionDialog> createState() => _RejectExtensionDialogState();
}

class _RejectExtensionDialogState extends State<_RejectExtensionDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: AppText.subHeading(AppStrings.rejectRequest, fontSize: 16.sp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.body(AppStrings.disputeReasonLabel, fontSize: 13.sp),
          SizedBox(height: 10.h),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: AppStrings.disputeReasonLabel,
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
            final success = await widget.dashboardCubit.reviewExtensionRequest(
              bookingId: widget.bookingId,
              isApproved: false,
              additionalCost: 0,
            );
            if (success && widget.parentContext.mounted) {
              widget.requestsCubit.markAsAttended(widget.request.id);
              ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.requestRejected),
                  backgroundColor: AppColors.warning,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
