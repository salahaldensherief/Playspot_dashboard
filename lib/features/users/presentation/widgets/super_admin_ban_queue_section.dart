import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../cubit/moderation_cubit.dart';
import '../cubit/moderation_state.dart';

class SuperAdminBanQueueSection extends StatefulWidget {
  const SuperAdminBanQueueSection({super.key});

  @override
  State<SuperAdminBanQueueSection> createState() => _SuperAdminBanQueueSectionState();
}

class _SuperAdminBanQueueSectionState extends State<SuperAdminBanQueueSection> {
  @override
  void initState() {
    super.initState();
    context.read<ModerationCubit>().loadPendingBanRequests();
  }

  void _showNotesDialog(BuildContext context, String title, Function(String notes) onSubmit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: AppStrings.adminNotesHint,
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.mutedBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              onSubmit(controller.text.trim());
            },
            child: Text(AppStrings.confirmDecision),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppColors.danger),
                  SizedBox(width: 10.w),
                  AppText.subHeading(AppStrings.pendingBanQueueTitle, fontSize: 16.sp),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.neonBlue),
                onPressed: () => context.read<ModerationCubit>().loadPendingBanRequests(),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          BlocConsumer<ModerationCubit, ModerationState>(
            listener: (context, state) {
              if (state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.successMessage!), backgroundColor: AppColors.success),
                );
              } else if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.danger),
                );
              }
            },
            builder: (context, state) {
              if (state.status == ModerationStatus.loading) {
                return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
              }

              final requests = state.pendingRequests;
              if (requests.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.r),
                    child: Text(AppStrings.noPendingBanRequests, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                separatorBuilder: (_, _) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.customerLabel(req.userName ?? req.userId),
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'الصالة: ${req.loungeName ?? req.loungeId}',
                                style: TextStyle(color: AppColors.warning, fontSize: 11.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text('${AppStrings.reportReason}: ${req.reason}', style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp)),
                        if (req.evidenceNotes != null && req.evidenceNotes!.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text('${AppStrings.reportEvidence}: ${req.evidenceNotes}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                        ],
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppButton(
                              text: AppStrings.banFromThisLoungeOnly,
                              variant: AppButtonVariant.outlined,
                              backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                              onPressed: () {
                                _showNotesDialog(context, AppStrings.banFromThisLoungeOnly, (notes) {
                                  context.read<ModerationCubit>().approveLoungeBan(req.id, adminNotes: notes);
                                });
                              },
                            ),
                            SizedBox(width: 8.w),
                            AppButton(
                              text: AppStrings.globalBanApp,
                              backgroundColor: AppColors.danger,
                              onPressed: () {
                                _showNotesDialog(context, AppStrings.globalBanApp, (notes) {
                                  context.read<ModerationCubit>().approveGlobalBan(req.id, adminNotes: notes);
                                });
                              },
                            ),
                            SizedBox(width: 8.w),
                            AppButton(
                              text: AppStrings.rejectRequest,
                              variant: AppButtonVariant.outlined,
                              onPressed: () {
                                _showNotesDialog(context, AppStrings.rejectRequest, (notes) {
                                  context.read<ModerationCubit>().rejectBan(req.id, adminNotes: notes);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
