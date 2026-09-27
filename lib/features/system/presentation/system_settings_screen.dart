import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'system_settings_cubit.dart';
import 'system_settings_state.dart';
import 'widgets/maintenance_mode_card.dart';
import 'widgets/app_versions_card.dart';
import 'widgets/create_announcement_card.dart';
import 'widgets/announcements_table.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SystemSettingsCubit>().loadData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SystemSettingsCubit, SystemSettingsState>(
      listenWhen: (prev, curr) =>
          curr.actionStatus != prev.actionStatus ||
          curr.errorMessage != null ||
          curr.successMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
          context.read<SystemSettingsCubit>().clearMessages();
        } else if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
          context.read<SystemSettingsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final isLoading = state.status == SystemSettingsStatus.loading;
        final isActionLoading = state.actionStatus == SystemSettingsStatus.loading;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 24.h),
                Expanded(
                  child: isLoading && state.appStatus.id == null
                      ? _buildShimmerLoading()
                      : state.status == SystemSettingsStatus.failure && state.appStatus.id == null
                          ? _buildErrorState(context, state.errorMessage)
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  MaintenanceModeCard(
                                    appStatus: state.appStatus,
                                    isLoading: isActionLoading,
                                    onSave: ({
                                      required isMaintenanceMode,
                                      required maintenanceMessageAr,
                                      required maintenanceMessageEn,
                                      expectedEndTime,
                                    }) {
                                      context.read<SystemSettingsCubit>().updateMaintenanceMode(
                                            isMaintenanceMode: isMaintenanceMode,
                                            maintenanceMessageAr: maintenanceMessageAr,
                                            maintenanceMessageEn: maintenanceMessageEn,
                                            expectedEndTime: expectedEndTime,
                                          );
                                    },
                                  ),
                                  SizedBox(height: 24.h),
                                  AppVersionsCard(
                                    appStatus: state.appStatus,
                                    isLoading: isActionLoading,
                                    onSave: (updated) {
                                      context.read<SystemSettingsCubit>().updateAppVersions(updated);
                                    },
                                  ),
                                  SizedBox(height: 24.h),
                                  CreateAnnouncementCard(
                                    lounges: state.lounges,
                                    isLoading: isActionLoading,
                                    onSubmit: (announcement) {
                                      context.read<SystemSettingsCubit>().createAnnouncement(announcement);
                                    },
                                  ),
                                  SizedBox(height: 24.h),
                                  AnnouncementsTable(
                                    announcements: state.announcements,
                                    onDeactivate: (id) {
                                      context.read<SystemSettingsCubit>().deactivateAnnouncement(id);
                                    },
                                  ),
                                  SizedBox(height: 40.h),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.systemSettingsAndAnnouncements,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              AppStrings.systemSettingsDesc,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        AppButton(
          text: AppStrings.refreshData,
          icon: Icons.refresh,
          variant: AppButtonVariant.outlined,
          onPressed: () => context.read<SystemSettingsCubit>().loadData(),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, index) => SizedBox(height: 24.h),
      itemBuilder: (_, index) => ShimmerLoading.rounded(
        width: double.infinity,
        height: 180.h,
        borderRadius: 16,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.danger, size: 48.r),
          SizedBox(height: 16.h),
          Text(
            message ?? AppStrings.error,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp),
          ),
          SizedBox(height: 16.h),
          AppButton(
            text: AppStrings.retry,
            icon: Icons.refresh,
            onPressed: () => context.read<SystemSettingsCubit>().loadData(),
          ),
        ],
      ),
    );
  }
}
