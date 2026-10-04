import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../../art_core/widgets/app_section_header.dart';
import '../../../art_core/widgets/shimmer_loading.dart';
import '../../../core/di/di.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/utils/permission_extension.dart';
import '../../auth/presentation/login/login_cubit.dart';
import 'audit_cubit.dart';
import 'audit_state.dart';
import 'widgets/audit_filters_bar.dart';
import 'widgets/audit_mobile_list.dart';
import 'widgets/audit_table_widget.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return BlocProvider<AuditCubit>(
      create: (_) => sl<AuditCubit>(),
      child: const _AuditScreenContent(),
    );
  }
}

class _AuditScreenContent extends StatefulWidget {
  const _AuditScreenContent();

  @override
  State<_AuditScreenContent> createState() => _AuditScreenContentState();
}

class _AuditScreenContentState extends State<_AuditScreenContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';
    context.read<AuditCubit>().loadAuditLogs(loungeId: loungeId);
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';
    final isMobile = AppBreakpoints.isMobile(context);

    // Permission guard
    final bool canViewAudit = user != null &&
        (user.isSuperAdmin ||
            user.isOwner ||
            context.hasPermission('audit.view') ||
            context.hasPermission('audit_view'));

    if (!canViewAudit) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(
          child: Container(
            margin: EdgeInsets.all(24.r),
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gavel_rounded, size: 56.r, color: AppColors.textSecondary),
                SizedBox(height: 16.h),
                Text(
                  AppStrings.accessDeniedAudit,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocListener<AuditCubit, AuditState>(
      listenWhen: (prev, curr) =>
          prev.exportSuccess != curr.exportSuccess ||
          (prev.errorMessage != curr.errorMessage && curr.errorMessage != null),
      listener: (context, state) {
        if (state.exportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.csvExportedSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              AppSectionHeader(
                title: AppStrings.auditTitle,
                subtitle: AppStrings.auditTimelineDesc,
                icon: Icons.history_rounded,
                iconColor: AppColors.neonBlue,
              ),
              SizedBox(height: 16.h),

              // Filters Bar
              BlocBuilder<AuditCubit, AuditState>(
                buildWhen: (prev, curr) =>
                    prev.selectedEntityType != curr.selectedEntityType ||
                    prev.selectedSeverity != curr.selectedSeverity ||
                    prev.selectedUserId != curr.selectedUserId ||
                    prev.searchBookingId != curr.searchBookingId ||
                    prev.startDate != curr.startDate ||
                    prev.endDate != curr.endDate ||
                    prev.isExporting != curr.isExporting,
                builder: (context, state) {
                  return AuditFiltersBar(
                    selectedEntityType: state.selectedEntityType,
                    selectedSeverity: state.selectedSeverity,
                    selectedUserId: state.selectedUserId,
                    searchBookingId: state.searchBookingId,
                    startDate: state.startDate,
                    endDate: state.endDate,
                    isExporting: state.isExporting,
                    onFilterChanged: ({
                      bookingId,
                      endDate,
                      entityType,
                      severity,
                      startDate,
                      userId,
                    }) {
                      context.read<AuditCubit>().updateFilters(
                            loungeId: loungeId,
                            entityType: entityType,
                            severity: severity,
                            userId: userId,
                            bookingId: bookingId,
                            startDate: startDate,
                            endDate: endDate,
                          );
                    },
                    onReset: () => context.read<AuditCubit>().resetFilters(loungeId: loungeId),
                    onExportCsv: () => context.read<AuditCubit>().exportCsv(loungeId: loungeId),
                  );
                },
              ),
              SizedBox(height: 16.h),

              // Main Content Table / List / States
              Expanded(
                child: BlocBuilder<AuditCubit, AuditState>(
                  buildWhen: (prev, curr) =>
                      prev.status != curr.status ||
                      prev.logs != curr.logs ||
                      prev.isLoadingMore != curr.isLoadingMore,
                  builder: (context, state) {
                    if (state.status == AuditStatus.loading && state.logs.isEmpty) {
                      return const TableShimmer(columns: 7);
                    }

                    if (state.status == AuditStatus.failure && state.logs.isEmpty) {
                      return Center(
                        child: Container(
                          padding: EdgeInsets.all(24.r),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 48.r, color: AppColors.danger),
                              SizedBox(height: 12.h),
                              Text(
                                state.errorMessage ?? AppStrings.operationError(''),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textPrimary, fontSize: 14.sp),
                              ),
                              SizedBox(height: 16.h),
                              AppButton(
                                text: AppStrings.retry,
                                icon: Icons.refresh,
                                onPressed: () => context
                                    .read<AuditCubit>()
                                    .loadAuditLogs(loungeId: loungeId),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state.logs.isEmpty) {
                      return Center(
                        child: Container(
                          padding: EdgeInsets.all(24.r),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 48.r, color: AppColors.textSecondary),
                              SizedBox(height: 12.h),
                              Text(
                                AppStrings.noAuditLogs,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                AppStrings.noAuditLogsDesc,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              AppButton(
                                text: AppStrings.resetFilters,
                                icon: Icons.restart_alt_rounded,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => context
                                    .read<AuditCubit>()
                                    .resetFilters(loungeId: loungeId),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: isMobile
                          ? AuditMobileList(
                              logs: state.logs,
                              hasMore: state.hasMore,
                              isLoadingMore: state.isLoadingMore,
                              onLoadMore: () => context
                                  .read<AuditCubit>()
                                  .loadMoreLogs(loungeId: loungeId),
                            )
                          : AuditTableWidget(
                              logs: state.logs,
                              hasMore: state.hasMore,
                              isLoadingMore: state.isLoadingMore,
                              onLoadMore: () => context
                                  .read<AuditCubit>()
                                  .loadMoreLogs(loungeId: loungeId),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
